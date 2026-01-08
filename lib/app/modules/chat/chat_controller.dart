import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/message_model.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String chatId;
  late String otherUserEmail;
  late String currentUserEmail;
  late String otherUserName;
  late String otherUserPhotoUrl;

  final TextEditingController messageInputController = TextEditingController();

  // Observable list of messages
  RxList<MessageModel> messages = <MessageModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Retrieve arguments passed from Home Screen
    final args = Get.arguments as Map<String, dynamic>?;
    if (args == null) {
      throw Exception('ChatView opened without arguments');
    }
    chatId = args['chatId'] as String;
    otherUserEmail = args['otherUserEmail'] as String;
    otherUserName = args['otherUserName'] as String;
    otherUserPhotoUrl = args['otherUserPhotoUrl'] as String? ?? '';
    currentUserEmail = _auth.currentUser!.email!;


    // Bind the real-time stream
    messages.bindStream(getMessagesStream());

    resetUnreadCount();
  }

  void resetUnreadCount() {
    _db.collection('chats').doc(chatId).update({
      // ✅ FieldPath protects the dot in the email
      FieldPath(['unreadCounts', currentUserEmail]): 0,
    });
  }

  Stream<List<MessageModel>> getMessagesStream() {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Newest first
        .snapshots()
        .map(
          (query) => query.docs
              .map((item) => MessageModel.fromDocument(item))
              .toList(),
        );
  }

  Future<void> sendMessage() async {
    final text = messageInputController.text.trim();
    if (text.isEmpty) return;

    messageInputController.clear();

    try {
      final timestamp = Timestamp.now();

      // 1. Create the Message Object
      final newMessage = MessageModel(
        senderEmail: currentUserEmail,
        text: text,
        timestamp: timestamp,
      );

      // 2. Add to Subcollection: chats -> {chatId} -> messages
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toJson());

      // 3. Update the Parent Chat Document (for the list preview)
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastUpdated': timestamp,
        // ✅ FieldPath ensures 'user@gmail.com' is treated as ONE key
        FieldPath(['unreadCounts', otherUserEmail]): FieldValue.increment(1),
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to send message");
    }
  }

  @override
  void onClose() {
    messageInputController.dispose();
    super.onClose();
  }
}
