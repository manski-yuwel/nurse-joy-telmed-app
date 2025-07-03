
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

    group('addTransaction', () {
      test('should update balances and create a transaction correctly', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user1').set({'balance': 100, 'first_name': 'John'});
        await fakeFirestore.collection('users').doc('user2').set({'balance': 50, 'first_name': 'Jane'});

        // Act
        await paymentsData.addTransaction(fromUserId: 'user1', toUserId: 'user2', amount: 30);

        // Assert
        final user1Doc = await fakeFirestore.collection('users').doc('user1').get();
        final user2Doc = await fakeFirestore.collection('users').doc('user2').get();
        final transactionSnapshot = await fakeFirestore.collection('transactions').get();

        expect(user1Doc.data()?['balance'], 70);
        expect(user2Doc.data()?['balance'], 80);
        expect(transactionSnapshot.docs.length, 1);
        expect(transactionSnapshot.docs.first.data()['amount'], 30);
      });

      test('should handle transactions where fromUserId and toUserId are the same', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user1').set({'balance': 100, 'first_name': 'John'});

        // Act
        await paymentsData.addTransaction(fromUserId: 'user1', toUserId: 'user1', amount: 50);

        // Assert
        final user1Doc = await fakeFirestore.collection('users').doc('user1').get();
        final transactionSnapshot = await fakeFirestore.collection('transactions').get();

        expect(user1Doc.data()?['balance'], 100); // Balance should not change
        expect(transactionSnapshot.docs.length, 1);
        expect(transactionSnapshot.docs.first.data()['amount'], 50);
      });

      test('should allow a transaction even if it results in a negative balance', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user1').set({'balance': 20, 'first_name': 'John'});
        await fakeFirestore.collection('users').doc('user2').set({'balance': 50, 'first_name': 'Jane'});

        // Act
        await paymentsData.addTransaction(fromUserId: 'user1', toUserId: 'user2', amount: 30);

        // Assert
        final user1Doc = await fakeFirestore.collection('users').doc('user1').get();
        expect(user1Doc.data()?['balance'], -10);
      });

      test('should correctly update balances even if the initial balance is not set', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user1').set({'first_name': 'John'});
        await fakeFirestore.collection('users').doc('user2').set({'first_name': 'Jane'});

        // Act
        await paymentsData.addTransaction(fromUserId: 'user1', toUserId: 'user2', amount: 30);

        // Assert
        final user1Doc = await fakeFirestore.collection('users').doc('user1').get();
        final user2Doc = await fakeFirestore.collection('users').doc('user2').get();
        expect(user1Doc.data()?['balance'], -30);
        expect(user2Doc.data()?['balance'], 30);
      });
    });

    group('addMoney', () {
      test('should increase balance and log a "Cash In" transaction', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user1').set({'balance': 100, 'first_name': 'John'});

        // Act
        await paymentsData.addMoney(userId: 'user1', amount: 50);

        // Assert
        final user1Doc = await fakeFirestore.collection('users').doc('user1').get();
        final transactionSnapshot = await fakeFirestore.collection('transactions').get();

        expect(user1Doc.data()?['balance'], 150);
        expect(transactionSnapshot.docs.length, 1);
        expect(transactionSnapshot.docs.first.data()['status'], 'Cash In');
      });

      test('should handle adding zero amount', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user1').set({'balance': 100, 'first_name': 'John'});

        // Act
        await paymentsData.addMoney(userId: 'user1', amount: 0);

        // Assert
        final user1Doc = await fakeFirestore.collection('users').doc('user1').get();
        expect(user1Doc.data()?['balance'], 100);
      });

      test('should handle adding a negative amount', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user1').set({'balance': 100, 'first_name': 'John'});

        // Act
        await paymentsData.addMoney(userId: 'user1', amount: -50);

        // Assert
        final user1Doc = await fakeFirestore.collection('users').doc('user1').get();
        expect(user1Doc.data()?['balance'], 50);
      });

      test('should work for a user that does not exist yet', () async {
        // Act
        await paymentsData.addMoney(userId: 'new_user', amount: 50);

        // Assert
        final userDoc = await fakeFirestore.collection('users').doc('new_user').get();
        expect(userDoc.data()?['balance'], 50);
      });
    });

    group('getBalance', () {
      test('should return a stream of the user\'s balance', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user1').set({'balance': 100});

        // Act
        final balanceStream = paymentsData.getBalance('user1');

        // Assert
        expect(balanceStream, emits(100));
      });

      test('should return 0 for a user that does not exist', () async {
        // Act
        final balanceStream = paymentsData.getBalance('non_existent_user');

        // Assert
        expect(balanceStream, emits(0));
      });
    });

    group('getUserTransactions', () {
      test('should return a stream of transactions for a user', () async {
        // Arrange
        await fakeFirestore.collection('transactions').add({'fromUserId': 'user1', 'toUserId': 'user2', 'amount': 50, 'timestamp': DateTime.now()});
        await fakeFirestore.collection('transactions').add({'fromUserId': 'user2', 'toUserId': 'user1', 'amount': 20, 'timestamp': DateTime.now()});

        // Act
        final transactionsStream = paymentsData.getUserTransactions('user1');

        // Assert
        expect(transactionsStream, emits(isA<List<Map<String, dynamic>>>().having((list) => list.length, 'length', 2)));
      });

      test('should return an empty list for a user with no transactions', () async {
        // Act
        final transactionsStream = paymentsData.getUserTransactions('user_with_no_transactions');

        // Assert
        expect(transactionsStream, emits([]));
      });
    });

    group('getDoctors', () {
      test('should return a list of users with the "doctor" role', () async {
        // Arrange
        await fakeFirestore.collection('users').add({'role': 'doctor', 'first_name': 'Dr. Smith'});
        await fakeFirestore.collection('users').add({'role': 'patient', 'first_name': 'John Doe'});

        // Act
        final doctors = await paymentsData.getDoctors();

        // Assert
        expect(doctors.length, 1);
        expect(doctors.first['first_name'], 'Dr. Smith');
      });

      test('should return an empty list when no doctors are found', () async {
        // Arrange
        await fakeFirestore.collection('users').add({'role': 'patient', 'first_name': 'John Doe'});

        // Act
        final doctors = await paymentsData.getDoctors();

        // Assert
        expect(doctors.isEmpty, isTrue);
      });
    });
  });
}