import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/video_call/ui/video_call_page.dart';
import 'package:nursejoyapp/features/chat/ui/widgets/message_types.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomID;
  final String recipientID;
  final String recipientFullName;

  const ChatRoomPage({
    super.key,
    required this.chatRoomID,
    required this.recipientID,
    required this.recipientFullName,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  User? user;
  final chatInstance = Chat();
  bool _isTyping = false;
  bool _isImportantToggled = false;
  bool _showAttachmentOptions = false;
  Map<String, dynamic>? _recipientData;
  late AnimationController _sendButtonAnimController;
  late Animation<double> _sendButtonAnim;

  @override
  void initState() {
    super.initState();
    _loadRecipientData();

    _sendButtonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sendButtonAnim = CurvedAnimation(
      parent: _sendButtonAnimController,
      curve: Curves.easeInOut,
    );

    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty &&
          !_sendButtonAnimController.isCompleted) {
        _sendButtonAnimController.forward();
      } else if (_messageController.text.isEmpty &&
          _sendButtonAnimController.isCompleted) {
        _sendButtonAnimController.reverse();
      }
    });
  }

  Future<void> _loadRecipientData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientID)
          .get();

      if (doc.exists) {
        setState(() {
          _recipientData = doc.data();
        });
      }
    } catch (e) {
      print('Error loading recipient data: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _sendButtonAnimController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final userID = user!.uid;
      final messageText = _messageController.text;

      // Clear the input field immediately for better UX
      _messageController.clear();

      // Hide attachment options if they were open
      if (_showAttachmentOptions) {
        setState(() {
          _showAttachmentOptions = false;
        });
      }

      // Send the message
      await chatInstance.sendMessage(
        widget.chatRoomID,
        userID,
        widget.recipientFullName,
        widget.recipientID,
        messageText,
        isImportant: _isImportantToggled,
      );

      // Reset important toggle
      if (_isImportantToggled) {
        setState(() {
          _isImportantToggled = false;
        });
      }

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _initiateVideoCall() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    user = auth.user;

    // Show calling dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Calling ${widget.recipientFullName}...'),
          ],
        ),
      ),
    );

    try {
      // Send call notification
      final messageRef = await chatInstance.sendCallNotification(
          widget.chatRoomID, user!.uid, widget.recipientID, "video");

      // Close dialog
      context.pop();

      // Navigate to video call page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallPage(
            chatRoomID: widget.chatRoomID,
            calleeID: widget.recipientID,
            callerID: user!.uid,
            isInitiator: true,
          ),
        ),
      ).then((_) {
        // Update call status when returning from call
        chatInstance.updateCallStatus(
            widget.chatRoomID, messageRef.id, 'ended');
      });
    } catch (e) {
      // Close dialog and show error
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate call: $e')),
      );
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final now = DateTime.now();

    final messageTime = timestamp.toDate();

    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      // Today, show time

      return DateFormat('h:mm a').format(messageTime);
    } else if (difference.inDays == 1) {
      // Yesterday

      return 'Yesterday, ${DateFormat('h:mm a').format(messageTime)}';
    } else if (difference.inDays < 7) {
      // Within a week

      return DateFormat('E, h:mm a').format(messageTime);
    } else {
      // Older

      return DateFormat('MMM d, h:mm a').format(messageTime);
    }
  }

  Widget _buildMessageItem(DocumentSnapshot message, bool isMe) {
    final messageType = message['message_type'] as String? ?? 'text';

    final timestamp = message['timestamp'] as Timestamp?;

    final formattedTime = _formatTime(timestamp);

    if (messageType == 'video_call') {
      return _buildCallNotificationMessage(message, isMe);
    } else if (messageType == 'prescription') {
      return MessageTypes.buildPrescriptionMessage(
          context: context,
          message: message,
          isMe: isMe,
          recipientFullName: widget.recipientFullName,
          recipientData: _recipientData);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _recipientData != null &&
                      _recipientData!['profile_pic'] != null
                  ? CachedNetworkImageProvider(_recipientData!['profile_pic'])
                  : null,
              child: _recipientData == null ||
                      _recipientData!['profile_pic'] == null
                  ? Text(
                      widget.recipientFullName.isNotEmpty
                          ? widget.recipientFullName
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .join()
                              .substring(0, 1)
                          : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          if (message['is_important']) ...[
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? message['is_important']
                            ? const Color(0xFF58f0d7)
                            : const Color(0xFF58f0d7).withOpacity(0.9)
                        : message['is_important']
                            ? Colors.white
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    border: message['is_important']
                        ? Border.all(
                            color: Colors.amber,
                            width: 2,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: message['is_important']
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: message['is_important'] ? 8 : 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message['is_important']) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Important Message',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        message['message_body'],
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: message['is_important']
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    formattedTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallNotificationMessage(DocumentSnapshot message, bool isMe) {
    final callStatus = message['call_status'] ?? 'pending';

    final isCaller = message['senderID'] == user!.uid;

    final timestamp = message['timestamp'] as Timestamp?;

    final formattedTime = _formatTime(timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: callStatus == 'ended'
                            ? Colors.grey.shade200
                            : callStatus == 'accepted'
                                ? Colors.green.shade100
                                : Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.videocam,
                        color: callStatus == 'ended'
                            ? Colors.grey.shade700
                            : callStatus == 'accepted'
                                ? Colors.green
                                : Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCaller
                                ? 'You initiated a video call'
                                : 'Incoming video call',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            callStatus == 'accepted'
                                ? 'Call in progress'
                                : callStatus == 'ended'
                                    ? 'Call ended'
                                    : 'Waiting to connect...',
                            style: TextStyle(
                              color: callStatus == 'ended'
                                  ? Colors.grey.shade600
                                  : callStatus == 'accepted'
                                      ? Colors.green
                                      : Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isCaller && callStatus == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
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
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Join Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Decline call

                          chatInstance.updateCallStatus(
                              widget.chatRoomID, message.id, 'declined');
                        },
                        icon: const Icon(Icons.call_end, size: 16),
                        label: const Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              formattedTime,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showAttachmentOptions)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.file_present,
                      color: Colors.purple,
                      label: 'Prescription',
                      onTap: () {
                        MessageTypes.showPrescriptionDialog(
                            context: context,
                            chatRoomId: widget.chatRoomID,
                            senderId: user!.uid,
                            recipientId: widget.recipientID);

                        setState(() {
                          _showAttachmentOptions = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showAttachmentOptions ? Icons.close : Icons.add,
                    color: Colors.grey.shade700,
                  ),
                  onPressed: () {
                    setState(() {
                      _showAttachmentOptions = !_showAttachmentOptions;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isImportantToggled ? Icons.star : Icons.star_border,
                    color: Colors.grey.shade700,
                    semanticLabel: "Mark as important",
                  ),
                  onPressed: () {
                    setState(() {
                      _isImportantToggled = !_isImportantToggled;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (value) {
                              // You could implement typing indicator here
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _sendButtonAnim,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _sendButtonAnim.value * 3.14159 * 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF58f0d7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: Colors.black87,
                          ),
                          onPressed: _messageController.text.isEmpty
                              ? () {
                                  // Handle voice recording
                                }
                              : _sendMessage,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        reverse: true,
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment:
                __ % 2 == 0 ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (__ % 2 != 0) ...[
                const CircleAvatar(radius: 16),
                const SizedBox(width: 8),
              ],
              Container(
                width: 200,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    user = auth.user;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text field

        FocusScope.of(context).unfocus();

        if (_showAttachmentOptions) {
          setState(() {
            _showAttachmentOptions = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF58f0d7),
          leadingWidth: 40,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _recipientData != null &&
                        _recipientData!['profile_pic'] != null
                    ? CachedNetworkImageProvider(_recipientData!['profile_pic'])
                    : null,
                child: _recipientData == null ||
                        _recipientData!['profile_pic'] == null
                    ? Text(
                        widget.recipientFullName.isNotEmpty
                            ? widget.recipientFullName
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .join()
                                .substring(0, 1)
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipientFullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_recipientData != null)
                      Text(
                        _recipientData!['status_online'] == true
                            ? 'Online'
                            : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: _recipientData!['status_online'] == true
                              ? Colors.black87
                              : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.black87),
              onPressed: _initiateVideoCall,
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: [
              // Date header

              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),

              // Messages

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: Chat().getChatRoomMessages(widget.chatRoomID),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _buildShimmerLoading();
                    }

                    var messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation with ${widget.recipientFullName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return AnimationLimiter(
                      child: ListView.builder(
                        controller: _scrollController,

                        reverse: true, // Show latest message at bottom

                        padding: const EdgeInsets.only(bottom: 8),

                        itemCount: messages.length,

                        itemBuilder: (context, index) {
                          var message = messages[index];

                          bool isMe = message['senderID'] == auth.user!.uid;

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 20.0,
                              child: FadeInAnimation(
                                child: _buildMessageItem(message, isMe),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // Typing indicator (placeholder)

              if (_isTyping)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 40,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Message input

              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }
}
