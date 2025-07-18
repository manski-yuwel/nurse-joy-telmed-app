import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:nursejoyapp/features/payments/data/paymongo_service.dart';

class PaymentsData {
  static final PaymentsData _instance = PaymentsData._internal();
  factory PaymentsData() => _instance;

  final FirebaseFirestore _db;

  bool paymongoEnabled = false;

  PaymentsData._internal({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // Add a new transaction (stores both user IDs and names)
  Future<void> addTransaction({
    required String fromUserId,
    required String toUserId,
    required int amount,
    String? status,
    bool skipRedirect = false,
  }) async {
    final fromUserRef = _db.collection('users').doc(fromUserId);
    final toUserRef = _db.collection('users').doc(toUserId);
    final transactionsRef = _db.collection('transactions');
    final txDocRef = transactionsRef.doc();
    final txId = txDocRef.id;

    final fromUserSnap = await fromUserRef.get();
    final toUserSnap = await toUserRef.get();
    final fromName = fromUserSnap.data()?['first_name'] ?? fromUserSnap.data()?['email'] ?? fromUserId;
    final toName = toUserSnap.data()?['first_name'] ?? toUserSnap.data()?['email'] ?? toUserId;

    await _db.runTransaction((transaction) async {
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
  Future<void> addMoney({
    required String userId,
    required int amount,
    bool skipRedirect = false,
  }) async {
    //TODO: uncomment to use paymongo
    if (paymongoEnabled && !skipRedirect) {
      final redirectUrl = await PayMongoService.createGcashCheckout(amount, userId);
      throw {'redirectUrl': redirectUrl}; // Signal frontend to open WebView
    }

    // If redirected back successfully, add balance
    final userRef = _db.collection('users').doc(userId);
    final txRef = _db.collection('transactions').doc();
    final userDoc = await userRef.get();
    final name = userDoc.data()?['first_name'] ?? userDoc.data()?['email'] ?? userId;

    await _db.runTransaction((txn) async {
      txn.set(txRef, {
        'transactionId': txRef.id,
        'fromUserId': userId,
        'toUserId': userId,
        'fromUserName': name,
        'toUserName': name,
        'amount': amount,
        'status': 'Cash In',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (userDoc.exists) {
        txn.update(userRef, {'balance': FieldValue.increment(amount)});
      } else {
        txn.set(userRef, {'balance': amount});
      }
    });
  }




  // Get live balance stream
  Stream<int> getBalance(String userId) {
    return _db.collection('users').doc(userId).snapshots().map(
      (doc) => (doc.data()?['balance'] ?? 0) as int,
    );
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
  Future<List<Map<String, dynamic>>> getDoctors() async {
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

  //refund a transaction
  Future<void> processRefund(String docId, {required bool approve}) async {
    final doc = await FirebaseFirestore.instance.collection('refunds').doc(docId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final amount = data['amount'];
    final fromUserId = data['fromUserId'];
    final toUserId = data['toUserId'];

    final batch = FirebaseFirestore.instance.batch();
    final refundRef = FirebaseFirestore.instance.collection('refunds').doc(docId);

    if (approve) {
      final fromRef = FirebaseFirestore.instance.collection('users').doc(fromUserId);
      final toRef = FirebaseFirestore.instance.collection('users').doc(toUserId);

      batch.update(fromRef, {'balance': FieldValue.increment(-amount)});
      batch.update(toRef, {'balance': FieldValue.increment(amount)});
    }

    batch.update(refundRef, {'status': approve ? 'Approved' : 'Rejected'});
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getApprovedRefunds(String userId) {
    final toUserStream = FirebaseFirestore.instance
        .collection('refunds')
        .where('status', isEqualTo: 'Approved')
        .where('toUserId', isEqualTo: userId)
        .snapshots();

    final fromUserStream = FirebaseFirestore.instance
        .collection('refunds')
        .where('status', isEqualTo: 'Approved')
        .where('fromUserId', isEqualTo: userId)
        .snapshots();

    return Rx.combineLatest2(
      toUserStream,
      fromUserStream,
      (QuerySnapshot toSnap, QuerySnapshot fromSnap) {
        final all = [
          ...toSnap.docs.map((doc) => doc.data() as Map<String, dynamic>),
          ...fromSnap.docs.map((doc) => doc.data() as Map<String, dynamic>),
        ];
        // Remove duplicates by refundId
        final seen = <String>{};
        final unique = <Map<String, dynamic>>[];
        for (final r in all) {
          final id = r['refundId']?.toString() ?? '';
          if (!seen.contains(id)) {
            seen.add(id);
            unique.add(r);
          }
        }
        return unique;
      },
    );
  }

  Stream<List<Map<String, dynamic>>> getAllRefunds(String userId) {
    final toUserStream = FirebaseFirestore.instance
        .collection('refunds')
        .where('toUserId', isEqualTo: userId)
        .snapshots();

    final fromUserStream = FirebaseFirestore.instance
        .collection('refunds')
        .where('fromUserId', isEqualTo: userId)
        .snapshots();

    return Rx.combineLatest2(
      toUserStream,
      fromUserStream,
      (QuerySnapshot toSnap, QuerySnapshot fromSnap) {
        final all = [
          ...toSnap.docs.map((doc) => doc.data() as Map<String, dynamic>),
          ...fromSnap.docs.map((doc) => doc.data() as Map<String, dynamic>),
        ];
        // Remove duplicates by refundId
        final seen = <String>{};
        final unique = <Map<String, dynamic>>[];
        for (final r in all) {
          final id = r['refundId']?.toString() ?? '';
          if (!seen.contains(id)) {
            seen.add(id);
            unique.add(r);
          }
        }
        return unique;
      },
    );
  }
}


