import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// initialize firestore and firebase auth
final db = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;

// update the user's profile
Future<void> updateProfile(
    String userID,
    String profilePicURL,
    String email,
    String firstName,
    String lastName,
    String fullName,
    String fullNameLower,
    String civilStatus,
    int age,
    DateTime birthdate,
    String address,
    String phoneNumber,
    {String? username,
    String? currentPassword,
    String? newPassword}) async {
  // Check if sensitive operations (email/password change) are requested
  bool needsReauthentication =
      (email != auth.currentUser!.email && email.isNotEmpty) ||
          (newPassword != null && newPassword.isNotEmpty);

  // Validate current password if sensitive operations are requested
  if (needsReauthentication) {
    if (currentPassword == null || currentPassword.isEmpty) {
      throw Exception(
          'Current password is required for changing email or password');
    }

    try {
      // Create credential for re-authentication
      AuthCredential credential = EmailAuthProvider.credential(
        email: auth.currentUser!.email!,
        password: currentPassword,
      );

      // Re-authenticate user
      await auth.currentUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      throw Exception('Current password is incorrect');
    }
  }

  // Now proceed with profile updates
  if (profilePicURL != auth.currentUser!.photoURL) {
    await auth.currentUser!.updatePhotoURL(profilePicURL);
  }

  // Update email if changed
  if (email != auth.currentUser!.email && email.isNotEmpty) {
    await auth.currentUser!.verifyBeforeUpdateEmail(email);
  }

  // Update password if provided
  if (newPassword != null && newPassword.isNotEmpty) {
    await auth.currentUser!.updatePassword(newPassword);
  }

  // Update display name with username if provided, otherwise use full name
  String newDisplayName = username ?? '$firstName $lastName';
  if (newDisplayName != auth.currentUser!.displayName) {
    await auth.currentUser!.updateDisplayName(newDisplayName);
  }
}

// function to get the user's profile details
Future<DocumentSnapshot> getProfile(String userID) async {
  return await db.collection('users').doc(userID).get();
}

Future<void> setIsSetup(String userID, bool isSetup) async {
  return await db.collection('users').doc(userID).update({
    'is_setup': isSetup,
  });
}


// get user profile pic url
Future<String> getProfilePicURL(String userID) async {
  final doc = await db.collection('users').doc(userID).get();
  return doc.data()!['profile_pic'];
}
