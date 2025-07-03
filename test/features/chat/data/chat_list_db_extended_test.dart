
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:nursejoyapp/notifications/notification_service.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

class MockLogger extends Mock implements Logger {}
class MockDio extends Mock implements Dio {}
class MockNotificationService extends Mock implements NotificationService {
  @override
  Future<void> registerActivity(
    String userID,
    String title,
    Map<String, dynamic> body,
    String type,
  ) {
    return super.noSuchMethod(
      Invocation.method(
        #registerActivity,
        [userID, title, body, type],
      ),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    ) as Future<void>;
  }
}

void main() {
  group('Chat Extended Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late Chat chat;
    late MockLogger mockLogger;
    late MockDio mockDio;
    late MockNotificationService mockNotificationService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockLogger = MockLogger();
      mockDio = MockDio();
      mockNotificationService = MockNotificationService();
      chat = Chat(
        firestore: fakeFirestore,
        logger: mockLogger,
        dio: mockDio,
        notificationService: mockNotificationService,
      );
    });

    group('searchUsers', () {
      test('should return an empty list when the search term is less than 2 characters', () async {
        final results = await chat.searchUsers('a', 'user1');
        expect(results, isEmpty);
      });

      test('should be case-insensitive', () async {
        await fakeFirestore.collection('users').add({
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'search_index': ['john', 'doe', 'john.doe@example.com'],
        });

        final results = await chat.searchUsers('JOHN', 'user1');
        expect(results, isNotEmpty);
        expect((results.first.data() as Map<String, dynamic>)['name'], 'John Doe');
      });

      test('should return an empty list when no users are found', () async {
        final results = await chat.searchUsers('nonexistent', 'user1');
        expect(results, isEmpty);
      });
    });

    group('generateChatRoom', () {
      test('should not overwrite an existing chat room', () async {
        const chatRoomID = 'user1_user2';
        await fakeFirestore.collection('chats').doc(chatRoomID).set({
          'users': ['user1', 'user2'],
          'last_message': 'Initial message',
        });

        await chat.generateChatRoom(chatRoomID, 'user1', 'user2');

        final doc = await fakeFirestore.collection('chats').doc(chatRoomID).get();
        expect((doc.data() as Map<String, dynamic>)['last_message'], 'Initial message');
      });
    });

    group('sendMessage', () {
      test('should handle empty messages gracefully', () async {
        const chatRoomID = 'user1_user2';
        await fakeFirestore.collection('chats').doc(chatRoomID).set({'users': ['user1', 'user2']});

        await chat.sendMessage(chatRoomID, 'user1', 'John Doe', 'user2', '');

        final chatDoc = await fakeFirestore.collection('chats').doc(chatRoomID).get();
        expect(chatDoc.data()!['last_message'], '');
      });

      test('should correctly set the is_important flag', () async {
        const chatRoomID = 'user1_user2';
        await fakeFirestore.collection('chats').doc(chatRoomID).set({'users': ['user1', 'user2']});

        await chat.sendMessage(chatRoomID, 'user1', 'John Doe', 'user2', 'Important message', isImportant: true);

        final messages = await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').get();
        final messageData = messages.docs.first.data();
        expect(messageData['is_important'], isTrue);

        final chatDoc = await fakeFirestore.collection('chats').doc(chatRoomID).get();
        expect(chatDoc.data()!['last_message_is_important'], isTrue);
      });
    });

    group('updateCallStatus', () {
      test('should not throw an error if the message does not exist', () async {
        const chatRoomID = 'user1_user2';
        const messageID = 'nonexistent_message';

        await chat.updateCallStatus(chatRoomID, messageID, 'answered');
        // No expect needed, the test passes if no exception is thrown.
      });
    });

    test('should handle leading/trailing whitespace in search term', () async {
        await fakeFirestore.collection('users').add({
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'search_index': ['john', 'doe', 'john.doe@example.com'],
        });

        final results = await chat.searchUsers('  john  ', 'user1');
        expect(results, isNotEmpty);
        expect((results.first.data() as Map<String, dynamic>)['name'], 'John Doe');
      });

    group('sendMessage', () {
      test('should handle null senderID gracefully', () async {
        const chatRoomID = 'user1_user2';
        await fakeFirestore.collection('chats').doc(chatRoomID).set({'users': ['user1', 'user2']});

        await chat.sendMessage(chatRoomID, null, 'Unknown Sender', 'user2', 'A message from null');

        final messages = await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').get();
        final messageData = messages.docs.first.data();
        expect(messageData['senderID'], isNull);

        final chatDoc = await fakeFirestore.collection('chats').doc(chatRoomID).get();
        expect(chatDoc.data()!['last_message_senderID'], isNull);
      });
    });

    group('getRecipientDetails', () {
      test('should return a non-existent snapshot for a non-existent user', () async {
        final doc = await chat.getRecipientDetails('non_existent_user');
        expect(doc.exists, isFalse);
      });
    });

    group('migrateMessages', () {
      test('should not overwrite existing is_important flag', () async {
        const chatRoomID = 'user1_user2';
        await fakeFirestore.collection('chats').doc(chatRoomID).set({'users': ['user1', 'user2']});
        await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').add({
          'message_body': 'Hello',
          'is_important': true,
        });

        await chat.migrateMessages();

        final messages = await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').get();
        expect(messages.docs.first.data()['is_important'], isTrue);
      });
    });
  });
}
