import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_service.dart';
import 'package:nursejoyapp/features/doctor/ui/widgets/date_time_picker.dart';
import 'package:nursejoyapp/notifications/notification_service.dart';
import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('DoctorService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockDio mockDio;
    late MockNotificationService mockNotificationService;
    late DoctorService doctorService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockDio = MockDio();
      mockNotificationService = MockNotificationService();
      doctorService = DoctorService(
        firestore: fakeFirestore,
        dio: mockDio,
        notificationService: mockNotificationService,
      );
    });

    test('getVerifiedFilteredDoctorList returns a list of verified doctors', () async {
      await fakeFirestore.collection('users').add({
        'role': 'doctor',
        'is_verified': true,
        'search_index': ['dr', 'john', 'doe'],
        'specialization': 'Cardiology',
        'consultation_fee': 100,
      });
      await fakeFirestore.collection('users').add({
        'role': 'doctor',
        'is_verified': false,
      });

      final results = await doctorService.getVerifiedFilteredDoctorList();

      expect(results.length, 1);
    });

    test('getDoctorDetails returns the correct doctor details', () async {
      final doctorId = 'doctor1';
      await fakeFirestore.collection('users').doc(doctorId).set({'name': 'Dr. John Doe'});

      final doc = await doctorService.getDoctorDetails(doctorId);

      expect(doc.exists, isTrue);
      expect((doc.data() as Map<String, dynamic>)['name'], 'Dr. John Doe');
    });

    test('getAppointmentList returns a list of appointments for a doctor', () async {
      final doctorId = 'doctor1';
      await fakeFirestore.collection('appointments').add({
        'doctorId': doctorId,
        'createdAt': DateTime.now(),
      });

      final snapshot = await doctorService.getAppointmentList(doctorId);

      expect(snapshot.docs.length, 1);
    });

    test('getUserDetails returns the correct user details', () async {
      final userId = 'user1';
      await fakeFirestore.collection('users').doc(userId).set({'name': 'John Doe'});

      final doc = await doctorService.getUserDetails(userId);

      expect(doc.exists, isTrue);
      expect((doc.data() as Map<String, dynamic>)['name'], 'John Doe');
    });

    test('getAppointmentDetails returns the correct appointment details', () async {
      final appointmentId = 'appointment1';
      await fakeFirestore.collection('appointments').doc(appointmentId).set({'description': 'Checkup'});

      final doc = await doctorService.getAppointmentDetails(appointmentId);

      expect(doc.exists, isTrue);
      expect((doc.data() as Map<String, dynamic>)['description'], 'Checkup');
    });

    test('getUserAppointmentList returns a list of appointments for a user', () async {
      final userId = 'user1';
      await fakeFirestore.collection('appointments').add({
        'userID': userId,
      });

      final snapshot = await doctorService.getUserAppointmentList(userId);

      expect(snapshot.docs.length, 1);
    });

    test('registerAppointment registers a new appointment', () async {
      final doctorId = 'doctor1';
      final patientId = 'patient1';
      final appointmentDateTime = DateTime.now();

      when(mockDio.post(argThat(isA<String>()), data: anyNamed('data'), options: anyNamed('options')))
          .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200));

      await doctorService.registerAppointment(doctorId, patientId, appointmentDateTime);

      final appointments = await fakeFirestore.collection('appointments').get();
      expect(appointments.docs.length, 1);
    });

    test('registerEnhancedAppointment registers a new enhanced appointment', () async {
      final doctorId = 'doctor1';
      final patientId = 'patient1';
      final booking = AppointmentBooking(
        selectedDay: AppointmentDay(id: '1', date: DateTime.now(), timeSlots: []),
        selectedTimeSlot: AppointmentTimeSlot(id: '1', startTime: TimeOfDay.now(), endTime: TimeOfDay.now()),
        userAvailableDays: [],
        description: 'Checkup',
      );

      await fakeFirestore.collection('users').doc(doctorId).set({
        'first_name': 'John',
        'last_name': 'Doe',
      });

      when(mockDio.post(argThat(isA<String>()), data: anyNamed('data'), options: anyNamed('options')))
          .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200));
      when(mockNotificationService.registerActivity(
        patientId,
        'You have a new appointment with John Doe',
        {
          'doctorID': doctorId,
          'patientID': patientId,
          'appointmentDateTime': booking.appointmentDateTime.toIso8601String(),
        },
        'appointment',
      )).thenAnswer((_) async {});

      await doctorService.registerEnhancedAppointment(doctorId, patientId, booking);

      final appointments = await fakeFirestore.collection('appointments').get();
      expect(appointments.docs.length, 1);
    });
  });
}