import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final db = FirebaseFirestore.instance;

class Chat {
  final logger = Logger();
  // ghet the chatlist by checking if the userID is included in the users pair in the chat doc
  Stream<QuerySnapshot> getChatList(String userID) {
    return db
        .collection('chats')
        .where('users', arrayContains: userID)
        .snapshots();
  }

  Stream<QuerySnapshot> getOnlineUsers() {
    return db.collection('users').snapshots();
  }

  // Method to search for users by email
  Future<List<QueryDocumentSnapshot>> searchUsers(
      String searchTerm, String currentUserID) async {
    // Don't search if the search term is too short
    if (searchTerm.length < 2) {
      return [];
    }

    // Get the search term with capitalization variations to improve search
    String searchTermLower = searchTerm.toLowerCase();

    try {
      // Search for users where full name and email contains the search term
      QuerySnapshot querySnapshot = await db
          .collection('users')
          .where('search_index', arrayContains: searchTermLower)
          .limit(10)
          .get();

      // Combine results and filter out the current user
      Set<QueryDocumentSnapshot> combinedResults = {};
      combinedResults.addAll(querySnapshot.docs);
      // Filter out the current user
      return combinedResults.where((doc) => doc.id != currentUserID).toList();
    } catch (e) {
      logger.e('Error searching for users: $e');
      return [];
    }
  }

  // function to generate the chatroom
  Future<void> generateChatRoom(
    String chatRoomID, String userID, String recipientID) async {
    // check if the chatroom already exists
    final chatRoomDoc = await db.collection('chats').doc(chatRoomID).get();
    if (chatRoomDoc.exists) {
      return;
    }

    await db.collection('chats').doc(chatRoomID).update({
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
    return await db.collection('users').doc(userID).get();
  }

  Stream<QuerySnapshot> getChatRoomMessages(String chatRoomID) {
    return db
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // function to send a message
  Future<void> sendMessage(String chatRoomID, String? userID,
      String recipientID, String messageBody) async {
    await db.collection('chats').doc(chatRoomID).collection('messages').add({
      'senderID': userID,
      'recipientID': recipientID,
      'message_body': messageBody,
      'message_type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await db.collection('chats').doc(chatRoomID).update({
      'last_message': messageBody,
      'timestamp': FieldValue.serverTimestamp(),
      'last_message_senderID': userID,
    });
  }

  // function to send a call notification message
  Future<DocumentReference> sendCallNotification(String chatRoomID,
      String callerID, String recipientID, String callType) async {
    final docRef = await db
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

    await db.collection('chats').doc(chatRoomID).update({
      'last_message': 'Video call',
      'timestamp': FieldValue.serverTimestamp(),
      'last_message_senderID': callerID,
    });

    return docRef;
  }

  // function to update call status in message
  Future<void> updateCallStatus(
      String chatRoomID, String messageID, String status) async {
    await db
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .doc(messageID)
        .update({
      'call_status': status,
    });
  }

  Future<void> migrateMessages() async {
    // Get all chat rooms
    final snapshot = await db.collection('chats').get();

    // set timestamp for last message, update for all chat rooms
    for (var chatDoc in snapshot.docs) {
      String chatRoomID = chatDoc.id;
      if (!chatDoc.data().containsKey('timestamp')) {
        await db.collection('chats').doc(chatRoomID).update({
          'timestamp': FieldValue.serverTimestamp(),
          'last_message_senderID': '',
        });
      }
    }

    for (var chatDoc in snapshot.docs) {
      String chatRoomID = chatDoc.id;

      // Get all messages in this chat room
      final messagesSnapshot = await db
          .collection('chats')
          .doc(chatRoomID)
          .collection('messages')
          .get();

      // Update each message that doesn't have message_type
      for (var messageDoc in messagesSnapshot.docs) {
        var messageData = messageDoc.data();
        if (!messageData.containsKey('message_type')) {
          await db
              .collection('chats')
              .doc(chatRoomID)
              .collection('messages')
              .doc(messageDoc.id)
              .update({'message_type': 'text'});
        }
      }
    }
    print("Migration complete!");
  }
}
