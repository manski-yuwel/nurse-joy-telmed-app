import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class VideoCallService {
  final logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Agora RTC Engine
  late RtcEngine _engine;
  RtcEngine get engine => _engine;

  bool _isInitialized = false;

  final _users = <int>[];
  final _infoStrings = <String>[];
  bool _muted = false;
  bool _videoDisabled = false;
  Function(List<int>)? onUsersUpdated;
  Function(bool)? onMuteChanged;
  Function(bool)? onVideoDisabledChanged;
  Function(bool)? onInitialized;

  // Agora App ID for using the Agora SDK
  String get appID => dotenv.get('AGORA_APP_ID');

  // Generate channel name using the chat room id
  String generateChannelName(String chatRoomID) {
    return 'nursejoy_$chatRoomID';
  }

  // generate token for the call
  String generateToken(String channelName) {
    // implement token server in next js
    String token = '';
    return token;
  }

  // Get user list
  List<int> get users => _users;

  // Get mute status
  bool get isMuted => _muted;

  // Get video disabled status
  bool get isVideoDisabled => _videoDisabled;

  Future<void> initiateCall(
      String chatRoomID, String callerID, String calleeID) async {
    final channelName = generateChannelName(chatRoomID);
    final token = generateToken(channelName);

    // Create a new video call document
    await _firestore.collection('video_calls').doc(chatRoomID).set({
      'callerID': callerID,
      'calleeID': calleeID,
      'channelName': channelName,
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // Update the chat room with the last message
    await _firestore
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .add({
      'senderID': callerID,
      'recipientID': calleeID,
      'message_body': 'Video call initiated.',
      'message_type': 'video_call',
      'call_status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // End the call
  Future<void> endCall(
      String chatRoomID, String callerID, String calleeID) async {
    await _firestore.collection('video_calls').doc(chatRoomID).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .add({
      'senderID': callerID,
      'recipientID': calleeID,
      'message_body': 'Video call ended.',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Clean up Agora engine if active
    await disposeAgoraEngine();
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

  // --- Agora Engine Methods ---

  // Request permissions for camera and microphone
  Future<void> requestPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  // Initialize the Agora engine
  Future<void> initializeAgoraSDK() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
        appId: appID,
        channelProfile: ChannelProfileType.channelProfileCommunication));
    _isInitialized = true;
    if (onInitialized != null) {
      onInitialized!(_isInitialized);
    }
  }

  // Setup local video
  Future<void> setupLocalVideo() async {
    await _engine.enableVideo();
    await _engine.startPreview();
  }

  // Setup event handlers for the Agora engine
  void setupEventHandlers() {
    // Register callback handlers
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _infoStrings.add('Joined Channel: ${connection.channelId}');
      },
      onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        _infoStrings.add('User Joined: $uid');
        _users.add(uid);
        if (onUsersUpdated != null) {
          onUsersUpdated!(_users);
        }
      },
      onUserOffline:
          (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        _infoStrings.add('User Offline: $uid');
        _users.remove(uid);
        if (onUsersUpdated != null) {
          onUsersUpdated!(_users);
        }
      },
    ));
  }

  // Join the Agora channel
  Future<void> joinChannel(String channelName) async {
    if (!_isInitialized) {
      logger.e("Engine is not initialized. Call initializeAgoraSDK first.");
      return;
    }

    await _engine.joinChannel(
      token: "",
      channelId: channelName,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
    );
  }

  // Toggle mute status
  void toggleMute() {
    _muted = !_muted;
    _engine.muteLocalAudioStream(_muted);
    if (onMuteChanged != null) {
      onMuteChanged!(_muted);
    }
  }

  // Toggle video status
  void toggleVideo() {
    _videoDisabled = !_videoDisabled;
    _engine.muteLocalVideoStream(_videoDisabled);
    if (onVideoDisabledChanged != null) {
      onVideoDisabledChanged!(_videoDisabled);
    }
  }

  // Switch camera
  void switchCamera() {
    _engine.switchCamera();
  }

  // Clean up resources
  Future<void> disposeAgoraEngine() async {
    _users.clear();
    await _engine.leaveChannel();
    await _engine.release();
  }

  // Start a call with all necessary setup
  Future<void> startVideoCall(String chatRoomID,
      {required bool isInitiator,
      required String callerId,
      required String calleeId}) async {
    final channelName = generateChannelName(chatRoomID);

    await requestPermissions();
    await initializeAgoraSDK();
    await setupLocalVideo();
    setupEventHandlers();
    await joinChannel(channelName);

    if (isInitiator) {
      await initiateCall(chatRoomID, callerId, calleeId);
    } else {
      await acceptCall(chatRoomID);
    }
  }
}
