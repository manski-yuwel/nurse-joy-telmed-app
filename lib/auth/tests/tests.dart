import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;

  setUp(() async {
    auth = MockFirebaseAuth();
    db = FakeFirebaseFirestore();
  });
  group('Auth Service Tests', () {
    test('should create new user document in firestore after new user signs up',
        () async {
      // create initial test user creds
      final email = 'test12345678@gmail.com';
      final password = 'test12345678';

      // create the user
      await auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // sign in the user and get the user
      final userCredentials = await auth.signInWithEmailAndPassword(
          email: email, password: password);

      // get the user's uid
      final uid = userCredentials.user!.uid;

      // get the user document and test whether it exists
      final userDoc = await db.collection('users').doc(uid).get();
      expect(userDoc.exists, true);
    });
  });
}
