import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursejoyapp/features/ai/data/ai_redirection.dart';
import 'package:nursejoyapp/main.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';

// Mock classes
class MockBuildContext extends Mock implements BuildContext {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  String get id => 'doctor1';
  
  @override
  Map<String, dynamic>? data() => {
    'id': 'doctor1',
    'name': 'Dr. Test',
    'specialization': 'Cardiologist',
    'consultation_fee': 1000,
    'is_doctor': true,
    'is_verified': true,
  };
}

// Mock the getVerifiedFilteredDoctorList function
Future<List<DocumentSnapshot<Map<String, dynamic>>>> getVerifiedFilteredDoctorList({
  String? specialization,
  int? minFee,
  int? maxFee,
}) async {
  final mockSnapshot = MockDocumentSnapshot();
  if (specialization == 'NonexistentSpecialty') {
    return [];
  }
  return [mockSnapshot];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  late MockBuildContext mockContext;
  
  setUp(() {
    mockContext = MockBuildContext();
    // Mock the push method with proper argument matchers
    when(() => mockContext.push<dynamic>(
      any(named: 'location'),
      extra: any(named: 'extra'),
    )).thenAnswer((_) async => null);
    
    // Mock the pop method
    when(() => mockContext.pop<dynamic>()).thenReturn(null);
  });

  testWidgets('AI Redirection Integration Test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp(authService: AuthService()));
    await tester.pumpAndSettle();

    // Test 1: Verify initial app state
    expect(find.byType(Scaffold), findsOneWidget);
    
    // Test 2: Test getGenerativeModel returns a valid model
    final model = AIRedirection.getGenerativeModel();
    expect(model, isA<GenerativeModel>());
    
    // Test 3: Test getSelectedDoctor with valid parameters
    final result = await AIRedirection.getSelectedDoctor(
      specialization: 'Cardiologist',
      minFee: 500,
      maxFee: 1500,
    );
    expect(result, isNotNull);
    expect(result!['doc'], isA<DocumentSnapshot>());
    expect(result['score'], greaterThan(0));
    
    // Test 4: Test navigateToDoctor with valid doctor
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AIRedirection.navigateToDoctor(
              context: mockContext,
              specialization: 'Cardiologist',
            ),
            child: const Text('Test Navigation'),
          ),
        ),
      ),
    );
    
    await tester.tap(find.text('Test Navigation'));
    await tester.pumpAndSettle();
    
    // Verify navigation was attempted
    verify(() => mockContext.push(any(), extra: any(named: 'extra'))).called(1);
  });
}
