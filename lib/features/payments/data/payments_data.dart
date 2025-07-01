import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class PaymentsData {
  final FirebaseFirestore _db;

  // Constructor with dependency injection
  PaymentsData({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // Add a new transaction (stores both user IDs and names)
  Future<void> addTransaction({
    required String fromUserId,
    required String toUserId,
    required int amount,
    String status = 'Completed',
  }) async {
    // Fetch sender and recipient names
    final fromUserDoc = await _db.collection('users').doc(fromUserId).get();
    final toUserDoc = await _db.collection('users').doc(toUserId).get();
    final fromUserName = fromUserDoc.data()?['first_name'] ?? fromUserId;
    final toUserName = toUserDoc.data()?['first_name'] ?? toUserId;

    await _db.collection('transactions').add({
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'amount': amount,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get transactions for a user (sent or received)
  Stream<List<Map<String, dynamic>>> getUserTransactions(String? userId) {
    if (userId == null) return const Stream.empty();

    final sentStream = _db
        .collection('transactions')
        .where('fromUserId', isEqualTo: userId)
        .snapshots();

    final receivedStream = _db
        .collection('transactions')
        .where('toUserId', isEqualTo: userId)
        .snapshots();

    return Rx.combineLatest2(
      sentStream,
      receivedStream,
      (QuerySnapshot sent, QuerySnapshot received) {
        final all = [...sent.docs, ...received.docs];
        all.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          return (bTime?.millisecondsSinceEpoch ?? 0)
              .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
        });
        return all.map((doc) => doc.data() as Map<String, dynamic>).toList();
      },
    );
  }

  // Get all doctors for dropdown
  Future<List<Map<String, dynamic>>> getDoctors() async {
    final query = await _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .get();
    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id;
      return data;
    }).toList();
  }
}