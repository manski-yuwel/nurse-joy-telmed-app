
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:nursejoyapp/features/doctor/ui/widgets/date_time_picker.dart';
import 'package:nursejoyapp/notifications/notification_service.dart';

class DoctorService {
  final FirebaseFirestore firestore;
  final Dio dio;
  final NotificationService notificationService;

  DoctorService({
    FirebaseFirestore? firestore,
    Dio? dio,
    NotificationService? notificationService,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        dio = dio ?? Dio(),
        notificationService = notificationService ?? NotificationService();

  Future<List<DocumentSnapshot>> getVerifiedFilteredDoctorList({
    String? searchQuery,
    String? specialization,
    int? minFee,
    int? maxFee,
  }) async {
    var query = firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('is_verified', isEqualTo: true);

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
    final doctorDetails = await firestore.collection('users').doc(doctorId).get();
    return doctorDetails;
  }

  Future<QuerySnapshot> getAppointmentList(String doctorId) async {
    final appointmentList = await firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .get();

    return appointmentList;
  }

  Future<DocumentSnapshot> getUserDetails(String userId) async {
    final userDetails = await firestore.collection('users').doc(userId).get();
    return userDetails;
  }

  Future<DocumentSnapshot> getAppointmentDetails(String appointmentId) async {
    final appointmentDetails =
        await firestore.collection('appointments').doc(appointmentId).get();

    return appointmentDetails;
  }

  Future<QuerySnapshot> getUserAppointmentList(String userID) async {
    final appointmentList = await firestore
        .collection('appointments')
        .where('userID', isEqualTo: userID)
        .get();

    return appointmentList;
  }

  Future<void> registerAppointment(
      String doctorId, String patientId, DateTime appointmentDateTime) async {
    await firestore.collection('appointments').add({
      'userID': patientId,
      'doctorID': doctorId,
      'appointmentDateTime': appointmentDateTime,
    });

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
        'availableDays':
            booking.userAvailableDays.map((day) => day.toMap()).toList(),
        'dayOfWeek': booking.selectedDay.date.weekday,
        'timeSlotStart': booking.selectedTimeSlot.startTime.hour * 60 +
            booking.selectedTimeSlot.startTime.minute,
        'timeSlotEnd': booking.selectedTimeSlot.endTime.hour * 60 +
            booking.selectedTimeSlot.endTime.minute,
      };

      final docRef = await firestore.collection('appointments').add(appointmentData);
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

      final doctorDoc = await getDoctorDetails(doctorId);
      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      final doctorFullName =
          '${doctorData['first_name']} ${doctorData['last_name']}';

      notificationService.registerActivity(
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
}
