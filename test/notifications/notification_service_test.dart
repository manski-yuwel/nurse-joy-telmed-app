import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursejoyapp/notifications/notification_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late NotificationService notificationService;
  late FakeFirebaseFirestore fakeFirestore;
  
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    notificationService = NotificationService(firestore: fakeFirestore);
  });
  
  group('NotificationService', () {
    test('registerActivity should add activity to Firestore', () async {
      // Arrange
      const userId = 'test-user-123';
      const title = 'Test Activity';
      final body = {'key': 'value'};
      const type = 'test-type';
      
      // Act
      await notificationService.registerActivity(userId, title, body, type);
      
      // Verify the document was added to the collection
      final collection = fakeFirestore.collection('activity_log');
      final docs = await collection.get();
      expect(docs.docs.length, 1);
      final data = docs.docs.first.data();
      expect(data['userID'], userId);
      expect(data['title'], title);
      expect(data['body'], body);
      expect(data['type'], type);
      expect(data, contains('timestamp'));
    });
    
    test('getActivities should return a stream of user activities', () async {
      // Arrange
      const userId = 'test-user-123';
      
      // Add a test document
      await fakeFirestore.collection('activity_log').add({
        'userID': userId,
        'title': 'Test Activity',
        'body': {'key': 'value'},
        'type': 'test-type',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Act
      final result = notificationService.getActivities(userId);
      
      // Assert
      expect(result, isA<Stream<QuerySnapshot>>());
      
      // Verify the stream contains our test document
      final snapshot = await result.first;
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['userID'], userId);
    });
    
    test('getAllActivities should return a stream of all activities', () async {
      // Arrange
      await fakeFirestore.collection('activity_log').add({
        'userID': 'test-user-1',
        'title': 'Test Activity 1',
        'body': {'key': 'value1'},
        'type': 'test-type',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      await fakeFirestore.collection('activity_log').add({
        'userID': 'test-user-2',
        'title': 'Test Activity 2',
        'body': {'key': 'value2'},
        'type': 'test-type',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Act
      final result = notificationService.getAllActivities();
      
      // Assert
      expect(result, isA<Stream<QuerySnapshot>>());
      
      // Verify the stream contains both test documents
      final snapshot = await result.first;
      expect(snapshot.docs.length, 2);
    });
    
    group('resolveActivityBody', () {
      test('should resolve appointment type correctly', () {
        // Arrange
        const type = 'appointment';
        final body = {
          'appointmentID': 'app123',
          'doctorID': 'doc123',
          'appointmentDateTime': '2023-01-01T12:00:00Z',
          'someOtherField': 'should not be included'
        };
        
        // Act
        final result = notificationService.resolveActivityBody(type, body);
        
        // Assert
        expect(result.length, 3);
        expect(result['appointmentID'], 'app123');
        expect(result['doctorID'], 'doc123');
        expect(result['appointmentDateTime'], '2023-01-01T12:00:00Z');
        expect(result, isNot(contains('someOtherField')));
      });
      
      test('should resolve message type correctly', () {
        // Arrange
        const type = 'message';
        final body = {
          'chatRoomID': 'chat123',
          'senderID': 'user123',
          'recipientID': 'user456',
          'messageBody': 'Hello!',
          'someOtherField': 'should not be included'
        };
        
        // Act
        final result = notificationService.resolveActivityBody(type, body);
        
        // Assert
        expect(result.length, 4);
        expect(result['chatRoomID'], 'chat123');
        expect(result['senderID'], 'user123');
        expect(result['recipientID'], 'user456');
        expect(result['messageBody'], 'Hello!');
        expect(result, isNot(contains('someOtherField')));
      });
      
      test('should return empty map for unknown type', () {
        // Arrange
        const type = 'unknown_type';
        final body = {
          'someField': 'someValue',
          'anotherField': 'anotherValue'
        };
        
        // Act
        final result = notificationService.resolveActivityBody(type, body);
        
        // Assert
        expect(result.isEmpty, isTrue);
      });
    });
  });
}
