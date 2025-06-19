import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

// define functions to fetch doctor list from Firestore
Future<QuerySnapshot> getDoctorList() async {
  final doctorList = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').get();
  
  return doctorList;
}

Future<DocumentSnapshot> getDoctorDetails(String doctorId) async {
  final doctorDetails = await FirebaseFirestore.instance.collection('users').doc(doctorId).collection('doctor_information').doc('profile').get();

  return doctorDetails;
}


// get appointment list
Future<QuerySnapshot> getAppointmentList(String doctorId) async {
  // sort appointment list by created_at
  final appointmentList = await FirebaseFirestore.instance.collection('appointments').where('doctorId', isEqualTo: doctorId).orderBy('createdAt', descending: true).get();

  return appointmentList;
}


// get user details
Future<DocumentSnapshot> getUserDetails(String userId) async {
  final userDetails = await FirebaseFirestore.instance.collection('users').doc(userId).get();

  return userDetails;
}

// get appointment details
Future<DocumentSnapshot> getAppointmentDetails(String appointmentId) async {
  final appointmentDetails = await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).get();

  return appointmentDetails;
}

// get user appointment list
Future<QuerySnapshot> getUserAppointmentList(String userID) async {
  final appointmentList = await FirebaseFirestore.instance.collection('appointments').where('userID', isEqualTo: userID).get();

  return appointmentList;
}


// register appointment
Future<void> registerAppointment(String doctorId, String patientId, DateTime appointmentDateTime) async {


  // register appointment in Firestore
  await FirebaseFirestore.instance.collection('appointments').add({
    'userID': patientId,
    'doctorID': doctorId,
    'appointmentDateTime': appointmentDateTime,
  });

  // register appointment in FCM using dio
  final dio = Dio();
  await dio.post('https://nurse-joy-api.vercel.app/api/notifications/appointments', data: {
    'userID': patientId,
    'doctorID': doctorId,
    'appointmentDateTime': appointmentDateTime.toIso8601String(),
  },
  options: Options(headers: {
    'Content-Type': 'application/json',
  },
  validateStatus: (status) {
    return status! < 500;
  },
  ),
  );
}

