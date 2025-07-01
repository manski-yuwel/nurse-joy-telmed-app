import 'package:flutter_test/flutter_test.dart';
import 'package:nursejoyapp/features/ai/data/ai_redirection.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AIRedirection Performance Tests', () {
    const testSpecialization = 'Cardiology';
    const testMinFee = 100;
    const testMaxFee = 500;

    test('getSelectedDoctor performance with multiple doctors', () async {
      // Create a list of 100 mock doctors
      final mockDoctors = List.generate(100, (index) {
        final doc = MockDocumentSnapshot();
        when(doc.data()).thenReturn({
          'specialization': testSpecialization,
          'consultationFee': 200 + (index % 3) * 50, // Vary fees
          'rating': 4.0 + (index % 5) * 0.2, // Vary ratings
          'reviewCount': 50 + index * 2, // Vary review counts
        });
        return doc;
      });

      // Setup the mock
      when(getVerifiedFilteredDoctorList(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      )).thenAnswer((_) async => mockDoctors);

      // Measure execution time
      final stopwatch = Stopwatch()..start();
      
      final result = await AIRedirection.getSelectedDoctor(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      );
      
      stopwatch.stop();
      
      // Assert
      expect(result, isNotNull);
      
      // Log performance metrics
      print('getSelectedDoctor with 100 doctors took: ${stopwatch.elapsedMilliseconds}ms');
      
      // Performance assertion (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(100), 
          reason: 'getSelectedDoctor should complete in less than 100ms');
    });

    test('navigateToDoctor performance under load', () async {
      // Create a mock context
      final mockContext = MockBuildContext();
      when(mockContext.mounted).thenReturn(true);
      when(mockContext.pop()).thenReturn(null);
      
      // Setup mock doctors
      final mockDoctors = List.generate(50, (index) {
        final doc = MockDocumentSnapshot();
        when(doc.id).thenReturn('doctor$index');
        when(doc.data()).thenReturn({
          'name': 'Dr. Test $index',
          'specialization': testSpecialization,
          'consultationFee': 200 + (index % 3) * 50,
          'rating': 4.0 + (index % 5) * 0.2,
          'reviewCount': 50 + index * 2,
        });
        return doc;
      });

      when(getVerifiedFilteredDoctorList(
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      )).thenAnswer((_) async => mockDoctors);

      // Warm-up run
      await AIRedirection.navigateToDoctor(
        context: mockContext,
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      );

      // Actual test run
      final stopwatch = Stopwatch()..start();
      
      await AIRedirection.navigateToDoctor(
        context: mockContext,
        specialization: testSpecialization,
        minFee: testMinFee,
        maxFee: testMaxFee,
      );
      
      stopwatch.stop();
      
      // Log performance metrics
      print('navigateToDoctor with 50 doctors took: ${stopwatch.elapsedMilliseconds}ms');
      
      // Performance assertion (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(200), 
          reason: 'navigateToDoctor should complete in less than 200ms');
    });
  });
}

// Mock classes
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockBuildContext extends Mock implements BuildContext {}

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
