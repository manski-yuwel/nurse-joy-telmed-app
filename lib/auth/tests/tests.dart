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
      final userCredentials = await auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // get the user's uid
      final uid = userCredentials.user!.uid;

      // create the doc for the new user
      await db.collection('users').doc(uid).set({
        'email': email,
        'profile_pic': '',
        'first_name': '',
        'last_name': '',
        'civil_status': '',
        'age': 0,
        'balance': 0,
        'birthdate': null,
        'address': '',
        'phone_number': '',
        'role': 'user',
        'status_online': false,
      });

      await db
          .collection('users')
          .doc(uid)
          .collection('health_information')
          .doc('health_info')
          .set({
        'height': 0,
        'weight': 0,
        'blood_type': '',
        'allergies': [],
        'medications': [],
        'other_information': '',
      });

      // get the user document and test whether it exists
      final userDoc = await db.collection('users').doc(uid).get();
      expect(userDoc.exists, true);
    });

    test('should update user status_online to true if user signs in', () async {
      // TO-DO IMPLEMENT TEST
    });

    test('should update user status_online to false if user is signed out',
        () async {
      // TO-DO IMPLEMENT TEST
    });
  });
}
