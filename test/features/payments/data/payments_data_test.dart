import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';

void main() {
  group('PaymentsData', () {
    late FakeFirebaseFirestore fakeFirestore;
    late PaymentsData paymentsData;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      paymentsData = PaymentsData(db: fakeFirestore);
    });

    test('addTransaction should update balances and create a transaction',
        () async {
      // Arrange
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .set({'balance': 100, 'first_name': 'John'});
      await fakeFirestore
          .collection('users')
          .doc('user2')
          .set({'balance': 50, 'first_name': 'Jane'});

      // Act
      await paymentsData.addTransaction(
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 30,
      );

      // Assert
      final user1Doc =
          await fakeFirestore.collection('users').doc('user1').get();
      final user2Doc =
          await fakeFirestore.collection('users').doc('user2').get();
      final transactionSnapshot =
          await fakeFirestore.collection('transactions').get();

      expect(user1Doc.data()?['balance'], 70);
      expect(user2Doc.data()?['balance'], 80);
      expect(transactionSnapshot.docs.length, 1);
      expect(transactionSnapshot.docs.first.data()['amount'], 30);
    });

    test('addMoney should increase balance and log a "Cash In" transaction',
        () async {
      // Arrange
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .set({'balance': 100, 'first_name': 'John'});

      // Act
      await paymentsData.addMoney(userId: 'user1', amount: 50);

      // Assert
      final user1Doc =
          await fakeFirestore.collection('users').doc('user1').get();
      final transactionSnapshot =
          await fakeFirestore.collection('transactions').get();

      expect(user1Doc.data()?['balance'], 150);
      expect(transactionSnapshot.docs.length, 1);
      expect(transactionSnapshot.docs.first.data()['status'], 'Cash In');
    });

    test('getBalance should return a stream of the user\'s balance', () async {
      // Arrange
      await fakeFirestore.collection('users').doc('user1').set({'balance': 100});

      // Act
      final balanceStream = paymentsData.getBalance('user1');

      // Assert
      expect(balanceStream, emits(100));
    });

    test(
        'getUserTransactions should return a stream of transactions for a user',
        () async {
      // Arrange
      await fakeFirestore.collection('transactions').add({
        'fromUserId': 'user1',
        'toUserId': 'user2',
        'amount': 50,
        'timestamp': DateTime.now(),
      });
      await fakeFirestore.collection('transactions').add({
        'fromUserId': 'user2',
        'toUserId': 'user1',
        'amount': 20,
        'timestamp': DateTime.now(),
      });

      // Act
      final transactionsStream = paymentsData.getUserTransactions('user1');

      // Assert
      expect(
        transactionsStream,
        emits(
          isA<List<Map<String, dynamic>>>()
              .having((list) => list.length, 'length', 2),
        ),
      );
    });

    test('getDoctors should return a list of users with the "doctor" role',
        () async {
      // Arrange
      await fakeFirestore.collection('users').add({
        'role': 'doctor',
        'first_name': 'Dr. Smith',
      });
      await fakeFirestore.collection('users').add({
        'role': 'patient',
        'first_name': 'John Doe',
      });

      // Act
      final doctors = await paymentsData.getDoctors();

      // Assert
      expect(doctors.length, 1);
      expect(doctors.first['first_name'], 'Dr. Smith');
    });
  });
}