
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
    String fullName,
    String fullNameLower,
    String civilStatus,
    int age,
    DateTime birthdate,
    String address,
    String phoneNumber,) async {
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
    'full_name': fullName,
    'full_name_lowercase': fullNameLower,
    'civil_status': civilStatus,
    'age': age,
    'birthdate': birthdate,
    'address': address,
    'phone_number': phoneNumber,
  });
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


List<String> createSearchIndex(String fullName) {
    final List<String> parts = fullName.split(' ');
    final List<String> nGrams = [];
    for (String part in parts) {
      nGrams.addAll(createNGrams(part));
    }
    return nGrams;
  }

List<String> createNGrams(String part,
      {int minGram = 1, int maxGram = 10}) {
    final List<String> nGrams = [];
    for (int i = 1; i <= maxGram; i++) {
      if (i <= part.length) {
        nGrams.add(part.substring(0, i));
      }
    }
    return nGrams;
  }