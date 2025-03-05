import 'package:cloud_firestore/cloud_firestore.dart';

final db = FirebaseFirestore.instance;

Future<void> UpdateProfile(
    String userID,
    String firstName,
    String lastName,
    String civilStatus,
    int age,
    DateTime birthdate,
    String address,
    String phoneNumber) {
  // update the user's profile
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
