import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class PaymentsData {
  static final _db = FirebaseFirestore.instance;

  // Add a new transaction and update balances
  static Future<void> addTransaction({
    required String fromUserId,
    required String toUserId,
    required int amount,
    String? status,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final fromUserRef = firestore.collection('users').doc(fromUserId);
    final toUserRef = firestore.collection('users').doc(toUserId);
    final transactionsRef = firestore.collection('transactions');
    final txDocRef = transactionsRef.doc();
    final txId = txDocRef.id;

    final fromUserSnap = await fromUserRef.get();
    final toUserSnap = await toUserRef.get();
    final fromName = fromUserSnap.data()?['first_name'] ?? fromUserSnap.data()?['email'] ?? fromUserId;
    final toName = toUserSnap.data()?['first_name'] ?? toUserSnap.data()?['email'] ?? toUserId;

    await firestore.runTransaction((transaction) async {
      final fromBalance = (fromUserSnap.data()?['balance'] ?? 0) as int;
      final toBalance = (toUserSnap.data()?['balance'] ?? 0) as int;

      if (fromUserId != toUserId) {
        transaction.update(fromUserRef, {'balance': fromBalance - amount});
        transaction.update(toUserRef, {'balance': toBalance + amount});
      }

      transaction.set(txDocRef, {
        'transactionId': txId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromName,
        'toUserName': toName,
        'amount': amount,
        'status': status ?? 'Completed',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }



  // Add money to the user's balance and log as "Cash In"
  static Future<void> addMoney({
    required String userId,
    required int amount,
  }) async {
    final transactionsRef = FirebaseFirestore.instance.collection('transactions');
    final txDocRef = transactionsRef.doc();
    final txId = txDocRef.id;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userName = userDoc.data()?['first_name'] ?? userDoc.data()?['email'] ?? userId;

    final txData = {
      'transactionId': txId,
      'fromUserId': userId,
      'toUserId': userId,
      'fromUserName': userName,
      'toUserName': userName,
      'amount': amount,
      'status': 'Cash In',
      'timestamp': Timestamp.now(),
    };

    await txDocRef.set(txData);

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'balance': FieldValue.increment(amount),
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