import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsyapp/app/data/models/message_model.dart'; // Ensure this path is correct
import 'chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(controller.otherUserPhotoUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.messages.isEmpty) {
                  return const Center(child: Text("Say Hi! 👋"));
                }

                return ListView.builder(
                  reverse: true, // Bottom-to-Top
                  itemCount: controller.messages.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final msg = controller.messages[index];
                    final isMe = msg.senderEmail == controller.currentUserEmail;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                            top: 4,
                            bottom: 4,
                            right: isMe ? 8 : Get.width * 0.2, // Increased width for images
                            left: isMe ? Get.width * 0.2 : 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft:
                            isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight:
                            isMe ? Radius.zero : const Radius.circular(12),
                          ),
                        ),
                        // Use helper to decide what to show (Text vs Image)
                        child: _buildMessageContent(msg, isMe),
                      ),
                    );
                  },
                );
              }),
            ),

            // Upload Progress Indicator
            Obx(() => controller.isUploading.value
                ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: LinearProgressIndicator(minHeight: 2),
            )
                : const SizedBox.shrink()),

            // Input Area
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // 1. ATTACHMENT BUTTON
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {
                      _showAttachmentOptions(context);
                    },
                  ),

                  // 2. TEXT FIELD
                  Expanded(
                    child: TextField(
                      controller: controller.messageInputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. SEND BUTTON
                  CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: controller.sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to show attachment options
  void _showAttachmentOptions(BuildContext context) {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                controller.pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text('Camera'),
              onTap: () {
                Get.back();

                controller.pickAndSendImage(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build content based on MessageType
  Widget _buildMessageContent(MessageModel msg, bool isMe) {
    switch (msg.type) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                msg.fileUrl,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                // Show loader while image downloads
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                },
              ),
            ),
          ],
        );

      case MessageType.audio:
        return const Text("🎤 Audio Message (Coming Soon)");

      case MessageType.text:
      default:
        return Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        );
    }
  }
}