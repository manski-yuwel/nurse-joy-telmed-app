import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nursejoyapp/features/video_call/data/video_call_service.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';

class VideoCallPage extends StatefulWidget {
  final String chatRoomID;
  final String callerID;
  final String calleeID;
  final bool isInitiator;

  const VideoCallPage(
      {super.key,
      required this.chatRoomID,
      required this.callerID,
      required this.calleeID,
      required this.isInitiator});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final VideoCallService _videoCallService = VideoCallService();
  late RtcEngine _engine;
  late String _channelName;
  late String _token;
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool videoDisabled = false;

  @override
  void initState() {
    super.initState();
    _channelName = _videoCallService.generateChannelName(widget.chatRoomID);
    _token = _videoCallService.generateToken(_channelName);
    _startVideoCall();
  }

  Future<void> _startVideoCall() async {
    await _requestPermissions();
    await _initializeAgoraSDK();
    await _setupLocalVideo();
    setupEventHandlers();
    await _joinChannel();

    if (widget.isInitiator) {
      final auth = Provider.of<AuthService>(context, listen: false);
      await _videoCallService.initiateCall(widget.chatRoomID, auth.user!.uid, widget.calleeID);
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  Future<void> _initializeAgoraSDK() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
        appId: _videoCallService.appID,
        channelProfile: ChannelProfileType.channelProfileCommunication));
  }

  Future<void> _setupLocalVideo() async {
    await _engine.enableVideo();
    await _engine.startPreview();
  }

  void setupEventHandlers() {
    // Register callback handlers
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() {
          _infoStrings.add('Joined Channel: ${connection.channelId}');
        });
      },
      onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        setState(() {
          _infoStrings.add('User Joined: $uid');
          _users.add(uid);
        });
      },
      onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        setState(() {
          _infoStrings.add('User Offline: $uid');
          _users.remove(uid);
        });
      },
    ));
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: _token,
      channelId: _channelName,
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


  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.release();
    _videoCallService.endCall(widget.chatRoomID);
    super.dispose();
  }


  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
