import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:nursejoyapp/features/chat/ui/pages/chat_room_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';

final logger = Logger();
final chatListInstance = Chat();

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  void showOnlineUsers(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: chatListInstance.getOnlineUsers(),
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
                  subtitle: Text('Online'),
                  onTap: () {
                    // get userID and recipientID and chatroomID
                    final userID = auth.user!.uid;
                    final recipientID = users[index].id;
                    final chatRoomID = chatListInstance.generateChatRoomID(
                        userID, recipientID);
                    logger.d(recipientID);

                    // generate the chat room and navigate to it.
                    MaterialPageRoute route = MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        chatRoomID: chatRoomID,
                        recipientID: recipientID,
                        recipientFullName: user['full_name'],
                      ),
                    );
                    chatListInstance.generateChatRoom(
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
          stream: chatListInstance.getChatList(auth.user!.uid),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data!.docs[index]['email']),
                    subtitle: Text(snapshot.data!.docs[index]['status_online']
                        ? 'Online'
                        : 'Offline'),
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => showOnlineUsers(context),
        ));
  }
}
