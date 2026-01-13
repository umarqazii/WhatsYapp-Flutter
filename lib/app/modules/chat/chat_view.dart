import 'package:zego_uikit/zego_uikit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsyapp/app/data/models/message_model.dart';
import 'package:whatsyapp/app/modules/chat/full_image_view.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart'; // Import Zego
import 'chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0.5,
          titleSpacing: 0,

          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: controller.otherUserPhotoUrl.isNotEmpty
                    ? NetworkImage(controller.otherUserPhotoUrl)
                    : null,
                child: controller.otherUserPhotoUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.teal)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.otherUserName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),


          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ZegoSendCallInvitationButton(
                isVideoCall: false,
                resourceID: "zegouikit_call",
                buttonSize: const Size(40, 40),
                iconSize: const Size(24, 24),
                icon: ButtonIcon(
                  icon: Icon(Icons.call, color: Colors.teal) 

                ),

                invitees: [
                  ZegoUIKitUser(
                    id: controller.otherUserEmail,
                    name: controller.otherUserName,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ZegoSendCallInvitationButton(
                isVideoCall: true, // <--- THE ONLY LOGIC CHANGE NEEDED
                resourceID: "zegouikit_call",
                buttonSize: const Size(40, 40),
                iconSize: const Size(24, 24),
                icon: ButtonIcon(
                  icon: const Icon(Icons.videocam, color: Colors.teal), // Video Icon
                  backgroundColor: Colors.transparent,
                ),
                invitees: [
                  ZegoUIKitUser(
                    id: controller.otherUserEmail,
                    name: controller.otherUserName,
                  ),
                ],
              ),
            ),
          ],
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

                    return Dismissible(
                      key: Key(msg.timestamp.toString()), // Use timestamp as unique key for now
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (direction) async {
                        controller.onSwipeToReply(msg);
                        return false; // Don't actually dismiss
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        // color: Colors.transparent, // Or subtle color
                        child: const Icon(Icons.reply, color: Colors.teal),
                      ),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(
                            top: 4,
                            bottom: 4,
                            right: isMe ? 8 : Get.width * 0.2,
                            left: isMe ? Get.width * 0.2 : 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildMessageContent(msg, isMe),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // --- LOADING INDICATOR ---
            Obx(
              () => controller.isUploading.value
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : const SizedBox.shrink(),
            ),

            // --- REPLY PREVIEW ---
            Obx(() {
               if (controller.replyToMessage.value == null) return const SizedBox.shrink();
               
               final reply = controller.replyToMessage.value!;
               final isSelf = reply.senderEmail == controller.currentUserEmail;
               final name = isSelf ? "You" : controller.otherUserName;
               
               return Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 color: Colors.grey[200],
                 child: Row(
                   children: [
                     Container(height: 40, width: 4, color: Colors.teal),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text("Replying to $name", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                           Text(
                             reply.type == MessageType.text ? reply.text : (reply.type == MessageType.image ? "📷 Photo" : "🎤 Voice Message"),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: const TextStyle(color: Colors.black54),
                           ),
                         ],
                       ),
                     ),
                     IconButton(
                       icon: const Icon(Icons.close, color: Colors.grey),
                       onPressed: controller.cancelReply,
                     )
                   ],
                 ),
               );
            }),

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
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          color: Colors.red,
                          size: 35,
                        ),
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
                        focusNode: controller.messageFocusNode, // ATTACH FOCUS NODE
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => controller.sendMessage(),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
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

  Widget _buildMessageContent(MessageModel msg, bool isMe) {
    if (msg.replyToSenderName != null) {
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // QUOTED PART
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: isMe ? Colors.teal.shade900 : Colors.teal, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(msg.replyToSenderName ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : Colors.teal, fontSize: 12)),
                 Text(
                   msg.replyToContent ?? '', 
                   maxLines: 2, 
                   overflow: TextOverflow.ellipsis, 
                   style: TextStyle(color: isMe ? Colors.white60 : Colors.black54, fontSize: 12)
                 ),
              ],
            ),
          ),
          // ACTUAL MESSAGE
          _buildCoreContent(msg, isMe),
        ],
      );
    }
    
    return _buildCoreContent(msg, isMe);
  }

  Widget _buildCoreContent(MessageModel msg, bool isMe) {
    switch (msg.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: () => Get.to(() => FullImageView(imageUrl: msg.fileUrl)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              msg.fileUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
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
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        );
    }
  }
}
