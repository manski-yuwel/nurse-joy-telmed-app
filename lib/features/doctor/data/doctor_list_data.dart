import 'package:cloud_firestore/cloud_firestore.dart';

// define functions to fetch doctor list from Firestore
Future<QuerySnapshot> getDoctorList() async {
  final doctorList = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').get();
  
  return doctorList;
}

Future<DocumentSnapshot> getDoctorDetails(String doctorId) async {
  final doctorDetails = await FirebaseFirestore.instance.collection('users').doc(doctorId).collection('doctor_information').doc('profile').get();

  return doctorDetails;
}