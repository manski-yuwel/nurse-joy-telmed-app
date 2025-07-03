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
    group('registerActivity', () {
      test('should add activity to Firestore with valid data', () async {
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

      test('should handle empty userID, title, body, and type', () async {
        // Arrange
        const userId = '';
        const title = '';
        final body = <String, dynamic>{};
        const type = '';

        // Act
        await notificationService.registerActivity(userId, title, body, type);

        // Verify the document was added to the collection with empty values
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

      test('should handle different data types in body', () async {
        // Arrange
        const userId = 'user-with-mixed-data';
        const title = 'Mixed Data Activity';
        final body = {
          'string_key': 'string_value',
          'int_key': 123,
          'bool_key': true,
          'list_key': [1, 2, 3],
          'map_key': {'nested_key': 'nested_value'},
        };
        const type = 'mixed-type';

        // Act
        await notificationService.registerActivity(userId, title, body, type);

        // Verify the document was added with mixed data types
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
    });
    
    group('getActivities', () {
      test('should return a stream of user activities', () async {
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

      test('should return empty stream when no activities exist for a user', () async {
        // Arrange
        const userId = 'non-existent-user';

        // Act
        final result = notificationService.getActivities(userId);

        // Assert
        final snapshot = await result.first;
        expect(snapshot.docs.length, 0);
      });

      test('should return limited and ordered activities for a user', () async {
        // Arrange
        const userId = 'user-with-many-activities';
        // Add more than 5 activities to test limit and ordering
        await fakeFirestore.collection('activity_log').add({
          'userID': userId, 'title': 'Activity 1', 'body': {}, 'type': 'type', 'timestamp': Timestamp.fromDate(DateTime(2025, 7, 1, 10, 0, 0))
        });
        await fakeFirestore.collection('activity_log').add({
          'userID': userId, 'title': 'Activity 2', 'body': {}, 'type': 'type', 'timestamp': Timestamp.fromDate(DateTime(2025, 7, 1, 11, 0, 0))
        });
        await fakeFirestore.collection('activity_log').add({
          'userID': userId, 'title': 'Activity 3', 'body': {}, 'type': 'type', 'timestamp': Timestamp.fromDate(DateTime(2025, 7, 1, 12, 0, 0))
        });
        await fakeFirestore.collection('activity_log').add({
          'userID': userId, 'title': 'Activity 4', 'body': {}, 'type': 'type', 'timestamp': Timestamp.fromDate(DateTime(2025, 7, 1, 13, 0, 0))
        });
        await fakeFirestore.collection('activity_log').add({
          'userID': userId, 'title': 'Activity 5', 'body': {}, 'type': 'type', 'timestamp': Timestamp.fromDate(DateTime(2025, 7, 1, 14, 0, 0))
        });
        await fakeFirestore.collection('activity_log').add({
          'userID': userId, 'title': 'Activity 6', 'body': {}, 'type': 'type', 'timestamp': Timestamp.fromDate(DateTime(2025, 7, 1, 15, 0, 0))
        }); // This one should be excluded by limit

        // Act
        final result = notificationService.getActivities(userId);

        // Assert
        final snapshot = await result.first;
        expect(snapshot.docs.length, 5); // Should be limited to 5
        expect(snapshot.docs.first['title'], 'Activity 6'); // Newest first
        expect(snapshot.docs[1]['title'], 'Activity 5');
        expect(snapshot.docs[2]['title'], 'Activity 4');
        expect(snapshot.docs[3]['title'], 'Activity 3');
        expect(snapshot.docs[4]['title'], 'Activity 2');
      });

      test('should only return activities for the specified user', () async {
        // Arrange
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        await fakeFirestore.collection('activity_log').add({
          'userID': userId1, 'title': 'User 1 Activity', 'body': {}, 'type': 'type', 'timestamp': FieldValue.serverTimestamp()
        });
        await fakeFirestore.collection('activity_log').add({
          'userID': userId2, 'title': 'User 2 Activity', 'body': {}, 'type': 'type', 'timestamp': FieldValue.serverTimestamp()
        });

        // Act
        final result = notificationService.getActivities(userId1);

        // Assert
        final snapshot = await result.first;
        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first['userID'], userId1);
      });
    });
    
    group('getAllActivities', () {
      test('should return a stream of all activities', () async {
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

      test('should return empty stream when no activities exist', () async {
        // Act
        final result = notificationService.getAllActivities();

        // Assert
        final snapshot = await result.first;
        expect(snapshot.docs.length, 0);
      });

      test('should return activities ordered by timestamp descending', () async {
        // Arrange
        await fakeFirestore.collection('activity_log').add({
          'userID': 'user-a', 'title': 'Old Activity', 'body': {}, 'type': 'type', 'timestamp': Timestamp.fromDate(DateTime(2025, 7, 1, 9, 0, 0))
        });
        await fakeFirestore.collection('activity_log').add({
          'userID': 'user-b', 'title': 'New Activity', 'body': {}, 'type': 'type', 'timestamp': Timestamp.fromDate(DateTime(2025, 7, 1, 10, 0, 0))
        });

        // Act
        final result = notificationService.getAllActivities();

        // Assert
        final snapshot = await result.first;
        expect(snapshot.docs.length, 2);
        expect(snapshot.docs.first['title'], 'New Activity'); // Newest first
        expect(snapshot.docs[1]['title'], 'Old Activity');
      });
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

      test('should handle missing keys for appointment type', () {
        // Arrange
        const type = 'appointment';
        final body = {
          'appointmentID': 'app123',
          // 'doctorID' is missing
          'appointmentDateTime': '2023-01-01T12:00:00Z',
        };
        
        // Act
        final result = notificationService.resolveActivityBody(type, body);
        
        // Assert
        expect(result.length, 3);
        expect(result['appointmentID'], 'app123');
        expect(result['doctorID'], null); // Should be null if missing
        expect(result['appointmentDateTime'], '2023-01-01T12:00:00Z');
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

      test('should handle missing keys for message type', () {
        // Arrange
        const type = 'message';
        final body = {
          'chatRoomID': 'chat123',
          // 'senderID' is missing
          'recipientID': 'user456',
          'messageBody': 'Hello!',
        };
        
        // Act
        final result = notificationService.resolveActivityBody(type, body);
        
        // Assert
        expect(result.length, 4);
        expect(result['chatRoomID'], 'chat123');
        expect(result['senderID'], null); // Should be null if missing
        expect(result['recipientID'], 'user456');
        expect(result['messageBody'], 'Hello!');
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

      test('should return empty map for known type with empty body', () {
        // Arrange
        const type = 'appointment';
        final body = <String, dynamic>{};
        
        // Act
        final result = notificationService.resolveActivityBody(type, body);
        
        // Assert
        expect(result.length, 3);
        expect(result['appointmentID'], null);
        expect(result['doctorID'], null);
        expect(result['appointmentDateTime'], null);
      });
    });
  });
}