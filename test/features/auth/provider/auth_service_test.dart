import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  
  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  const testUid = 'test_uid';
  const testDisplayName = 'Test User';
  const testPhotoUrl = 'https://example.com/photo.jpg';

  setUp(() {
    // Initialize mocks
    auth = MockFirebaseAuth(
      mockUser: MockUser(
        uid: testUid,
        email: testEmail,
        displayName: testDisplayName,
        photoURL: testPhotoUrl,
        isEmailVerified: true,
      ),
    );
    
    firestore = FakeFirebaseFirestore();
  });

  group('Authentication', () {
    test('should sign in with email and password', () async {
      // Act
      final userCredential = await auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      
      // Assert
      expect(userCredential.user, isNotNull);
      expect(userCredential.user!.email, testEmail);
      expect(userCredential.user!.uid, testUid);
    });

    test('should create user with email and password', () async {
      // Act - Use the mock auth instance directly
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'password123',
      );
      
      // Assert
      expect(userCredential.user, isNotNull);
      expect(userCredential.user!.email, 'new@example.com');
      expect(userCredential.user!.emailVerified, isTrue); // Mock user is verified by default
    });

    test('should sign out user', () async {
      // Arrange - sign in first
      await auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      
      // Act
      await auth.signOut();
      
      expect(auth.currentUser, isNull);
    });
  });

  group('Firestore Integration', () {
    test('should create and retrieve user document', () async {
      const testUid = 'test_user_123';
      const testEmail = 'test@example.com';
      const testDisplayName = 'Test User';

      await firestore.collection('users').doc(testUid).set({
        'email': testEmail,
        'displayName': testDisplayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final doc = await firestore.collection('users').doc(testUid).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['email'], testEmail);
      expect(doc.data()!['displayName'], testDisplayName);
      expect(doc.data(), contains('createdAt'));
    });
  });


}
