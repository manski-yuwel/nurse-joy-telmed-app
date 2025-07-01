import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';
import 'package:mockito/mockito.dart';

// Create a mock for FirebaseFirestore
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late PaymentsData paymentsData;
  
  const String testFromUserId = 'user1';
  const String testToUserId = 'user2';
  const String testFromUserName = 'John';
  const String testToUserName = 'Jane';
  const int testAmount = 1000;
  
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    paymentsData = PaymentsData(db: fakeFirestore);
    // Initialize FirebaseFirestore with our fake instance
    
    // Seed test data
    fakeFirestore.collection('users').doc(testFromUserId).set({
      'first_name': testFromUserName,
      'email': 'john@example.com',
    });
    
    fakeFirestore.collection('users').doc(testToUserId).set({
      'first_name': testToUserName,
      'email': 'jane@example.com',
    });
  });

  group('PaymentsData', () {
    test('addTransaction should create a transaction with correct data', () async {
      // Act
      await paymentsData.addTransaction(
        fromUserId: testFromUserId,
        toUserId: testToUserId,
        amount: testAmount,
      );

      // Assert - Verify transaction was created with correct data
      final transactions = await fakeFirestore.collection('transactions').get();
      expect(transactions.docs.length, 1);
      
      final transaction = transactions.docs.first.data();
      expect(transaction['fromUserId'], testFromUserId);
      expect(transaction['fromUserName'], testFromUserName);
      expect(transaction['toUserId'], testToUserId);
      expect(transaction['toUserName'], testToUserName);
      expect(transaction['amount'], testAmount);
      expect(transaction['status'], 'Completed');
      expect(transaction, contains('timestamp'));
    });

    test('addTransaction should use user ID as name when name is missing', 
        () async {
      // Arrange - Create a user without a name
      const String unknownUserId = 'unknown_user';
      await fakeFirestore.collection('users').doc(unknownUserId).set({
        'email': 'unknown@example.com',
      });

      // Act
      await paymentsData.addTransaction(
        fromUserId: testFromUserId,
        toUserId: unknownUserId,
        amount: testAmount,
      );

      // Assert
      final transactions = await fakeFirestore.collection('transactions').get();
      final transaction = transactions.docs.first.data();
      expect(transaction['toUserName'], unknownUserId);
    });

    test('getUserTransactions should return empty stream for null userId', () async {
      // Act
      final stream = paymentsData.getUserTransactions(null);
      
      // Assert
      expect(await stream.isEmpty, isTrue);
    });

    test('getUserTransactions should return sent and received transactions',
        () async {
      // Arrange - Add test transactions
      await fakeFirestore.collection('transactions').add({
        'fromUserId': testFromUserId,
        'fromUserName': testFromUserName,
        'toUserId': testToUserId,
        'toUserName': testToUserName,
        'amount': 1000,
        'status': 'Completed',
        'timestamp': Timestamp.now(),
      });
      
      await fakeFirestore.collection('transactions').add({
        'fromUserId': testToUserId,
        'fromUserName': testToUserName,
        'toUserId': testFromUserId,
        'toUserName': testFromUserName,
        'amount': 500,
        'status': 'Completed',
        'timestamp': Timestamp.now(),
      });

      // Act
      final stream = paymentsData.getUserTransactions(testFromUserId);
      final transactions = await stream.first;

      // Assert
      expect(transactions.length, 2);
      expect(transactions.any((t) => t['fromUserId'] == testFromUserId), isTrue);
      expect(transactions.any((t) => t['toUserId'] == testFromUserId), isTrue);
    });

    test('getUserTransactions should sort transactions by timestamp descending',
        () async {
      // Arrange - Add test transactions with different timestamps
      final now = DateTime.now();
      
      await fakeFirestore.collection('transactions').add({
        'fromUserId': testFromUserId,
        'toUserId': testToUserId,
        'amount': 1000,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      });
      
      await fakeFirestore.collection('transactions').add({
        'fromUserId': testToUserId,
        'toUserId': testFromUserId,
        'amount': 500,
        'timestamp': Timestamp.fromDate(now.add(const Duration(days: 1))),
      });

      // Act
      final stream = paymentsData.getUserTransactions(testFromUserId);
      final transactions = await stream.first;

      // Assert
      expect(transactions.length, 2);
      expect(transactions[0]['amount'], 500); // Newer transaction first
      expect(transactions[1]['amount'], 1000); // Older transaction second
    });

    test('getDoctors should return list of doctors', () async {
      // Arrange - Add test doctors
      await fakeFirestore.collection('users').doc('doc1').set({
        'first_name': 'Dr. Smith',
        'email': 'smith@example.com',
        'role': 'doctor',
      });
      
      await fakeFirestore.collection('users').doc('doc2').set({
        'first_name': 'Dr. Johnson',
        'email': 'johnson@example.com',
        'role': 'doctor',
      });
      
      // Add a non-doctor user that shouldn't be returned
      await fakeFirestore.collection('users').doc('user3').set({
        'first_name': 'Regular User',
        'email': 'user@example.com',
        'role': 'patient',
      });

      // Act
      final doctors = await paymentsData.getDoctors();

      // Assert
      expect(doctors.length, 2);
      expect(doctors.any((d) => d['first_name'] == 'Dr. Smith'), isTrue);
      expect(doctors.any((d) => d['first_name'] == 'Dr. Johnson'), isTrue);
      expect(doctors.every((d) => d['role'] == 'doctor'), isTrue);
      
      // Verify uid is added to each doctor
      expect(doctors.every((d) => d['uid'] != null), isTrue);
    });
  });
}
