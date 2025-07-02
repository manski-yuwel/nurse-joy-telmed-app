import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:nursejoyapp/features/doctor/ui/widgets/date_time_picker.dart';
import 'package:nursejoyapp/notifications/notification_service.dart';


// define functions to fetch doctor list from Firestore
Future<QuerySnapshot> getDoctorList() async {
  final doctorList = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'doctor')
      .get();

  return doctorList;
}


Future<List<DocumentSnapshot>> getVerifiedFilteredDoctorList(
  {
    String? searchQuery,
    String? specialization,
    int? minFee,
    int? maxFee,
  }) async {
  final firestore = FirebaseFirestore.instance;

  var query = firestore
      .collection('users')
      .where('role', isEqualTo: 'doctor').where('is_verified', isEqualTo: true);

  if (searchQuery != null && searchQuery.isNotEmpty) {
    query = query.where('search_index', arrayContains: searchQuery.toLowerCase());
  }

  final querySnapshot = await query.get();

  final List<DocumentSnapshot> verifiedDoctors = [];

  for (final doc in querySnapshot.docs) {
    try {
      final userData = doc.data() as Map<String, dynamic>?;
      if (userData == null || userData['is_verified'] != true) continue;

      final docSpecialization = userData['specialization'];
      final fee = userData['consultation_fee'] as int? ?? 0;

      bool matches = true;

      if (specialization != null &&
          specialization != 'All Specializations' &&
          docSpecialization != specialization) {
        matches = false;
      }

      if (minFee != null && fee < minFee) matches = false;
      if (maxFee != null && fee > maxFee) matches = false;

      if (matches) {
        verifiedDoctors.add(doc);
      }
    } catch (e) {
      print('Error filtering doctor ${doc.id}: $e');
    }
  }

  return verifiedDoctors;
}


Future<DocumentSnapshot> getDoctorDetails(String doctorId) async {
  final doctorDetails = await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
  return doctorDetails;
}

// get appointment list
Future<QuerySnapshot> getAppointmentList(String doctorId) async {
  final appointmentList = await FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: doctorId)
      .get();

  return appointmentList;
}

// get user details
Future<DocumentSnapshot> getUserDetails(String userId) async {
  final userDetails = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return userDetails;
}

// get appointment details
Future<DocumentSnapshot> getAppointmentDetails(String appointmentId) async {
  final appointmentDetails = await FirebaseFirestore.instance
      .collection('appointments')
      .doc(appointmentId)
      .get();

  return appointmentDetails;
}


// get user appointment list
Future<QuerySnapshot> getUserAppointmentList(String userID) async {
  final appointmentList = await FirebaseFirestore.instance.collection('appointments').where('userID', isEqualTo: userID).get();

  return appointmentList;
}




// register appointment
Future<void> registerAppointment(
    String doctorId, String patientId, DateTime appointmentDateTime) async {
  // register appointment in Firestore
  DocumentReference appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
    'userID': patientId,
    'doctorID': doctorId,
    'appointmentDateTime': appointmentDateTime,
  });

  // register appointment in FCM using dio
  final dio = Dio();
  await dio.post(
    'https://nurse-joy-api.vercel.app/api/notifications/appointments',
    data: {
      'userID': patientId,
      'doctorID': doctorId,
      'appointmentDateTime': appointmentDateTime.toIso8601String(),
    },
    options: Options(
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        return status! < 500;
      },
    ),
  );

}


Future<void> registerEnhancedAppointment(
  String doctorId, 
  String patientId, 
  AppointmentBooking booking,
) async {
  try {
    final appointmentData = {
      'userID': patientId,
      'doctorID': doctorId,
      'appointmentDateTime': Timestamp.fromDate(booking.appointmentDateTime),
      'description': booking.description,
      'status': 'scheduled',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      
      'bookingDetails': booking.toMap(),
      'availableDays': booking.userAvailableDays.map((day) => day.toMap()).toList(),
      
      'dayOfWeek': booking.selectedDay.date.weekday,
      'timeSlotStart': booking.selectedTimeSlot.startTime.hour * 60 + booking.selectedTimeSlot.startTime.minute,
      'timeSlotEnd': booking.selectedTimeSlot.endTime.hour * 60 + booking.selectedTimeSlot.endTime.minute,
    };

    print(appointmentData);

    final docRef = await FirebaseFirestore.instance
        .collection('appointments')
        .add(appointmentData);
    final dio = Dio();
    await dio.post(
      'https://nurse-joy-api.vercel.app/api/notifications/appointments',
      data: {
        'userID': patientId,
        'doctorID': doctorId,
        'appointmentDateTime': booking.appointmentDateTime.toIso8601String(),
        'appointmentId': docRef.id,
        'description': booking.description,
        'timeSlot': booking.selectedTimeSlot.displayTime,
        'date': booking.selectedDay.displayDate,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status! < 500,
      ),
    );

    // Get doctor and user details
    final doctorDoc = await getDoctorDetails(doctorId);
    final doctorData = doctorDoc.data() as Map<String, dynamic>;
    final doctorFullName = '${doctorData['first_name']} ${doctorData['last_name']}';

    NotificationService().registerActivity(
      patientId,
      'You have a new appointment with $doctorFullName',
      {
        'doctorID': doctorId,
        'patientID': patientId,
        'appointmentDateTime': booking.appointmentDateTime.toIso8601String(),
      },
      'appointment',
    );
  } catch (e) {
    throw Exception('Failed to register appointment: $e');
  }

}
