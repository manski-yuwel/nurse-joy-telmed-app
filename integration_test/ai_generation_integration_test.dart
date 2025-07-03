import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nursejoyapp/features/ai/data/ai_redirection.dart';
import 'package:nursejoyapp/firebase_options.dart';

void main() {
  // Note: This is an integration test that requires Firebase to be properly set up
  // and the device/emulator to have internet access
  group('AI Generation Integration Tests', () {
    late GenerativeModel model;

    setUpAll(() async {
      // Initialize test bindings
      TestWidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      // Initialize the model
      model = AIRedirection.getGenerativeModel();
    });

    test('should return valid response for health-related query', () async {
      // Arrange
      const testQuery = 'I have a severe headache and sensitivity to light';
      final stopwatch = Stopwatch()..start();
      
      // Act
      try {
        final response = await model.generateContent([
          Content.text(testQuery)
        ]);
        
        // Assert
        final responseText = response.text;
        expect(responseText, isNotNull);
        
        // Print the raw response for debugging
        print('Response time: ${stopwatch.elapsedMilliseconds}ms');
        print('Raw response: $responseText');
        
        // Basic validation of response
        expect(
          responseText!.toLowerCase(),
          anyOf([contains('neurologist'), contains('doctor')]),
        );
        
        // Check response time (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      } catch (e) {
        fail('Failed to get response from AI: $e');
      }
    });

    test('should handle non-health related queries', () async {
      // Arrange
      const testQuery = 'What\'s the weather like today?';
      final stopwatch = Stopwatch()..start();
      
      // Act
      try {
        final response = await model.generateContent([
          Content.text(testQuery)
        ]);
        
        // Assert
        final responseText = response.text;
        expect(responseText, isNotNull);
        
        print('Response time: ${stopwatch.elapsedMilliseconds}ms');
        print('Response: $responseText');
        
        // Should not suggest a specific doctor for non-health queries
        expect(
          responseText!.toLowerCase(),
          isNot(anyOf([
            contains('neurologist'),
            contains('cardiologist'),
            contains('specialist')
          ])),
        );
      } catch (e) {
        fail('Failed to get response from AI: $e');
      }
    });
  });
}
