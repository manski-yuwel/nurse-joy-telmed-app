import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Update user profile
  Future<void> updateProfile({
    required String userID,
    required String profilePicURL,
    required String email,
    required String firstName,
    required String lastName,
    required String fullName,
    required String fullNameLower,
    required String civilStatus,
    required int age,
    required DateTime birthdate,
    required String address,
    required String phoneNumber,
    String? username,
    String? currentPassword,
    String? newPassword,
  }) async {
    // Check if sensitive operations (email/password change) are requested
    final needsReauthentication =
        (email != _auth.currentUser!.email && email.isNotEmpty) ||
            (newPassword != null && newPassword.isNotEmpty);

    // Validate current password if sensitive operations are requested
    if (needsReauthentication) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception(
            'Current password is required for changing email or password');
      }

      try {
        // Create credential for re-authentication
        final credential = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: currentPassword,
        );

        // Re-authenticate user
        await _auth.currentUser!.reauthenticateWithCredential(credential);
      } catch (e) {
        throw Exception('Current password is incorrect');
      }
    }

    // Update profile picture if changed
    if (profilePicURL != _auth.currentUser!.photoURL) {
      await _auth.currentUser!.updatePhotoURL(profilePicURL);
    }

    // Update email if changed
    if (email != _auth.currentUser!.email && email.isNotEmpty) {
      await _auth.currentUser!.verifyBeforeUpdateEmail(email);
    }

    // Update password if provided
    if (newPassword != null && newPassword.isNotEmpty) {
      await _auth.currentUser!.updatePassword(newPassword);
    }

    // Update display name with username if provided, otherwise use full name
    final newDisplayName = username ?? '$firstName $lastName';
    if (newDisplayName != _auth.currentUser!.displayName) {
      await _auth.currentUser!.updateDisplayName(newDisplayName);
    }

    // Update user document in Firestore
    await _firestore.collection('users').doc(userID).update({
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'full_name_lower': fullNameLower,
      'civil_status': civilStatus,
      'age': age,
      'birthdate': birthdate,
      'address': address,
      'phone_number': phoneNumber,
      'username': username,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Get user profile
  Future<DocumentSnapshot> getProfile(String userID) async {
    return await _firestore.collection('users').doc(userID).get();
  }

  // Set user setup status
  Future<void> setIsSetup(String userID, bool isSetup) async {
    return await _firestore.collection('users').doc(userID).update({
      'is_setup': isSetup,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Get user profile picture URL
  Future<String> getProfilePicURL(String userID) async {
    final doc = await _firestore.collection('users').doc(userID).get();
    return doc.data()?['profile_pic'] ?? '';
  }

  // Update doctor availability schedule
  Future<void> updateDoctorAvailability(
    String userID,
    List<Map<String, dynamic>> availabilitySchedule,
  ) async {
    await _firestore.collection('users').doc(userID).update({
      'availability_schedule': availabilitySchedule,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Update doctor profile information
  Future<void> updateDoctorProfile(
    String userID, {
    required String bio,
    required String workingHistory,
    required List<String> languages,
    required List<String> servicesOffered,
  }) async {
    await _firestore.collection('users').doc(userID).update({
      'bio': bio,
      'working_history': workingHistory,
      'languages': languages,
      'services_offered': servicesOffered,
      'is_doctor': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Get doctor profile
  Future<DocumentSnapshot> getDoctorProfile(String userID) async {
    return await _firestore.collection('users').doc(userID).get();
  }
}
