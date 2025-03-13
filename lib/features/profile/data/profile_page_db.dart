import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// initialize firestore and firebase auth
final db = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;

// update the user's profile
// did not include username because authentication is yet to be implemented
Future<void> updateProfile(
    String userID,
    String profilePicURL,
    String email,
    String firstName,
    String lastName,
    String civilStatus,
    int age,
    DateTime birthdate,
    String address,
    String phoneNumber) async {
  // use auth to update the user's profile with the ones built-in the user type with firebase auth
  if (profilePicURL != auth.currentUser!.photoURL) {
    await auth.currentUser!.updatePhotoURL(profilePicURL);
  }
  if (email != auth.currentUser!.email) {
    await auth.currentUser!.verifyBeforeUpdateEmail(email);
  }
  if ('$firstName $lastName' != auth.currentUser!.displayName) {
    await auth.currentUser!.updateDisplayName('$firstName $lastName');
  }

  // update the user's profile through firestore
  return db.collection('users').doc(userID).update({
    'first_name': firstName,
    'last_name': lastName,
    'civil_status': civilStatus,
    'age': age,
    'birthdate': birthdate,
    'address': address,
    'phone_number': phoneNumber
  });
}

// function to get the user's profile details
Future<DocumentSnapshot> getProfile(String userID) async {
  return await db.collection('users').doc(userID).get();
}
