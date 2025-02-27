import 'package:cloud_firestore/cloud_firestore.dart';

final db = FirebaseFirestore.instance;

class ChatList {
  Future<QuerySnapshot> getChatList() async {
    return await db.collection('users').get();
  }
}
