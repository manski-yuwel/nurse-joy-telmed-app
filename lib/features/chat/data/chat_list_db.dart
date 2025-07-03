import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:nursejoyapp/notifications/notification_service.dart';

class Chat {
  final FirebaseFirestore _firestore;
  final Logger logger;
  final Dio dio;
  final NotificationService notificationService;

  // Default constructor that uses the default Firestore instance
  Chat({
    FirebaseFirestore? firestore,
    Logger? logger,
    Dio? dio,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        logger = logger ?? Logger(),
        dio = dio ?? Dio(),
        notificationService = notificationService ?? NotificationService();

  // ghet the chatlist by checking if the userID is included in the users pair in the chat doc
  Stream<QuerySnapshot> getChatList(String userID) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userID)
        .snapshots();
  }

  Stream<QuerySnapshot> getOnlineUsers() {
    return _firestore.collection('users').snapshots();
  }

  // Method to search for users by email
  Future<List<QueryDocumentSnapshot>> searchUsers(
      String searchTerm, String currentUserID) async {
    // Don't search if the search term is too short
    if (searchTerm.length < 2) {
      return [];
    }

    // Get the search term with capitalization variations to improve search
    String searchTermLower = searchTerm.toLowerCase().trim();

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('search_index', arrayContains: searchTermLower)
          .limit(10)
          .get();

      Set<QueryDocumentSnapshot> combinedResults = {};
      combinedResults.addAll(querySnapshot.docs);
      return combinedResults.toList();
    } catch (e) {
      logger.e('Error searching for users: $e');
      return [];
    }
  }

  // function to generate the chatroom
  Future<void> generateChatRoom(
      String chatRoomID, String userID, String recipientID) async {
    // check if the chatroom already exists
    final chatRoomDoc = await _firestore.collection('chats').doc(chatRoomID).get();
    if (chatRoomDoc.exists) {
      return;
    }

    await _firestore.collection('chats').doc(chatRoomID).set({
      'users': [userID, recipientID],
      'last_message': '',
      'timestamp': FieldValue.serverTimestamp(),
      'last_message_senderID': '',
    });
    logger.i('Chatroom $chatRoomID created between $userID and $recipientID');
  }

  String generateChatRoomID(String userID, String recipientID) {
    List<String> chatRoomUsers = [userID, recipientID]..sort();
    return '${chatRoomUsers[0]}_${chatRoomUsers[1]}';
  }

  // function to get the recipient user details
  Future<DocumentSnapshot<Object>> getRecipientDetails(String userID) async {
    return await _firestore.collection('users').doc(userID).get();
  }

  Stream<QuerySnapshot> getChatRoomMessages(String chatRoomID) {
    return _firestore
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // function to send a message
  Future<void> sendMessage(
      String chatRoomID, String? userID, String fullName, String recipientID, String messageBody,
      {bool isImportant = false}) async {
    await _firestore.collection('chats').doc(chatRoomID).collection('messages').add({
      'senderID': userID,
      'recipientID': recipientID,
      'message_body': messageBody,
      'message_type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'is_important': isImportant,
    });

    await _firestore.collection('chats').doc(chatRoomID).update({
      'last_message': messageBody,
      'message_type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'last_message_senderID': userID,
      'last_message_is_important': isImportant,
    });

    // register the message in the activity log
    notificationService.registerActivity(
      recipientID,
      '$fullName has sent you a message',
      {
        'chatRoomID': chatRoomID,
        'senderID': userID,
        'recipientID': recipientID,
        'messageBody': messageBody,
      },
      'message',
    );
  }

  // function to send a call notification message
  Future<DocumentReference> sendCallNotification(String chatRoomID,
      String callerID, String recipientID, String callType) async {
    final docRef = await _firestore
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .add({
      'senderID': callerID,
      'recipientID': recipientID,
      'message_body': 'Incoming $callType call',
      'message_type': 'video_call',
      'call_status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatRoomID).update({
      'last_message': 'Video call',
      'timestamp': FieldValue.serverTimestamp(),
      'last_message_senderID': callerID,
    });

    return docRef;
  }

  // function to update call status in message
  Future<void> updateCallStatus(
      String chatRoomID, String messageID, String status) async {
    final messageDoc = await _firestore
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .doc(messageID)
        .get();

    if (messageDoc.exists) {
      await messageDoc.reference.update({
        'call_status': status,
      });
    }
  }

  Future<void> migrateMessages() async {
    // Get all chat rooms
    final snapshot = await _firestore.collection('chats').get();

    for (var chatDoc in snapshot.docs) {
      String chatRoomID = chatDoc.id;

      // Get all messages in this chat room
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatRoomID)
          .collection('messages')
          .get();

      for (var messageDoc in messagesSnapshot.docs) {
        var messageData = messageDoc.data();
        if (!messageData.containsKey('is_important')) {
          await _firestore
              .collection('chats')
              .doc(chatRoomID)
              .collection('messages')
              .doc(messageDoc.id)
              .update({'is_important': false});
        }
      }
    }
    print("Migration complete!");
  }
}
