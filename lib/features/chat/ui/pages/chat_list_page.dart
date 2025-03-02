import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  void showOnlineUsers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: ChatList().getOnlineUsers(),
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
                  title: Text(user['full_name']),
                  subtitle: Text('Online'),
                  onTap: () {
                    // Navigate to chat screen with selected user
                    Navigator.pop(context); // Close bottom sheet
                    // TODO: Implement chat navigation
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
    return Scaffold(
        body: FutureBuilder<QuerySnapshot>(
          future: ChatList().getChatList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data!.docs[index]['full_name']),
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
