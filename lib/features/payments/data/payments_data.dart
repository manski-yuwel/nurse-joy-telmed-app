import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentsData {
  static final _db = FirebaseFirestore.instance;

  // Add a new transaction
  static Future<void> addTransaction({
    required String fromUserId,
    required String toUserId,
    required int amount,
    String status = 'Completed',
  }) async {
    await _db.collection('transactions').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get transactions for a user (sent or received)
  static Stream<List<Map<String, dynamic>>> getUserTransactions(String? userId) {
    if (userId == null) return const Stream.empty();
    return _db
        .collection('transactions')
        .where('fromUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get all doctors for dropdown
  static Future<List<Map<String, dynamic>>> getDoctors() async {
    final query = await _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }
}