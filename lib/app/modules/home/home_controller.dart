import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // IMPORT THIS
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsyapp/app/data/models/user_model.dart';
import '../../data/models/chat_model.dart';
import '../../utils/chat_helpers.dart';
import '../../routes/app_pages.dart';
import '../../../main.dart'; // For initZegoService

class HomeController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  // These might be null on fresh login, handled safely in onInit usually
  // But for now keeping your structure
  final String currentUserName = FirebaseAuth.instance.currentUser!.displayName ?? '';
  final String currentUserPhotoUrl = FirebaseAuth.instance.currentUser!.photoURL ?? '';

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Rxn<UserModel> currentUser = Rxn<UserModel>();
  RxList<ChatModel> chats = <ChatModel>[].obs;

  var isSearching = false.obs;
  RxList<UserModel> searchResults = <UserModel>[].obs;
  TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    _fetchMyProfile();

    _saveDeviceToken();

    chats.bindStream(getChatsStream());

    // Initialize Zego Invitation Service
    initZegoService(currentUserEmail, currentUserName);
  }

  // --- NEW: SAVE DEVICE TOKEN ---
  void _saveDeviceToken() async {
    try {
      // Get the token for this device
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        // Save it to the user's document
        await _db.collection('users').doc(currentUserEmail).update({
          'fcmToken': token,
        });
        print("FCM Token Saved: $token");
      }

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(currentUserEmail).update({
          'fcmToken': newToken,
        });
      });

    } catch (e) {
      print("Error saving FCM Token: $e");
    }
  }

  void _fetchMyProfile() async {
    try {
      var doc = await _db.collection('users').doc(currentUserEmail).get();
      if (doc.exists) {
        currentUser.value = UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

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
      QuerySnapshot snapshot = await _db
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchTerm)
          .where('email', isLessThan: searchTerm + '\uf8ff')
          .get();

      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((user) => user.email != currentUserEmail)
          .toList();

      searchResults.assignAll(users);
    } catch (e) {
      print("Search Error: $e");
    }
  }

  Future<void> startNewChat(String targetEmail, [UserModel? userModel]) async {
    if (isSearching.value) toggleSearch();

    final email = targetEmail.trim().toLowerCase();
    if (email.isEmpty) return;
    if (email == currentUserEmail) {
      Get.snackbar("Error", "You cannot chat with yourself.");
      return;
    }

    try {
      String targetName;
      String targetPhoto;

      if (userModel != null) {
        targetName = userModel.displayName;
        targetPhoto = userModel.photoUrl;
      } else {
        var userDoc = await _db.collection('users').doc(email).get();
        if (!userDoc.exists) {
          Get.snackbar("Error", "User not found");
          return;
        }
        var data = userDoc.data()!;
        targetName = data['displayName'] ?? 'Unknown';
        targetPhoto = data['photoUrl'] ?? '';
      }

      final String chatId = getChatId(currentUserEmail, email);
      final chatDoc = await _db.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        final myDoc = await _db.collection('users').doc(currentUserEmail).get();
        final myData = myDoc.data()!;

        await _db.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'participants': [currentUserEmail, email],
          'participantNames': {
            currentUserEmail: myData['displayName'],
            email: targetName
          },
          'participantPhotos': {
            currentUserEmail: myData['photoUrl'],
            email: targetPhoto
          },
          'lastMessage': '',
          'lastUpdated': FieldValue.serverTimestamp(),
          'unreadCounts': {currentUserEmail: 0, email: 0},
        });
      }

      Get.toNamed(Routes.CHAT, arguments: {
        'chatId': chatId,
        'otherUserEmail': email,
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