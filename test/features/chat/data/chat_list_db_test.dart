
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
  group('Chat', () {
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

    test('getChatList returns a stream of chat lists', () async {
      const userID = 'user1';
      await fakeFirestore.collection('chats').add({
        'users': [userID, 'user2'],
        'last_message': 'Hello',
        'timestamp': DateTime.now(),
      });

      final stream = chat.getChatList(userID);
      final snapshot = await stream.first;

      expect(snapshot.docs.length, 1);
      expect((snapshot.docs.first.data() as Map<String, dynamic>)['users'], contains(userID));
    });

    test('getOnlineUsers returns a stream of online users', () async {
      await fakeFirestore.collection('users').add({'name': 'John Doe', 'online': true});
      await fakeFirestore.collection('users').add({'name': 'Jane Doe', 'online': false});

      final stream = chat.getOnlineUsers();
      final snapshot = await stream.first;

      expect(snapshot.docs.length, 2);
    });

    test('searchUsers returns a list of users', () async {
      await fakeFirestore.collection('users').add({
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'search_index': ['john', 'doe', 'john.doe@example.com'],
      });

      final results = await chat.searchUsers('john', 'user1');

      expect(results.length, 1);
      expect((results.first.data() as Map<String, dynamic>)['name'], 'John Doe');
    });

    test('generateChatRoom creates a new chat room', () async {
      const chatRoomID = 'user1_user2';
      await chat.generateChatRoom(chatRoomID, 'user1', 'user2');

      final doc = await fakeFirestore.collection('chats').doc(chatRoomID).get();
      expect(doc.exists, isTrue);
    });

    test('generateChatRoomID generates a consistent chat room ID', () {
      final chatRoomID1 = chat.generateChatRoomID('user1', 'user2');
      final chatRoomID2 = chat.generateChatRoomID('user2', 'user1');

      expect(chatRoomID1, 'user1_user2');
      expect(chatRoomID1, chatRoomID2);
    });

    test('getRecipientDetails returns the correct user details', () async {
      const userID = 'user1';
      await fakeFirestore.collection('users').doc(userID).set({'name': 'John Doe'});

      final doc = await chat.getRecipientDetails(userID);

      expect(doc.exists, isTrue);
      expect((doc.data() as Map<String, dynamic>)['name'], 'John Doe');
    });

    test('getChatRoomMessages returns a stream of messages', () async {
      const chatRoomID = 'user1_user2';
      await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').add({
        'message_body': 'Hello',
        'timestamp': DateTime.now(),
      });

      final stream = chat.getChatRoomMessages(chatRoomID);
      final snapshot = await stream.first;

      expect(snapshot.docs.length, 1);
      expect((snapshot.docs.first.data() as Map<String, dynamic>)['message_body'], 'Hello');
    });

    test('sendMessage adds a new message to the chat room', () async {
      const chatRoomID = 'user1_user2';
      await fakeFirestore.collection('chats').doc(chatRoomID).set({'users': ['user1', 'user2']});

      // Setup mock with actual data
      final expectedBody = {
        'chatRoomID': chatRoomID,
        'senderID': 'user1',
        'recipientID': 'user2',
        'messageBody': 'Hello',
      };
      
      when(mockNotificationService.registerActivity(
        'user2',
        'John Doe has sent you a message',
        expectedBody,
        'message',
      )).thenAnswer((_) => Future.value());

      await chat.sendMessage(chatRoomID, 'user1', 'John Doe', 'user2', 'Hello');

      // Verify the message was added
      final chatDoc = await fakeFirestore.collection('chats').doc(chatRoomID).get();
      expect(chatDoc.data()!['last_message'], 'Hello');
      
      // Verify registerActivity was called with correct parameters
      verify(mockNotificationService.registerActivity(
        'user2',
        'John Doe has sent you a message',
        expectedBody,
        'message',
      )).called(1);
    });

    test('sendCallNotification sends a call notification', () async {
      const chatRoomID = 'user1_user2';
      await fakeFirestore.collection('chats').doc(chatRoomID).set({'users': ['user1', 'user2']});

      final docRef = await chat.sendCallNotification(chatRoomID, 'user1', 'user2', 'video');

      final message = await docRef.get();
      expect(message.exists, isTrue);
      expect((message.data() as Map<String, dynamic>)['message_type'], 'video_call');
    });

    test('updateCallStatus updates the call status of a message', () async {
      const chatRoomID = 'user1_user2';
      const messageID = 'message1';
      await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').doc(messageID).set({
        'call_status': 'pending',
      });

      await chat.updateCallStatus(chatRoomID, messageID, 'answered');

      final message = await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').doc(messageID).get();
      expect((message.data() as Map<String, dynamic>)['call_status'], 'answered');
    });

    test('migrateMessages migrates messages correctly', () async {
      const chatRoomID = 'user1_user2';
      await fakeFirestore.collection('chats').doc(chatRoomID).set({'users': ['user1', 'user2']});
      await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').add({
        'message_body': 'Hello',
      });

      await chat.migrateMessages();

      final messages = await fakeFirestore.collection('chats').doc(chatRoomID).collection('messages').get();
      expect(messages.docs.first.data()['is_important'], false);
    });
  });
}
