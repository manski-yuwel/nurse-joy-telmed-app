import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_service.dart';
import 'package:nursejoyapp/features/doctor/ui/widgets/date_time_picker.dart';
import 'package:nursejoyapp/notifications/notification_service.dart';
import 'package:dio/dio.dart';

// Mock classes
class MockDio extends Mock implements Dio {
  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return super.noSuchMethod(
      Invocation.method(
        #post, 
        [path], 
        {
          #data: data,
          #queryParameters: queryParameters,
          #options: options,
          #cancelToken: cancelToken,
          #onSendProgress: onSendProgress,
          #onReceiveProgress: onReceiveProgress,
        },
      ),
      returnValue: Response<T>(
        data: {} as T,
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }
}

class MockNotificationService extends Mock implements NotificationService {
  @override
  Future<void> registerActivity(
    String userID, 
    String title, 
    Map<String, dynamic> body, 
    String type,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#registerActivity, [userID, title, body, type]),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    ) as Future<void>;
  }
}

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


    test('registerEnhancedAppointment registers a new appointment', () async {
      final doctorId = 'doctor1';
      final patientId = 'patient1';
      final now = DateTime.now();
      final timeSlot = AppointmentTimeSlot(
        id: '1',
        startTime: TimeOfDay.now(),
        endTime: TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0),
      );
      final selectedDay = AppointmentDay(
        id: '1',
        date: now,
        timeSlots: [timeSlot],
      );
      final booking = AppointmentBooking(
        selectedDay: selectedDay,
        selectedTimeSlot: timeSlot,
        userAvailableDays: [selectedDay],
        description: 'Checkup',
      );

      // set up the registerActivity
      when(mockNotificationService.registerActivity(
        patientId,
        'You have a new appointment with John Doe',
        {
          'doctorID': doctorId,
          'patientID': patientId,
          'appointmentDateTime': booking.appointmentDateTime.toIso8601String(),
        },
        'appointment',
      )).thenAnswer((_) => Future.value());

      // set up the dio post
      when(mockDio.post(
        'https://nurse-joy-api.vercel.app/api/notifications/appointments',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((invocation) async {
        final data = invocation.namedArguments[#data] as Map<String, dynamic>;
        expect(data['userID'], patientId);
        expect(data['doctorID'], doctorId);
        expect(data['appointmentDateTime'], isNotNull);
        expect(data['description'], 'Checkup');
        
        return Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });
      
      await fakeFirestore.collection('users').doc(doctorId).set({
        'first_name': 'John',
        'last_name': 'Doe',
        'role': 'doctor',
        'is_verified': true,
        'specialization': 'Cardiology',
        'consultation_fee': 100,
        'search_index': ['john', 'doe', 'cardiology'],
      });

      final doctorSnap = await fakeFirestore.collection('users').doc(doctorId).get();
      final fee = doctorSnap.data()?['consultation_fee'] ?? 0;
      await doctorService.registerEnhancedAppointment(doctorId, patientId, booking, fee);

      final appointments = await fakeFirestore.collection('appointments').get();
      expect(appointments.docs.length, 1);
    });

    group('getVerifiedFilteredDoctorList', () {
      test('should filter by specialization', () async {
        await fakeFirestore.collection('users').add({
          'role': 'doctor',
          'is_verified': true,
          'specialization': 'Cardiology',
        });
        await fakeFirestore.collection('users').add({
          'role': 'doctor',
          'is_verified': true,
          'specialization': 'Dermatology',
        });

        final results = await doctorService.getVerifiedFilteredDoctorList(specialization: 'Cardiology');
        expect(results.length, 1);
        expect((results.first.data() as Map<String, dynamic>)['specialization'], 'Cardiology');
      });

      test('should filter by consultation fee', () async {
        await fakeFirestore.collection('users').add({
          'role': 'doctor',
          'is_verified': true,
          'consultation_fee': 100,
        });
        await fakeFirestore.collection('users').add({
          'role': 'doctor',
          'is_verified': true,
          'consultation_fee': 200,
        });

        final results = await doctorService.getVerifiedFilteredDoctorList(minFee: 150);
        expect(results.length, 1);
        expect((results.first.data() as Map<String, dynamic>)['consultation_fee'], 200);
      });

      test('should filter by a combination of specialization and fee', () async {
        await fakeFirestore.collection('users').add({
          'role': 'doctor',
          'is_verified': true,
          'specialization': 'Cardiology',
          'consultation_fee': 100,
        });
        await fakeFirestore.collection('users').add({
          'role': 'doctor',
          'is_verified': true,
          'specialization': 'Cardiology',
          'consultation_fee': 200,
        });

        final results = await doctorService.getVerifiedFilteredDoctorList(specialization: 'Cardiology', maxFee: 150);
        expect(results.length, 1);
        expect((results.first.data() as Map<String, dynamic>)['consultation_fee'], 100);
      });

      test('should return an empty list when no doctors match the criteria', () async {
        final results = await doctorService.getVerifiedFilteredDoctorList(specialization: 'NonExistent');
        expect(results, isEmpty);
      });
    });

    group('getDoctorDetails', () {
      test('should return a non-existent snapshot for a non-existent doctor', () async {
        final doc = await doctorService.getDoctorDetails('non_existent_doctor');
        expect(doc.exists, isFalse);
      });
    });

    group('getAppointmentList', () {
      test('should return an empty list when a doctor has no appointments', () async {
        final snapshot = await doctorService.getAppointmentList('doctor_with_no_appointments');
        expect(snapshot.docs, isEmpty);
      });
    });

    group('getUserAppointmentList', () {
      test('should return an empty list when a user has no appointments', () async {
        final snapshot = await doctorService.getUserAppointmentList('user_with_no_appointments');
        expect(snapshot.docs, isEmpty);
      });
    });

    group('registerAppointment', () {
      test('should register an appointment and make a Dio call', () async {
        final doctorId = 'doctor1';
        final patientId = 'patient1';
        final appointmentDateTime = DateTime.now();

        when(mockDio.post(
          'https://nurse-joy-api.vercel.app/api/notifications/appointments',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200));

        await doctorService.registerAppointment(doctorId, patientId, appointmentDateTime, 500);

        final appointments = await fakeFirestore.collection('appointments').get();
        expect(appointments.docs.length, 1);
        final appointmentData = appointments.docs.first.data();
        expect(appointmentData['doctorID'], doctorId);
        expect(appointmentData['userID'], patientId);

        verify(mockDio.post('https://nurse-joy-api.vercel.app/api/notifications/appointments', data: anyNamed('data'), options: anyNamed('options'))).called(1);
      });
    });

    group('registerEnhancedAppointment', () {
      test('should throw an exception if the doctor is not found', () async {
        final booking = AppointmentBooking(
          selectedDay: AppointmentDay(id: '1', date: DateTime.now(), timeSlots: []),
          selectedTimeSlot: AppointmentTimeSlot(id: '1', startTime: TimeOfDay.now(), endTime: TimeOfDay.now()),
          userAvailableDays: [],
          description: '',
        );

        expect(
          () => doctorService.registerEnhancedAppointment('non_existent_doctor', 'patient1', booking, 500),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}

    