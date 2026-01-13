import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio }

class MessageModel {
  String senderEmail;
  String text;
  String fileUrl;
  MessageType type;
  Timestamp timestamp;
  int? durationSeconds;
  
  // REPLY FIELDS
  String? replyToMessageId;
  String? replyToSenderName;
  String? replyToContent;
  MessageType? replyToType;

  MessageModel({
    required this.senderEmail,
    required this.text,
    this.fileUrl='',
    this.type = MessageType.text,
    required this.timestamp,
    this.durationSeconds,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToContent,
    this.replyToType,
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
      durationSeconds: data['durationSeconds'],
      replyToMessageId: data['replyToMessageId'],
      replyToSenderName: data['replyToSenderName'],
      replyToContent: data['replyToContent'],
      replyToType: data['replyToType'] != null 
          ? MessageType.values.firstWhere((e) => e.name == data['replyToType'], orElse: () => MessageType.text)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderEmail': senderEmail,
      'text': text,
      'fileUrl': fileUrl,
      'type': type.name,
      'timestamp': timestamp,
      if (durationSeconds != null)
        'durationSeconds': durationSeconds,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToContent != null) 'replyToContent': replyToContent,
      if (replyToType != null) 'replyToType': replyToType!.name,
    };
  }

  String get formattedDuration {
    if (durationSeconds == null) return "0:00";
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}