import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
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

  final TextEditingController messageInputController = TextEditingController();

  // Observable list of messages
  RxList<MessageModel> messages = <MessageModel>[].obs;

  final ImagePicker _picker = ImagePicker();
  RxBool isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
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
    );
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
      );

    } catch (e) {
      Get.snackbar("Upload Failed", "Check your internet or Cloudinary keys");
      print("Cloudinary Error: $e");
    } finally {
      isUploading.value = false;
    }
  }

  // --- 3. SHARED DB HELPER ---
  // Keeps logic for Text and Image consistent
  Future<void> _sendMessageToDB({
    required String content,
    required MessageType type,
    required String fileUrl,
  }) async {
    try {
      final timestamp = Timestamp.now();

      final newMessage = MessageModel(
        senderEmail: currentUserEmail,
        text: content,
        timestamp: timestamp,
        type: type,
        fileUrl: fileUrl,
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

    } catch (e) {
      print("DB Error: $e");
      Get.snackbar("Error", "Failed to save message");
    }
  }

  @override
  void onClose() {
    messageInputController.dispose();
    super.onClose();
  }
}