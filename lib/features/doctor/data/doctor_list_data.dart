import 'package:cloud_firestore/cloud_firestore.dart';

// define functions to fetch doctor list from Firestore
Future<List<Map<String, dynamic>>> getDoctorList() async {
  final doctorList = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').get();
  return doctorList.docs.map((doc) => doc.data()).toList();
}