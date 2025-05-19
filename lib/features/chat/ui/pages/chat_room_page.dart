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
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => VideoCallPage(
                  chatRoomID: widget.chatRoomID,
                  calleeID: widget.recipientID,
                  callerID: user!.uid,
                  isInitiator: true,
                )));
              }
            )
          ]
      ),
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
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              child: Icon(
                                  Icons.person), // Placeholder for profile pic
                              backgroundColor: Colors.grey[300],
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
}
