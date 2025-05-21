import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:nursejoyapp/features/chat/ui/pages/chat_room_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

final logger = Logger();
final chatInstance = Chat();

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  Map<String, Map<String, dynamic>> recipientDetails = {};
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // use debounce to prevent multiple searches
  void _debounceSearch(String searchTerm, String currentUserID) {
    if (_debounce != null) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(searchTerm, currentUserID);
    });
  }

  Future<void> _performSearch(String searchTerm, String currentUserID) async {
    if (searchTerm.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _animationController.reverse();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      if (!_animationController.isCompleted) {
        _animationController.forward();
      }
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Online Users",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: chatInstance.getOnlineUsers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildShimmerLoading();
                        }

                        var users = snapshot.data!.docs;

                        if (users.isEmpty) {
                          return _buildEmptyState(
                            icon: Icons.person_off_outlined,
                            message: "No users are online right now",
                            subMessage: "Check back later",
                          );
                        }

                        return AnimationLimiter(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              var user =
                                  users[index].data() as Map<String, dynamic>;

                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildUserCard(
                                      context,
                                      user,
                                      users[index].id,
                                      auth.user!.uid,
                                      isOnlineList: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> user,
    String recipientID,
    String currentUserID, {
    bool isOnlineList = false,
    String? lastMessage,
    Timestamp? timestamp,
  }) {
    final fullName = "${user['first_name']} ${user['last_name']}";
    final isOnline = user['status_online'] == true;
    final avatarUrl = user['avatar_url'] as String?;
    final chatRoomID =
        chatInstance.generateChatRoomID(currentUserID, recipientID);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          chatInstance.generateChatRoom(chatRoomID, currentUserID, recipientID);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomPage(
                chatRoomID: chatRoomID,
                recipientID: recipientID,
                recipientFullName: fullName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            fullName.isNotEmpty
                                ? fullName
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .join()
                                : '?',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lastMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (isOnlineList &&
                        lastMessage != null &&
                        lastMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (timestamp != null)
                Text(
                  DateFormat('h:mm a').format(timestamp.toDate()),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(String currentUserID) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        message: "No users found",
        subMessage: "Try a different search term",
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index].data() as Map<String, dynamic>;
          final recipientID = _searchResults[index].id;

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildUserCard(
                  context,
                  user,
                  recipientID,
                  currentUserID,
                  isOnlineList: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const CircleAvatar(radius: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF58f0d7);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        "Chats",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: AnimatedIcon(
                          icon: AnimatedIcons.search_ellipsis,
                          progress: _animation,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (_isSearching) {
                              _animationController.forward();
                            } else {
                              _animationController.reverse();
                              _searchController.clear();
                              _searchResults = [];
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  // Animated Search Bar
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: SizeTransition(
                      sizeFactor: _animation,
                      axisAlignment: -1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search users by name',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('', auth.user!.uid);
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) =>
                              _debounceSearch(value, auth.user!.uid),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Chat List or Search Results
            Expanded(
              child: _isSearching
                  ? _buildSearchResults(auth.user!.uid)
                  : StreamBuilder<QuerySnapshot>(
                      stream: chatInstance.getChatList(auth.user!.uid),
                      builder: (context, chatSnapshot) {
                        if (!chatSnapshot.hasData) {
                          return _buildShimmerLoading();
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
                          return _buildEmptyState(
                            icon: Icons.chat_bubble_outline,
                            message: "No conversations yet",
                            subMessage: "Start chatting with someone",
                          );
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where(FieldPath.documentId,
                                  whereIn: recipientIDs)
                              .snapshots(),
                          builder: (context, recipientSnapshot) {
                            if (!recipientSnapshot.hasData) {
                              return _buildShimmerLoading();
                            }

                            // Store recipient details in a map
                            recipientDetails = {
                              for (var doc in recipientSnapshot.data!.docs)
                                doc.id: doc.data() as Map<String, dynamic>
                            };

                            return AnimationLimiter(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: chatRooms.length,
                                itemBuilder: (context, index) {
                                  final chatRoom = chatRooms[index];
                                  final List<dynamic> users = chatRoom['users'];

                                  final recipientID =
                                      users.first == auth.user!.uid
                                          ? users.last
                                          : users.first;

                                  final recipientData =
                                      recipientDetails[recipientID] ?? {};
                                  final lastMessage =
                                      chatRoom['last_message'] as String?;
                                  final timestamp =
                                      chatRoom['timestamp'] as Timestamp?;

                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: _buildUserCard(
                                          context,
                                          recipientData,
                                          recipientID,
                                          auth.user!.uid,
                                          lastMessage: lastMessage ?? '',
                                          timestamp: timestamp,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 4,
        child: const Icon(Icons.chat_rounded, color: Colors.black87),
        onPressed: () => showOnlineUsers(context),
      ),
    );
  }
}
