import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nursejoyapp/features/profile/data/profile_service.dart';
// Mock for Firebase Auth
class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  User? get currentUser => MockUser();
}

// Mock for Firebase User
class MockUser extends Mock implements User {
  @override
  String get uid => 'test_user_id';
  
  @override
  String? get email => 'test@example.com';
  
  @override
  Future<void> updateEmail(String newEmail) async {}
  
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}
  
  @override
  Future<void> updatePhotoURL(String? photoURL) async {}
  
  @override
  Future<void> updateDisplayName(String? displayName) async {}
  
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    return MockUserCredential();
  }
}

// Mock for UserCredential
class MockUserCredential extends Mock implements UserCredential {
  @override
  User? get user => MockUser();
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late ProfileService profileService;
  
  const String testUserId = 'test_user_id';
  const String testEmail = 'test@example.com';
  const String testFirstName = 'John';
  const String testLastName = 'Doe';
  final DateTime testBirthdate = DateTime(1990, 1, 1);
  
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    
    // Initialize service with fake Firestore and mock Auth
    profileService = ProfileService(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
    
    // Seed initial data if needed
    fakeFirestore.collection('users').doc(testUserId).set({
      'email': testEmail,
      'first_name': testFirstName,
      'last_name': testLastName,
      'created_at': DateTime.now().toIso8601String(),
    });
  });

  group('ProfileService', () {
    test('updateProfile should update user profile data', () async {
      // Arrange
      final testProfilePicUrl = 'https://example.com/avatar.jpg';
      final testAddress = '123 Test St';
      final testPhone = '1234567890';
      final testCivilStatus = 'Single';
      final testAge = 33;
      
      // Act
      await profileService.updateProfile(
        userID: testUserId,
        profilePicURL: testProfilePicUrl,
        email: testEmail,
        firstName: testFirstName,
        lastName: testLastName,
        fullName: '$testFirstName $testLastName',
        fullNameLowercase: '${testFirstName.toLowerCase()} ${testLastName.toLowerCase()}',
        civilStatus: testCivilStatus,
        age: testAge,
        birthdate: testBirthdate,
        address: testAddress,
        phoneNumber: testPhone,
        gender: 'Male',
      );

      // Assert - Verify data was saved to Firestore
      final userDoc = await fakeFirestore.collection('users').doc(testUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      expect(userData['first_name'], testFirstName);
      expect(userData['last_name'], testLastName);
      expect(userData['email'], testEmail);
      expect(userData['full_name'], '$testFirstName $testLastName');
      expect(userData['full_name_lowercase'], '${testFirstName.toLowerCase()} ${testLastName.toLowerCase()}');
      expect(userData['civil_status'], testCivilStatus);
      expect(userData['age'], testAge);
      expect((userData['birthdate'] as Timestamp).toDate(), testBirthdate);
      expect(userData['address'], testAddress);
      expect(userData['phone_number'], testPhone);
      expect(userData['profile_pic'], testProfilePicUrl);
      expect(userData, contains('updated_at'));
    });

    test('getProfile should return user document', () async {
      // Arrange
      final testData = {
        'first_name': testFirstName,
        'last_name': testLastName,
        'email': testEmail,
      };
      
      // Add test data to fake Firestore
      await fakeFirestore.collection('users').doc(testUserId).set(testData);

      // Act
      final doc = await profileService.getProfile(testUserId);

      // Assert
      expect(doc.exists, isTrue);
      final data = doc.data() as Map<String, dynamic>?;
      expect(data, isNotNull);
      expect(data?['first_name'], testFirstName);
      expect(data?['last_name'], testLastName);
      expect(data?['email'], testEmail);
    });

    test('setIsSetup should update is_setup field', () async {
      // Act
      await profileService.setIsSetup(testUserId, true);

      // Assert
      final userDoc = await fakeFirestore.collection('users').doc(testUserId).get();
      expect(userDoc.data()?['is_setup'], isTrue);
      expect(userDoc.data(), contains('updated_at'));
    });

    test('updateDoctorAvailability should update availability schedule', () async {
      // Arrange
      final testSchedule = [
        {
          'day': 'monday',
          'startTime': Timestamp.fromDate(DateTime(2023, 1, 1, 9, 0)),
          'endTime': Timestamp.fromDate(DateTime(2023, 1, 1, 17, 0)),
        }
      ];

      // Act
      await profileService.updateDoctorAvailability(testUserId, testSchedule);

      // Assert
      final userDoc = await fakeFirestore.collection('users').doc(testUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final schedule = userData['availability_schedule'] as List;
      
      expect(schedule, isNotEmpty);
      expect(schedule[0]['day'], 'monday');
      expect((schedule[0]['startTime'] as Timestamp).toDate(), DateTime(2023, 1, 1, 9, 0));
      expect((schedule[0]['endTime'] as Timestamp).toDate(), DateTime(2023, 1, 1, 17, 0));
      expect(userDoc.data(), contains('updated_at'));
    });

    test('updateDoctorProfile should update doctor profile data', () async {
      // Arrange
      final testBio = 'Test bio';
      final testWorkingHistory = 'Test working history';
      final testLanguages = ['English', 'Spanish'];
      final testServices = ['Consultation', 'Check-up'];

      // Act
      await profileService.updateDoctorProfile(
        testUserId,
        bio: testBio,
        workingHistory: testWorkingHistory,
        languages: testLanguages,
        servicesOffered: testServices,
      );

      // Assert
      final userDoc = await fakeFirestore.collection('users').doc(testUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      expect(userData['bio'], testBio);
      expect(userData['working_history'], testWorkingHistory);
      expect(userData['languages'], testLanguages);
      expect(userData['services_offered'], testServices);
      expect(userData['is_doctor'], isTrue);
      expect(userData, contains('updated_at'));
    });

    test('getDoctorProfile should return doctor profile data', () async {
      // Arrange
      final testData = {
        'first_name': testFirstName,
        'last_name': testLastName,
        'email': testEmail,
        'is_doctor': true,
        'bio': 'Test bio',
        'working_history': 'Test working history',
        'languages': ['English'],
        'services_offered': ['Consultation'],
      };
      
      await fakeFirestore.collection('users').doc(testUserId).set(testData);

      // Act
      final doc = await profileService.getDoctorProfile(testUserId);

      // Assert
      expect(doc.exists, isTrue);
      final data = doc.data() as Map<String, dynamic>?;
      expect(data, isNotNull);
      expect(data?['first_name'], testFirstName);
      expect(data?['last_name'], testLastName);
      expect(data?['email'], testEmail);
      expect(data?['is_doctor'], isTrue);
      expect(data?['bio'], 'Test bio');
      expect(data?['working_history'], 'Test working history');
      expect(data?['languages'], ['English']);
      expect(data?['services_offered'], ['Consultation']);
    });

    test('updateDoctorProfile should handle empty data correctly', () async {
      // Act
      await profileService.updateDoctorProfile(
        testUserId,
        bio: '',
        workingHistory: '',
        languages: [],
        servicesOffered: [],
      );

      // Assert
      final userDoc = await fakeFirestore.collection('users').doc(testUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      expect(userData['bio'], '');
      expect(userData['working_history'], '');
      expect(userData['languages'], isEmpty);
      expect(userData['services_offered'], isEmpty);
      expect(userData['is_doctor'], isTrue);
      expect(userData, contains('updated_at'));
    });
  });
}
