import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  String senderEmail;
  String text;
  Timestamp timestamp;

  MessageModel({
    required this.senderEmail,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      senderEmail: data['senderEmail'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderEmail': senderEmail,
      'text': text,
      'timestamp': timestamp,
    };
  }
}