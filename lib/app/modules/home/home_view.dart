import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../routes/app_pages.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: controller.scaffoldKey,
        backgroundColor: Colors.grey.shade100,

        // --- SIDEBAR (DRAWER) ---
        drawer: Drawer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header with User Info
              UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.teal),
                  accountName: Text(
                    controller.currentUserName ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  accountEmail: Text(controller.currentUserEmail ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: (controller.currentUserPhotoUrl != null)
                        ? NetworkImage(controller.currentUserPhotoUrl)
                        : null,
                    child: (controller.currentUserPhotoUrl != null)
                        ? null
                        : const Icon(Icons.person, size: 40, color: Colors.teal),
                  ),
                ),


              // Menu Items
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: controller.logout,
              ),
            ],
          ),
        ),

        // --- APP BAR ---
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          automaticallyImplyLeading: false, // Hides default hamburger (we make our own)
          titleSpacing: 16,

          title: Obx(() {
            // CASE 1: SEARCHING -> Show Search Field
            if (controller.isSearching.value) {
              return Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: controller.searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Search by email",
                    border: InputBorder.none,
                    icon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: controller.searchUsers,
                ),
              );
            }

            // CASE 2: NORMAL -> Show Profile Pic + "Chats"

            return Row(
              children: [
                // Clickable Profile Picture
                GestureDetector(
                  onTap: controller.openDrawer,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: (controller.currentUserPhotoUrl != null)
                        ? NetworkImage(controller.currentUserPhotoUrl)
                        : null,
                    child: (controller.currentUserPhotoUrl != null)
                        ? null
                        : const Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Chats',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            );
          }),

          actions: [
            Obx(() {
              // CASE 1: SEARCHING -> Show Close Button
              if (controller.isSearching.value) {
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: controller.toggleSearch,
                );
              }
              // CASE 2: NORMAL -> Show Search Icon (Logout is now in Drawer)
              return IconButton(
                icon: const Icon(Icons.search),
                onPressed: controller.toggleSearch,
              );
            })
          ],
        ),

        body: Obx(() {
          // SEARCH MODE
          if (controller.isSearching.value) {
            if (controller.searchResults.isEmpty) {
              return const Center(
                child: Text(
                  "Search users by their email",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final user = controller.searchResults[index];
                return _UserTile(
                  name: user.displayName,
                  email: user.email,
                  photoUrl: user.photoUrl,
                  onTap: () => controller.startNewChat(user.email, user),
                );
              },
            );
          }

          // EMPTY STATE
          if (controller.chats.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet\nTap search to start chatting',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // CHAT LIST
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final chat = controller.chats[index];
              final unreadCount =
                  chat.unreadCounts[controller.currentUserEmail] ?? 0;
              final isUnread = unreadCount > 0;

              return _ChatTile(
                name: chat.getOtherUserName(controller.currentUserEmail),
                photoUrl:
                chat.getOtherUserPhoto(controller.currentUserEmail),
                message: chat.lastMessage.isEmpty
                    ? 'Tap to start chatting'
                    : chat.lastMessage,
                unreadCount: unreadCount,
                isUnread: isUnread,
                onTap: () {
                  Get.toNamed(
                    Routes.CHAT,
                    arguments: {
                      'chatId': chat.chatId,
                      'otherUserEmail': chat.getOtherUserEmail(
                          controller.currentUserEmail),
                      'otherUserName': chat.getOtherUserName(
                          controller.currentUserEmail),
                      'otherUserPhotoUrl': chat.getOtherUserPhoto(
                          controller.currentUserEmail),
                    },
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String photoUrl;
  final String message;
  final int unreadCount;
  final bool isUnread;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.photoUrl,
    required this.message,
    required this.unreadCount,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundImage:
        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUnread ? Colors.black : Colors.grey,
        ),
      ),
      trailing: isUnread
          ? Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
        child: Text(
          unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      )
          : null,
      onTap: onTap,
    );
  }
}

class _UserTile extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;
  final VoidCallback onTap;

  const _UserTile({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(name),
      subtitle: Text(email),
      onTap: onTap,
    );
  }
}

