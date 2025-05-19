import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nursejoyapp/features/video_call/ui/video_call_page.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomID;
  final String recipientID;
  final String recipientFullName;

  const ChatRoomPage(
      {super.key,
      required this.chatRoomID,
      required this.recipientID,
      required this.recipientFullName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  User? user;
  final chatInstance = Chat();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    user = auth.user;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.recipientFullName,
              style: const TextStyle(fontSize: 14)),
          backgroundColor: const Color(0xFF58f0d7),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.call),
                onPressed: () async {
                  // First send call notification
                  final messageRef = await chatInstance.sendCallNotification(
                      widget.chatRoomID,
                      user!.uid,
                      widget.recipientID,
                      "video");

                  // Then navigate to video call page
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => VideoCallPage(
                                chatRoomID: widget.chatRoomID,
                                calleeID: widget.recipientID,
                                callerID: user!.uid,
                                isInitiator: true,
                              ))).then((_) {
                    // Update call status when returning from call
                    chatInstance.updateCallStatus(
                        widget.chatRoomID, messageRef.id, 'ended');
                  });
                })
          ]),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Chat().getChatRoomMessages(widget.chatRoomID),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Show latest message at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderID'] == auth.user!.uid;
                    bool isNotMe = message['recipientID'] == auth.user!.uid;

                    logger.i(
                        'isMe: $isMe for message: ${message['message_body']}');
                    logger.i(
                        'isNotMe: $isNotMe for message: ${message['message_body']}');
                    if ((message['message_type'] ?? '') == 'video_call') {
                      return _buildCallNotificationMessage(message, isMe);
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Icon(
                                  Icons.person), // Placeholder for profile pic
                            ),
                            SizedBox(
                                width: 8), // Spacing between avatar and message
                          ],
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft:
                                      isMe ? Radius.circular(16) : Radius.zero,
                                  bottomRight:
                                      isMe ? Radius.zero : Radius.circular(16),
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width *
                                    0.7, // Limit width
                              ),
                              child: Text(
                                message['message_body'],
                                style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final userID = user!.uid;

      // call the send message function from the Chat class
      await chatInstance.sendMessage(widget.chatRoomID, userID,
          widget.recipientID, _messageController.text);
      _messageController.clear();
    }
  }

  Widget _buildCallNotificationMessage(DocumentSnapshot message, bool isMe) {
    final callStatus = message['call_status'] ?? 'pending';
    final isCaller = message['senderID'] == user!.uid;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_call,
                  color: Colors.blue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  isCaller
                      ? 'You initiated a video call'
                      : 'Incoming video call',
                  style: TextStyle(color: Colors.black87),
                ),
                if (!isCaller && callStatus == 'pending') ...[
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // Update status to accepted
                      chatInstance.updateCallStatus(
                          widget.chatRoomID, message.id, 'accepted');

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoCallPage(
                            chatRoomID: widget.chatRoomID,
                            calleeID: widget.recipientID,
                            callerID: message['senderID'],
                            isInitiator: false,
                            messageId: message.id,
                          ),
                        ),
                      ).then((_) {
                        // Update call status when returning from call
                        chatInstance.updateCallStatus(
                            widget.chatRoomID, message.id, 'ended');
                      });
                    },
                    child: Text(
                      'Join',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
                if (callStatus == 'accepted')
                  Text(
                    ' • Call in progress',
                    style: TextStyle(color: Colors.green),
                  ),
                if (callStatus == 'ended')
                  Text(
                    ' • Call ended',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
