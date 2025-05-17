import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class VideoCallService {
  final logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String appID = 'AGORA_APP_ID';
  final String token = 'AGORA_TOKEN';

  // Generae channel name using the chat room id
  String generateChannelName(String chatRoomID) {
    return 'nursejoy_$chatRoomID';
  }

  Future<String> generateToken(String channelName) async {
    // implement token server in next js
    String token = '';
    return token;
  }

  Future<void> initiateCall(
      String chatRoomID, String callerID, String calleeID) async {
    final channelName = generateChannelName(chatRoomID);
    final token = await generateToken(channelName);

    // Create a new video call document
    await _firestore.collection('video_calls').doc(chatRoomID).update({
      'callerID': callerID,
      'calleeID': calleeID,
      'channelName': channelName,
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // Update the chat room with the last message
    await _firestore.collection('chats').doc(chatRoomID).update({
      'lastMessage': 'Video call initiated.',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // End the call
  Future<void> endCall(String chatRoomID) async {
    await _firestore.collection('video_calls').doc(chatRoomID).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // Accept the call
  Future<void> acceptCall(String chatRoomID) async {
    await _firestore.collection('video_calls').doc(chatRoomID).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reject the call
  Future<void> rejectCall(String chatRoomID) async {
    await _firestore.collection('video_calls').doc(chatRoomID).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // get call information
  Stream<DocumentSnapshot> getCall(String chatRoomID) {
    return _firestore.collection('video_calls').doc(chatRoomID).snapshots();
  }
    
}
