import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:permission_handler/permission_handler.dart'; // PERMISSIONS
import 'package:record/record.dart'; // RECORDER
import 'package:audioplayers/audioplayers.dart'; // PLAYER
import 'package:path_provider/path_provider.dart'; // PATHS
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../../data/models/message_model.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final cloudinary = CloudinaryPublic('ddbllhkcb', 'whatsyapp_upload_preset');

  late String chatId;
  late String otherUserEmail;
  late String currentUserEmail;
  late String otherUserName;
  late String otherUserPhotoUrl;

  String currentUserName = '';

  final TextEditingController messageInputController = TextEditingController();

  // Observable list of messages
  RxList<MessageModel> messages = <MessageModel>[].obs;

  final ImagePicker _picker = ImagePicker();
  late AudioRecorder audioRecorder;
  late AudioPlayer audioPlayer;
  RxBool isUploading = false.obs;
  RxBool isRecording = false.obs; // UI toggles based on this
  RxBool isPlaying = false.obs;   // UI toggles Play/Pause icon
  RxString currentPlayingUrl = ''.obs; // To know WHICH message is playing
  Rxn<MessageModel> replyToMessage = Rxn<MessageModel>(); // Current REPLY state
  final FocusNode messageFocusNode = FocusNode(); // Focus control

  DateTime? _recordingStartTime;

  @override
  void onInit() {
    super.onInit();
    audioPlayer = AudioPlayer();
    audioRecorder = AudioRecorder();

    audioPlayer.onPlayerComplete.listen((event) {
      isPlaying.value = false;
      currentPlayingUrl.value = '';
    });

    final args = Get.arguments as Map<String, dynamic>?;
    if (args == null) {
      throw Exception('ChatView opened without arguments');
    }
    chatId = args['chatId'] as String;
    otherUserEmail = args['otherUserEmail'] as String;
    otherUserName = args['otherUserName'] as String;
    otherUserPhotoUrl = args['otherUserPhotoUrl'] as String? ?? '';
    currentUserEmail = _auth.currentUser!.email!;

    messages.bindStream(getMessagesStream());
    resetUnreadCount();
  }

  // --- REPLY LOGIC ---
  void onSwipeToReply(MessageModel msg) {
    replyToMessage.value = msg;
    messageFocusNode.requestFocus();
  }

  void cancelReply() {
    replyToMessage.value = null;
  }

  void resetUnreadCount() {
    _db.collection('chats').doc(chatId).update({
      FieldPath(['unreadCounts', currentUserEmail]): 0,
    });
  }

  Stream<List<MessageModel>> getMessagesStream() {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (query) => query.docs
          .map((item) => MessageModel.fromDocument(item))
          .toList(),
    );
  }

  // --- 1. SEND TEXT ---
  Future<void> sendMessage() async {
    final text = messageInputController.text.trim();
    if (text.isEmpty) return;

    messageInputController.clear();

    await _sendMessageToDB(
      content: text,
      type: MessageType.text,
      fileUrl: '',
      replyToMsg: replyToMessage.value, // Pass current reply
    );
    cancelReply(); // Reset after send
  }

  // --- 2. PICK & SEND IMAGE ---
  Future<void> pickAndSendImage([bool? isCameraSource]) async {
    try {
      // A. Pick Image from Gallery
      final XFile? image = await _picker.pickImage(
        source: isCameraSource==true ? ImageSource.camera: ImageSource.gallery,
        imageQuality: 70, // Optimize size
      );
      if (image == null) return;

      isUploading.value = true;

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image
        ),
      );

      // E. Get Download URL
      String downloadUrl = response.secureUrl;

      // F. Save to Firestore
      await _sendMessageToDB(
        content: '📷 Photo', // This text shows in the Chat List "Last Message"
        type: MessageType.image,
        fileUrl: downloadUrl,
        replyToMsg: replyToMessage.value, // Pass reply
      );
      cancelReply(); // Reset

    } catch (e) {
      Get.snackbar("Upload Failed", "Check your internet or Cloudinary keys");
      print("Cloudinary Error: $e");
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecorder.hasPermission()) {
        final Directory tempDir = await getTemporaryDirectory();
        // Create a unique path for the recording
        final String path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingStartTime = DateTime.now();
        await audioRecorder.start(const RecordConfig(), path: path);
        isRecording.value = true;
      } else {
        Get.snackbar("Permission Denied", "Microphone permission is required.");
      }
    } catch (e) {
      print("Recording Error: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      final String? path = await audioRecorder.stop();
      isRecording.value = false;

      if (path != null && _recordingStartTime != null) {
        final int durationSeconds = DateTime.now()
            .difference(_recordingStartTime!)
            .inSeconds;

        isUploading.value = true;

        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            path,
            resourceType: CloudinaryResourceType.Auto,
            folder: "voice_notes",
          ),
        );

        await _sendMessageToDB(
          content: '🎤 Voice Message',
          type: MessageType.audio,
          fileUrl: response.secureUrl,
          durationSeconds: durationSeconds,
          replyToMsg: replyToMessage.value,
        );
        cancelReply(); // Reset
      }
    } catch (e) {
      Get.snackbar("Error", "Audio upload failed");
      print(e);
    } finally {
      isUploading.value = false;
    }
  }


  Future<void> playAudio(String url) async {
    if (isPlaying.value && currentPlayingUrl.value == url) {
      // If clicking the same song -> Pause
      await audioPlayer.pause();
      isPlaying.value = false;
    } else {
      // New song or Resume -> Play
      await audioPlayer.play(UrlSource(url));
      isPlaying.value = true;
      currentPlayingUrl.value = url;
    }
  }

  Future<void> _sendMessageToDB({
    required String content,
    required MessageType type,
    required String fileUrl,
    int? durationSeconds,
    MessageModel? replyToMsg,
  }) async {
    try {
      final timestamp = Timestamp.now();

      final newMessage = MessageModel(
        senderEmail: currentUserEmail,
        text: content,
        timestamp: timestamp,
        type: type,
        fileUrl: fileUrl,
        durationSeconds: durationSeconds ?? 0,
        replyToMessageId: replyToMsg?.timestamp.toString(), 
        replyToSenderName: replyToMsg?.senderEmail == currentUserEmail ? "You" : (otherUserName), 
        replyToContent: replyToMsg?.type == MessageType.text ? replyToMsg?.text : (replyToMsg?.type == MessageType.image ? "📷 Photo" : "🎤 Voice Message"),
        replyToType: replyToMsg?.type,
      );

      // 1. Add to Messages Subcollection
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toJson());

      // 2. Update Chat Metadata (Last Message & Unread)
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastUpdated': timestamp,
        FieldPath(['unreadCounts', otherUserEmail]): FieldValue.increment(1),
      });

      _sendPushNotification(content);

    } catch (e) {
      print("DB Error: $e");
      Get.snackbar("Error", "Failed to save message");
    }
  }

  Future<String> _getAccessToken() async {
    final String response = await rootBundle.loadString('assets/service_account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(response);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(accountCredentials, scopes);

    return client.credentials.accessToken.data;
  }

  Future<void> _sendPushNotification(String messageContent) async {
    try {
      // 1. Get Other User's FCM Token from Firestore
      final userDoc = await _db.collection('users').doc(otherUserEmail).get();
      final String? token = userDoc.data()?['fcmToken'];

      if (token == null) {
        print("User has no FCM token. Skipping notification.");
        return;
      }

      // 2. Get Secure Access Token (V1 API)
      final currentUser = _auth.currentUser;
      final String myName = currentUser?.displayName ?? 'Friend';
      final String myPhoto = currentUser?.photoURL ?? '';
      final String accessToken = await _getAccessToken();

      // 3. Prepare the V1 Request Body
      // CHANGE "YOUR_PROJECT_ID" BELOW TO YOUR ACTUAL FIREBASE PROJECT ID
      final String endpoint = 'https://fcm.googleapis.com/v1/projects/whatsyapp-9730d/messages:send';

      final Map<String, dynamic> body = {
        'message': {
          'token': token,
          'notification': {
            'title': myName, // Shows who sent it
            'body': messageContent,
          },
          'data': {
            'type': 'chat',
            'chatId': chatId,
            'senderEmail': currentUserEmail,
            'senderName': myName,
            'senderPhoto': myPhoto,
          }
        }
      };

      // 4. Send Request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("Notification Sent Successfully!");
      } else {
        print("Notification Failed: ${response.body}");
      }

    } catch (e) {
      print("Notification Error: $e");
    }
  }

  @override
  void onClose() {
    messageInputController.dispose();
    audioRecorder.dispose();
    audioPlayer.dispose();
    super.onClose();
  }
}