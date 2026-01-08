import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  String chatId;
  List<String> participants;
  String lastMessage;
  Timestamp? lastUpdated;
  Map<String, int> unreadCounts;
  
  // --- NEW FIELDS ---
  Map<String, String> participantNames;
  Map<String, String> participantPhotos;

  ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage = '',
    this.lastUpdated,
    this.unreadCounts = const {},
    // Initialize with empty maps if needed
    this.participantNames = const {},
    this.participantPhotos = const {},
  });

  factory ChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 1. Parse Unread Counts (Your existing safe logic)
    Map<String, int> parsedCounts = {};
    if (data['unreadCounts'] != null && data['unreadCounts'] is Map) {
      final rawMap = data['unreadCounts'] as Map<String, dynamic>;
      rawMap.forEach((key, value) {
        if (value is int) parsedCounts[key] = value;
        else if (value is double) parsedCounts[key] = value.toInt();
      });
    }

    // 2. Parse Names (New Safe Logic)
    Map<String, String> parsedNames = {};
    if (data['participantNames'] != null && data['participantNames'] is Map) {
      (data['participantNames'] as Map<String, dynamic>).forEach((key, value) {
        parsedNames[key] = value.toString();
      });
    }

    // 3. Parse Photos (New Safe Logic)
    Map<String, String> parsedPhotos = {};
    if (data['participantPhotos'] != null && data['participantPhotos'] is Map) {
      (data['participantPhotos'] as Map<String, dynamic>).forEach((key, value) {
        parsedPhotos[key] = value.toString();
      });
    }

    return ChatModel(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastUpdated: data['lastUpdated'],
      unreadCounts: parsedCounts,
      participantNames: parsedNames,
      participantPhotos: parsedPhotos,
    );
  }

  // --- HELPER METHODS FOR UI ---
  
  // Get the email of the person you are talking to
  String getOtherUserEmail(String myEmail) {
    return participants.firstWhere(
      (email) => email != myEmail, 
      orElse: () => 'Unknown',
    );
  }

  // Get the Name of the person you are talking to
  String getOtherUserName(String myEmail) {
    String otherEmail = getOtherUserEmail(myEmail);
    return participantNames[otherEmail] ?? 'Unknown User';
  }

  // Get the Photo of the person you are talking to
  String getOtherUserPhoto(String myEmail) {
    String otherEmail = getOtherUserEmail(myEmail);
    return participantPhotos[otherEmail] ?? '';
  }
}