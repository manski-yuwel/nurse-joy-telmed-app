import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nursejoyapp/features/ai/data/ai_redirection.dart';
import 'dart:convert';
import 'package:nursejoyapp/firebase_options.dart';

// Helper function to extract JSON from response
Map<String, dynamic>? _extractJsonFromResponse(GenerateContentResponse response) {
  try {
    final text = response.text;
    if (text == null) return null;
    
    // Try to find JSON in the response
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) return null;
    
    final jsonStr = text.substring(jsonStart, jsonEnd + 1);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  } catch (e) {
    print('Error parsing response: $e');
    return null;
  }
}

void main() {
  late GenerativeModel model;
  
  setUpAll(() async {
    // Initialize test bindings
    TestWidgetsFlutterBinding.ensureInitialized();
    
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Initialize the actual model
    model = AIRedirection.getGenerativeModel();
  });

  group('AI Generation Tests', () {
    test('should return valid response for health-related query', () async {
      // Arrange
      const testQuery = 'I have a severe headache and sensitivity to light';
      final stopwatch = Stopwatch()..start();
      
      // Act
      final response = await model.generateContent([
        Content.text(testQuery)
      ]);
      
      // Assert
      final responseData = _extractJsonFromResponse(response);
      
      expect(responseData, isNotNull);
      expect(responseData!['specialization'], isNotNull);
      expect(responseData['response'], isNotNull);
      
      // Log performance
      print('Response time: ${stopwatch.elapsedMilliseconds}ms');
      print('Full response: ${response.text}');
      print('Specialization: ${responseData['specialization']}');
      print('Response: ${responseData['response']}');
      
      // Check response time (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('should handle non-health related queries', () async {
      // Arrange
      const testQuery = 'What\'s the weather like today?';
      final stopwatch = Stopwatch()..start();
      
      // Act
      final response = await model.generateContent([
        Content.text(testQuery)
      ]);
      
      // Assert
      final responseData = _extractJsonFromResponse(response);
      
      expect(responseData, isNotNull);
      
      // For non-health queries, specialization should be empty or 'All Specializations'
      expect(
        responseData!['specialization'],
        anyOf(['', 'All Specializations', null]),
      );
      
      print('Response time: ${stopwatch.elapsedMilliseconds}ms');
      print('Full response: ${response.text}');
      print('Specialization: ${responseData['specialization']}');
      print('Response: ${responseData['response']}');
    });

    test('should handle multiple symptoms', () async {
      // Arrange
      const testQuery = 'I have stomach pain, nausea, and heartburn';
      final stopwatch = Stopwatch()..start();
      
      // Act
      final response = await model.generateContent([
        Content.text(testQuery)
      ]);
      
      // Assert
      final responseData = _extractJsonFromResponse(response);
      
      expect(responseData, isNotNull);
      expect(responseData!['specialization'], isNotNull);
      
      print('Response time: ${stopwatch.elapsedMilliseconds}ms');
      print('Full response: ${response.text}');
      print('Specialization: ${responseData['specialization']}');
    });

    test('should respond within acceptable time limit', () async {
      // Arrange
      const testQuery = 'I have a persistent cough and fever';
      final stopwatch = Stopwatch()..start();
      
      // Act
      await model.generateContent([Content.text(testQuery)]);
      final responseTime = stopwatch.elapsedMilliseconds;
      
      // Assert
      print('Response time: ${responseTime}ms');
      expect(responseTime, lessThan(5000)); // 5 seconds timeout
    });
  });
}
