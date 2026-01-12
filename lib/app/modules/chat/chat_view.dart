import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsyapp/app/data/models/message_model.dart';
import 'package:whatsyapp/app/modules/chat/full_image_view.dart';
import 'chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // --- MESSAGE LIST ---
            Expanded(
              child: Obx(() {
                if (controller.messages.isEmpty) {
                  return const Center(child: Text("Say Hi! 👋"));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: controller.messages.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final msg = controller.messages[index];
                    final isMe = msg.senderEmail == controller.currentUserEmail;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                            top: 4, bottom: 4,
                            right: isMe ? 8 : Get.width * 0.2,
                            left: isMe ? Get.width * 0.2 : 8
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildMessageContent(msg, isMe),
                      ),
                    );
                  },
                );
              }),
            ),

            // --- LOADING INDICATOR ---
            Obx(() => controller.isUploading.value
                ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: LinearProgressIndicator(minHeight: 2),
            )
                : const SizedBox.shrink()),

            // --- INPUT AREA ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(() {
                // RECORDING MODE UI
                if (controller.isRecording.value) {
                  return Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.red, size: 30),
                      const SizedBox(width: 10),
                      const Text(
                          "Recording...",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.stop_circle_outlined, color: Colors.red, size: 35),
                        onPressed: controller.stopRecording,
                      ),
                    ],
                  );
                }

                // NORMAL TEXT MODE UI
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: () => _showAttachmentOptions(context),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller.messageInputController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => controller.sendMessage(),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // MIC BUTTON
                    GestureDetector(
                      // You can change this to onLongPress if you prefer
                      onTap: controller.startRecording,
                      child: const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.mic, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // SEND BUTTON
                    CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: controller.sendMessage,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: ATTACHMENT SHEET ---
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
              onTap: () { Get.back(); controller.pickAndSendImage(); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text('Camera'),
              onTap: () { Get.back(); controller.pickAndSendImage(true); },
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: MESSAGE CONTENT ---
  Widget _buildMessageContent(MessageModel msg, bool isMe) {
    switch (msg.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: () => Get.to(() => FullImageView(imageUrl: msg.fileUrl)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              msg.fileUrl,
              width: 200, height: 200, fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200, height: 200, color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          ),
        );

      case MessageType.audio:
        return Obx(() {
          final isThisPlaying =
              controller.isPlaying.value &&
                  controller.currentPlayingUrl.value == msg.fileUrl;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            constraints: const BoxConstraints(minWidth: 180),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PLAY / PAUSE
                GestureDetector(
                  onTap: () => controller.playAudio(msg.fileUrl),
                  child: Icon(
                    isThisPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: 36,
                    color: isMe ? Colors.white : Colors.teal,
                  ),
                ),

                const SizedBox(width: 8),

                // WAVEFORM (fake for now, but looks legit)
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white54 : Colors.teal.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // DURATION
                Text(
                  msg.formattedDuration,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        });


      case MessageType.text:
      default:
        return Text(
          msg.text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16),
        );
    }
  }
}