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
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String searchTerm, String currentUserID) async {
    if (searchTerm.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    final results = await chatInstance.searchUsers(searchTerm, currentUserID);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

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

  Widget _buildSearchResults(String currentUserID) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text("No users found. Try a different search term."),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index].data() as Map<String, dynamic>;
        final recipientID = _searchResults[index].id;

        return ListTile(
          leading: const Icon(Icons.person, color: Colors.blue),
          title: Text(user['email'] ?? 'Unknown'),
          subtitle: Text(user['status_online'] == true ? 'Online' : 'Offline'),
          onTap: () {
            final chatRoomID =
                chatInstance.generateChatRoomID(currentUserID, recipientID);

            chatInstance.generateChatRoom(
                chatRoomID, currentUserID, recipientID);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomPage(
                  chatRoomID: chatRoomID,
                  recipientID: recipientID,
                  recipientFullName: user['email'],
                ),
              ),
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
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: const Color(0xFF58f0d7),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('', auth.user!.uid);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => _performSearch(value, auth.user!.uid),
              ),
            ),
          Expanded(
            child: _isSearching
                ? _buildSearchResults(auth.user!.uid)
                : StreamBuilder<QuerySnapshot>(
                    stream: chatInstance.getChatList(auth.user!.uid),
                    builder: (context, chatSnapshot) {
                      if (!chatSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var chatRooms = chatSnapshot.data!.docs;

                      // Extract recipient IDs safely
                      List<String> recipientIDs = chatRooms
                          .map((chatRoom) {
                            List<String> users =
                                List<String>.from(chatRoom['users']);
                            return users.first == auth.user!.uid
                                ? users.last
                                : users.first;
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
                            return const Center(
                                child: CircularProgressIndicator());
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

                              final recipientID = users.first == auth.user!.uid
                                  ? users.last
                                  : users.first;

                              final recipientData =
                                  recipientDetails[recipientID] ?? {};

                              return ListTile(
                                leading: const Icon(Icons.person,
                                    color: Colors.green),
                                title:
                                    Text(recipientData['email'] ?? 'Unknown'),
                                subtitle: Text(chatRoom['last_message'] ?? ''),
                                onTap: () {
                                  final userID = auth.user!.uid;
                                  final chatRoomID = chatInstance
                                      .generateChatRoomID(userID, recipientID);

                                  logger.d("Opening chat with: $recipientID");

                                  chatInstance.generateChatRoom(
                                      chatRoomID, userID, recipientID);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatRoomPage(
                                        chatRoomID: chatRoomID,
                                        recipientID: recipientID,
                                        recipientFullName:
                                            recipientData['email'],
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF58f0d7),
        child: const Icon(Icons.add),
        onPressed: () => showOnlineUsers(context),
      ),
    );
  }
}
