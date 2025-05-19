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
      await _videoCallService.initiateCall(
          widget.chatRoomID, auth.user!.uid, widget.calleeID);
    } else {
      await _videoCallService.acceptCall(widget.chatRoomID);
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
      onUserOffline:
          (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        setState(() {
          _infoStrings.add('User Offline: $uid');
          _users.remove(uid);
        });
      },
    ));
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: "",
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
    _videoCallService.endCall(widget.chatRoomID, widget.callerID, widget.calleeID);
    super.dispose();
  }

  Widget _buildVideoView(int uid) {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: uid == 0 ? const VideoCanvas(uid: 0) : VideoCanvas(uid: uid),
      ),
    );
  }

  Widget _buildVideoGrid() {
    final views = <Widget>[];

    views.add(_buildVideoView(0));
    for (var uid in _users) {
      views.add(_buildVideoView(uid));
    }

    if (views.length == 1) {
      return Container(
        child: views.first,
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: views.length <= 2 ? 1 : 2,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      ),
      itemBuilder: (context, index) => views[index],
    );
  }

  Widget _buildControlButtons() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: () {
              setState(() {
                muted = !muted;
              });
              _engine.muteLocalAudioStream(muted);
            },
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              setState(() {
                videoDisabled = !videoDisabled;
              });
              _engine.muteLocalVideoStream(videoDisabled);
            },
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: videoDisabled ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              videoDisabled ? Icons.videocam_off : Icons.videocam,
              color: videoDisabled ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              _engine.switchCamera();
            },
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call with ${widget.isInitiator ? widget.calleeID : widget.callerID}'),
        backgroundColor: const Color(0xFF58f0d7),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            _buildVideoGrid(),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }
}

