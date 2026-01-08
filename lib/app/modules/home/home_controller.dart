import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsyapp/app/data/models/user_model.dart';
import '../../data/models/chat_model.dart';
import '../../utils/chat_helpers.dart'; // Ensure you have the helper we created earlier
import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  // The list of chats (Observable)
  RxList<ChatModel> chats = <ChatModel>[].obs;

  var isSearching = false.obs;
  RxList<UserModel> searchResults = <UserModel>[].obs;
  TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Bind the stream to the reactive list
    chats.bindStream(getChatsStream());
  }

  // 1. Listen to all chats where I am a participant
  Stream<List<ChatModel>> getChatsStream() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: currentUserEmail)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((query) =>
            query.docs.map((item) => ChatModel.fromDocument(item)).toList());
  }

void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchResults.clear();
      searchController.clear();
    }
  }

void searchUsers(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    String searchTerm = query.toLowerCase().trim();

    try {
      // "Starts with" query logic
      QuerySnapshot snapshot = await _db
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchTerm)
          .where('email', isLessThan: searchTerm + '\uf8ff') 
          .get();

      // Convert docs to UserModels and filter out yourself
      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((user) => user.email != currentUserEmail) 
          .toList();

      searchResults.assignAll(users);
    } catch (e) {
      print("Search Error: $e");
    }
  }

  // 2. Logic to search for a user and start a chat
  Future<void> startNewChat(String targetEmail, [UserModel? userModel]) async {
    // 1. Close search mode
    if (isSearching.value) toggleSearch();

    final email = targetEmail.trim().toLowerCase();
    if (email.isEmpty) return;

    // Check self-chat
    if (email == currentUserEmail) {
      Get.snackbar("Error", "You cannot chat with yourself.");
      return;
    }

    try {
      // 2. Prepare Target User Data
      // If we passed the user model from the view, use it!
      // Otherwise (manual entry), fetch it from Firestore.
      String targetName;
      String targetPhoto;

      if (userModel != null) {
        targetName = userModel.displayName;
        targetPhoto = userModel.photoUrl;
      } else {
        // Fetch from DB if we don't have it
        var userDoc = await _db.collection('users').doc(email).get();
        if (!userDoc.exists) {
          Get.snackbar("Error", "User not found");
          return;
        }
        var data = userDoc.data()!;
        targetName = data['displayName'] ?? 'Unknown';
        targetPhoto = data['photoUrl'] ?? '';
      }

      // 3. Generate Chat ID
      final String chatId = getChatId(currentUserEmail, email);
      final chatDoc = await _db.collection('chats').doc(chatId).get();

      // 4. Create Chat if not exists
      if (!chatDoc.exists) {
        final myDoc = await _db.collection('users').doc(currentUserEmail).get();
        final myData = myDoc.data()!;

        await _db.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'participants': [currentUserEmail, email],
          'participantNames': {
            currentUserEmail: myData['displayName'],
            email: targetName // Use variable
          },
          'participantPhotos': {
            currentUserEmail: myData['photoUrl'],
            email: targetPhoto // Use variable
          },
          'lastMessage': '',
          'lastUpdated': FieldValue.serverTimestamp(),
          'unreadCounts': {currentUserEmail: 0, email: 0},
        });
      }

      // 5. Navigate with CONSISTENT Arguments
      Get.toNamed(
          Routes.CHAT,
          arguments: {
            'chatId': chatId,
            'otherUserEmail': email,
            // Now we always have these available
            'otherUserName': targetName,
            'otherUserPhotoUrl': targetPhoto,
          });

    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(Routes.AUTH);
  }
}