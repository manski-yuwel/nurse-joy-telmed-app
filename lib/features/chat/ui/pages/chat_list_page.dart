import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:nursejoyapp/features/chat/ui/pages/chat_room_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';

final logger = Logger();
final chatInstance = Chat();

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  Map<String, Map<String, dynamic>> recipientDetails = {};
  void showOnlineUsers(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: chatInstance.getOnlineUsers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var users = snapshot.data!.docs;

            if (users.isEmpty) {
              return const Center(child: Text("No users are online"));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index].data() as Map<String, dynamic>;

                return ListTile(
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(user['email']),
                  subtitle: Text(user['status_online'] ? 'Online' : 'Offline'),
                  onTap: () {
                    // get userID and recipientID and chatroomID
                    final userID = auth.user!.uid;
                    final recipientID = users[index].id;
                    final chatRoomID =
                        chatInstance.generateChatRoomID(userID, recipientID);
                    logger.d(recipientID);

                    // generate the chat room and navigate to it.
                    MaterialPageRoute route = MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        chatRoomID: chatRoomID,
                        recipientID: recipientID,
                        recipientFullName: user['email'],
                      ),
                    );
                    chatInstance.generateChatRoom(
                        chatRoomID, userID, recipientID);
                    Navigator.push(context, route);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: chatInstance.getChatList(auth.user!.uid),
        builder: (context, chatSnapshot) {
          if (!chatSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var chatRooms = chatSnapshot.data!.docs;

          // Extract recipient IDs safely
          List<String> recipientIDs = chatRooms
              .map((chatRoom) {
                List<String> users = List<String>.from(chatRoom['users']);
                return users.first == auth.user!.uid ? users.last : users.first;
              })
              .where((id) => id.isNotEmpty)
              .toSet() // Ensure unique IDs
              .toList();

          if (recipientIDs.isEmpty) {
            return const Center(child: Text("No chats available"));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: recipientIDs)
                .snapshots(),
            builder: (context, recipientSnapshot) {
              if (!recipientSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Store recipient details in a map
              recipientDetails = {
                for (var doc in recipientSnapshot.data!.docs)
                  doc.id: doc.data() as Map<String, dynamic>
              };

              return ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final chatRoom = chatRooms[index];
                  final List<dynamic> users = chatRoom['users'];

                  final recipientID =
                      users.first == auth.user!.uid ? users.last : users.first;

                  final recipientData = recipientDetails[recipientID] ?? {};

                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.green),
                    title: Text(recipientData['email'] ?? 'Unknown'),
                    subtitle: Text(chatRoom['last_message'] ?? ''),
                    onTap: () {
                      final userID = auth.user!.uid;
                      final chatRoomID =
                          chatInstance.generateChatRoomID(userID, recipientID);

                      logger.d("Opening chat with: $recipientID");

                      chatInstance.generateChatRoom(
                          chatRoomID, userID, recipientID);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomPage(
                            chatRoomID: chatRoomID,
                            recipientID: recipientID,
                            recipientFullName: recipientData['email'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => showOnlineUsers(context),
      ),
    );
  }
}
