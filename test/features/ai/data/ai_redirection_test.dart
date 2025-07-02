import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursejoyapp/features/ai/data/ai_redirection.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

// Generate mocks
@GenerateMocks([
  BuildContext,
  ScaffoldMessengerState,
  DocumentSnapshot<Map<String, dynamic>>,
  NavigatorObserver,
  NavigatorState,
])
import 'ai_redirection_test.mocks.dart';

void main() {
  late MockBuildContext mockContext;
  late MockScaffoldMessengerState mockScaffoldMessenger;
  late MockNavigatorObserver mockObserver;
  late MockNavigatorState mockNavigator;
  
  const testSpecialization = 'Cardiology';
  const testMinFee = 100;
  const testMaxFee = 500;
  
  // Setup test widget with mocked dependencies
  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
      navigatorObservers: [mockObserver],
    );
  }
  
  setUp(() {
    mockContext = MockBuildContext();
    mockScaffoldMessenger = MockScaffoldMessengerState();
    mockObserver = MockNavigatorObserver();
    mockNavigator = MockNavigatorState();
    
    // Setup mock context and navigator
    when(mockContext.mounted).thenReturn(true);
  
    // Setup mock navigator
    when(mockNavigator.canPop()).thenReturn(true);
    when(Navigator.of(mockContext)).thenReturn(mockNavigator);
    
    // Setup mock scaffold messenger
    when(ScaffoldMessenger.of(mockContext)).thenReturn(mockScaffoldMessenger);
    when(mockScaffoldMessenger.showSnackBar(any)).thenAnswer((_) {
      // Create a mock controller that won't be used but satisfies the return type
      final controller = ScaffoldFeatureController<SnackBar, SnackBarClosedReason>._(
        null,
        null,
        (SnackBarClosedReason reason) {},
      );
      return controller;
    });
    
    // Reset mocks
    reset(mockObserver);
  });

  group('AIRedirection', () {
    testWidgets('navigateToDoctor shows loading dialog and handles no doctors found', (WidgetTester tester) async {
      // Arrange
      when(getVerifiedFilteredDoctorList(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      )).thenAnswer((_) async => []);

      // Build our app and trigger a frame.
      await tester.pumpWidget(createWidgetForTesting(
        child: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () async {
                await AIRedirection.navigateToDoctor(
                  context: context,
                  specialization: testSpecialization,
                  minFee: testMinFee,
                  maxFee: testMaxFee,
                );
              },
              child: const Text('Test'),
            );
          },
        ),
      ));

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verify loading dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Finding the best doctor for you...'), findsOneWidget);
      
      // Wait for async operations
      await tester.pumpAndSettle();
      
      // Verify snackbar is shown when no doctors found
      verify(mockScaffoldMessenger.showSnackBar(any)).called(1);
    });

    testWidgets('navigateToDoctor navigates to doctor details when found', (WidgetTester tester) async {
      // Arrange
      final testDoctor = MockDocumentSnapshot<Map<String, dynamic>>();
      when(testDoctor.id).thenReturn('doctor1');
      when(testDoctor.data()).thenReturn({
        'name': 'Dr. Test',
        'specialization': testSpecialization,
        'consultation_fee': 200,
        'rating': 4.5,
        'reviewCount': 100,
      });
      
      when(getVerifiedFilteredDoctorList(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      )).thenAnswer((_) async => [testDoctor]);

      // Build our app and trigger a frame
      await tester.pumpWidget(createWidgetForTesting(
        child: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () async {
                await AIRedirection.navigateToDoctor(
                  context: context,
                  specialization: testSpecialization,
                  minFee: testMinFee,
                  maxFee: testMaxFee,
                );
              },
              child: const Text('Test'),
            );
          },
        ),
      ));

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify navigation to doctor details
      verify(mockObserver.didPush(any, any));
    });

    test('getSelectedDoctor returns null when no doctors found', () async {
      // Arrange
      when(getVerifiedFilteredDoctorList(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      )).thenAnswer((_) async => []);

      // Act
      final result = await AIRedirection.getSelectedDoctor(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      );

      // Assert
      expect(result, isNull);
    });

    test('getSelectedDoctor returns doctor with highest score', () async {
      // Arrange
      final doctor1 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doctor1.id).thenReturn('doc1');
      when(doctor1.data()).thenReturn({
        'specialization': testSpecialization,
        'consultation_fee': 200,
        'rating': 4.5,
        'reviewCount': 100,
      });
      
      final doctor2 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doctor2.id).thenReturn('doc2');
      when(doctor2.data()).thenReturn({
        'specialization': testSpecialization,
        'consultation_fee': 300,
        'rating': 4.8,
        'reviewCount': 150,
      });
      
      when(getVerifiedFilteredDoctorList(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      )).thenAnswer((_) async => [doctor1, doctor2]);

      // Act
      final result = await AIRedirection.getSelectedDoctor(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!['doc'], doctor2); // doctor2 has higher rating and more reviews
      expect(result['score'], greaterThan(0));
    });

    test('getSelectedDoctor returns doctor with highest score', () async {
      // Arrange
      final doctor1 = MockDocumentSnapshot();
      when(doctor1.data()).thenReturn({
        'specialization': testSpecialization,
        'consultationFee': 200,
        'rating': 4.5,
        'reviewCount': 100,
      });
      
      final doctor2 = MockDocumentSnapshot();
      when(doctor2.data()).thenReturn({
        'specialization': testSpecialization,
        'consultationFee': 300,
        'rating': 4.8,
        'reviewCount': 150,
      });
      
      when(getVerifiedFilteredDoctorList(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      )).thenAnswer((_) async => [doctor1, doctor2]);

      // Act
      final result = await AIRedirection.getSelectedDoctor(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!['doc'], doctor2); // doctor2 has higher rating and more reviews
    });
  });

}

// Mock for the doctor list function
@visibleForTesting
Future<List<DocumentSnapshot<Map<String, dynamic>>>> getVerifiedFilteredDoctorList({
  required String specialization,
  int? minFee,
  int? maxFee,
}) async {
  // This will be overridden in tests
  return [];
}
