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
      .where('doctorID', isEqualTo: doctorId)
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
  try {
    final appointmentList = await FirebaseFirestore.instance.collection('appointments').where('userID', isEqualTo: userID).orderBy('createdAt', descending: true).get();
    return appointmentList;
  } catch (e) {
    throw Exception('Failed to get user appointment list: $e');
  }
}




// register appointment
Future<void> registerAppointment(
    String doctorId, String patientId, DateTime appointmentDateTime) async {
  // register appointment in Firestore
  await FirebaseFirestore.instance.collection('appointments').add({
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
  int fee,
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
      'fee': fee,
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
        'id': docRef.id,
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

Future<void> updateAppointmentStatus(String appointmentId, String status) async {
  await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({'status': status});

  // notify user
  final appointmentDoc = await getAppointmentDetails(appointmentId);
  final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
  final userId = appointmentData['userID'];
  final doctorId = appointmentData['doctorID'];
  final appointmentDateTime = appointmentData['appointmentDateTime'];

  // Get doctor details
  final doctorDoc = await getDoctorDetails(doctorId);
  final doctorData = doctorDoc.data() as Map<String, dynamic>;

  // Convert Firestore Timestamp to DateTime before converting to ISO string
  final dateTime = appointmentDateTime is Timestamp 
      ? appointmentDateTime.toDate() 
      : appointmentDateTime;

  // determine if the doctor is the current user
  final currentUser = await getDoctorDetails(doctorId);
  final currentUserData = currentUser.data() as Map<String, dynamic>;
  final isDoctor = currentUserData['role'] == 'doctor';

  if (isDoctor) {
    // get user details
    final userDoc = await getUserDetails(userId);
    final userData = userDoc.data() as Map<String, dynamic>;
    final userFullName = '${userData['first_name']} ${userData['last_name']}';
    NotificationService().registerActivity(
      doctorId,
      'Your appointment with $userFullName has been updated to $status',
      {
        'id': appointmentId,
        'doctorID': doctorId,
        'patientID': userId,
        'appointmentDateTime': dateTime.toIso8601String(),
      },
      'appointment',
    );
  } else {
    NotificationService().registerActivity(
      userId,
      'Your appointment with ${doctorData['first_name']} ${doctorData['last_name']} has been updated to $status',
      {
        'id': appointmentId,
        'doctorID': doctorId,
        'patientID': userId,
        'appointmentDateTime': dateTime.toIso8601String(),
      },
      'appointment',
    );
  }
      
  NotificationService().registerActivity(
    userId,
    'Your appointment with ${doctorData['first_name']} ${doctorData['last_name']} has been updated to $status',
    {
      'id': appointmentId,
      'doctorID': doctorId,
      'patientID': userId,
      'appointmentDateTime': dateTime.toIso8601String(),
    },
    'appointment',
  );
}


Future<void> saveDoctorNotes(String appointmentId, String notes) async {
  await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({'doctor_notes': notes});
} 

Future<void> savePatientNotes(String appointmentId, String notes) async {
  await FirebaseFirestore.instance
      .collection('appointments')
      .doc(appointmentId)
      .update({'patientNotes': notes});
}

// Get user's medical history
Future<String> getUserMedicalHistory(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
        
    final userDetails = doc.data() as Map<String, dynamic>;
    final medicalHistory = userDetails['medical_history'];
    if (doc.exists) {
      return medicalHistory;
    }
    return '';
  } catch (e) {
    return '';
  }
}

Future<void> rescheduleAppointment({
  required String appointmentId,
  required DateTime newDateTime,
  required String doctorId,
  required String patientId,
}) async {
  final appointmentRef = FirebaseFirestore.instance.collection('appointments').doc(appointmentId);
  
  // Get the current appointment data
  final appointmentDoc = await appointmentRef.get();
  if (!appointmentDoc.exists) {
    throw Exception('Appointment not found');
  }
  
  final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
  final oldDateTime = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
  
  // Update the appointment with new date/time
  await appointmentRef.update({
    'appointmentDateTime': Timestamp.fromDate(newDateTime),
    'status': 'rescheduled',
    'previousDate': Timestamp.fromDate(oldDateTime),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  
  // Get user details for notification
  final doctorDoc = await getDoctorDetails(doctorId);
  final patientDoc = await getUserDetails(patientId);
  
  if (doctorDoc.exists && patientDoc.exists) {
    final doctorData = doctorDoc.data() as Map<String, dynamic>;
    final patientData = patientDoc.data() as Map<String, dynamic>;
    
    // Notify patient
    await NotificationService().registerActivity(
      patientId,
      'Your appointment with Dr. ${doctorData['last_name']} has been rescheduled',
      {
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'patientId': patientId,
        'appointmentDateTime': newDateTime.toIso8601String(),
      },
      'appointment',
    );
    
    // Notify doctor
    await NotificationService().registerActivity(
      doctorId,
      'Appointment with ${patientData['first_name']} ${patientData['last_name']} has been rescheduled',
      {
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'patientId': patientId,
        'appointmentDateTime': newDateTime.toIso8601String(),
      },
      'appointment',
    );
  }
}
