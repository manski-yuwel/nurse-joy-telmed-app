import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class PaymentsData {
  static final _db = FirebaseFirestore.instance;

  // Add a new transaction and update balances
  static Future<void> addTransaction({
    required String fromUserId,
    required String toUserId,
    required int amount,
    String status = 'Completed',
  }) async {
    // Fetch sender and recipient docs
    final fromUserRef = _db.collection('users').doc(fromUserId);
    final toUserRef = _db.collection('users').doc(toUserId);

    final fromUserDoc = await fromUserRef.get();
    final toUserDoc = await toUserRef.get();

    final fromUserName = fromUserDoc.data()?['first_name'] ?? fromUserId;
    final toUserName = toUserDoc.data()?['first_name'] ?? toUserId;

    // Update balances in a transaction
    await _db.runTransaction((transaction) async {
      final fromBalance = (fromUserDoc.data()?['balance'] ?? 0) as int;
      final toBalance = (toUserDoc.data()?['balance'] ?? 0) as int;

      if (fromUserId == toUserId) {
        // Self-transfer: Don't change balance
        transaction.update(fromUserRef, {'balance': fromBalance});
      } else {
        transaction.update(fromUserRef, {'balance': fromBalance - amount});
        transaction.update(toUserRef, {'balance': toBalance + amount});
      }

      transaction.set(_db.collection('transactions').doc(), {
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'amount': amount,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // Add money to the user's balance and log as "Cash In"
  static Future<void> addMoney({
    required String userId,
    required int amount,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    final userDoc = await userRef.get();
    final userName = userDoc.data()?['first_name'] ?? userId;

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final currentBalance = (userSnap.data()?['balance'] ?? 0) as int;
      transaction.update(userRef, {'balance': currentBalance + amount});

      // Add a "Cash In" transaction
      transaction.set(_db.collection('transactions').doc(), {
        'fromUserId': userId,
        'fromUserName': userName,
        'toUserId': userId,
        'toUserName': userName,
        'amount': amount,
        'status': 'Cash In',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get live balance stream
  static Stream<int> getBalance(String userId) {
    return _db.collection('users').doc(userId).snapshots().map(
      (doc) => (doc.data()?['balance'] ?? 0) as int,
    );
  }

  // Get transactions for a user (sent or received)
  static Stream<List<Map<String, dynamic>>> getUserTransactions(String? userId) {
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
        final allDocs = [...sent.docs, ...received.docs];

        // Filter duplicates using document ID (or all field values if no ID)
        final unique = {
          for (var doc in allDocs) doc.id: doc,
        }.values.toList();

        unique.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          return (bTime?.millisecondsSinceEpoch ?? 0)
              .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
        });

        return unique.map((doc) => doc.data() as Map<String, dynamic>).toList();
      },
    );
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