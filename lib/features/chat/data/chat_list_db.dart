import 'package:cloud_firestore/cloud_firestore.dart';

final db = FirebaseFirestore.instance;

class ChatList {
  Future<QuerySnapshot> getChatList() async {
    return await db.collection('users').get();
  }

  Stream<QuerySnapshot> getOnlineUsers() {
    return db
        .collection('users')
        .where('status_online', isEqualTo: true)
        .snapshots();
  }
}
