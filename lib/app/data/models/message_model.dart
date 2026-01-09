import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio }

class MessageModel {
  String senderEmail;
  String text;
  String fileUrl;
  MessageType type;
  Timestamp timestamp;

  MessageModel({
    required this.senderEmail,
    required this.text,
    this.fileUrl='',
    this.type = MessageType.text,
    required this.timestamp,
  });

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    MessageType msgType = MessageType.text;
    if (data['type'] == 'image') msgType = MessageType.image;
    if (data['type'] == 'audio') msgType = MessageType.audio;

    return MessageModel(
      senderEmail: data['senderEmail'] ?? '',
      text: data['text'] ?? '',
      type: msgType,
      fileUrl: data['fileUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderEmail': senderEmail,
      'text': text,
      'fileUrl': fileUrl,
      'type': type.name,
      'timestamp': timestamp,
    };
  }
}