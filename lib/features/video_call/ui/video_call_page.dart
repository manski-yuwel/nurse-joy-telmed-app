import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/video_call/data/video_call_service.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:logger/logger.dart';

class VideoCallPage extends StatefulWidget {
  final String chatRoomID;
  final String callerID;
  final String calleeID;
  final bool isInitiator;
  final String? messageId;

  const VideoCallPage(
      {super.key,
      required this.chatRoomID,
      required this.callerID,
      required this.calleeID,
      required this.isInitiator,
      this.messageId});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final VideoCallService _videoCallService = VideoCallService();
  final List<int> _users = [];
  bool _muted = false;
  bool _videoDisabled = false;
  bool _isInitialized = false;
  final logger = Logger();
  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    _startCall();
  }

  void _setupCallbacks() {
    _videoCallService.onUsersUpdated = (users) {
      setState(() {
        _users.clear();
        _users.addAll(users);
      });
    };

    _videoCallService.onMuteChanged = (muted) {
      setState(() {
        _muted = muted;
      });
    };

    _videoCallService.onVideoDisabledChanged = (disabled) {
      setState(() {
        _videoDisabled = disabled;
      });
    };

    _videoCallService.onInitialized = (initialized) {
      setState(() {
        _isInitialized = initialized;
      });
    };
  }

  Future<void> _startCall() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await _videoCallService.startVideoCall(
      widget.chatRoomID,
      isInitiator: widget.isInitiator,
      callerId: widget.isInitiator ? auth.user!.uid : widget.callerID,
      calleeId: widget.calleeID,
    );
  }

  @override
  void dispose() {
    _videoCallService.endCall(
        widget.chatRoomID, widget.callerID, widget.calleeID);
    super.dispose();
  }

  // Create a video view widget for a user
  Widget buildVideoView(int uid) {
    if (!_isInitialized) return const CircularProgressIndicator();

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _videoCallService.engine,
        canvas: uid == 0 ? const VideoCanvas(uid: 0) : VideoCanvas(uid: uid),
      ),
    );
  }

  Widget _buildVideoGrid() {
    final views = <Widget>[];

    // Add local view
    views.add(buildVideoView(0));

    // Add remote views
    for (var uid in _users) {
      views.add(buildVideoView(uid));
    }

    if (views.length == 1) {
      return Container(child: views.first);
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: views.length <= 2 ? 1 : 2,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      ),
      itemCount: views.length,
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
              _videoCallService.toggleMute();
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _muted ? Icons.mic_off : Icons.mic,
              color: _muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              _videoCallService.toggleVideo();
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _videoDisabled ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _videoDisabled ? Icons.videocam_off : Icons.videocam,
              color: _videoDisabled ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              _videoCallService.switchCamera();
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: const Icon(
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
        title: Text(
            'Call with ${widget.isInitiator ? widget.calleeID : widget.callerID}'),
        backgroundColor: const Color(0xFF58f0d7),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Remote video (full screen)
          if (_users.isNotEmpty)
            Positioned.fill(
              child: buildVideoView(_users.first),
            ),
          
          // Local video preview (small window)
          if (_isInitialized)
            Positioned(
              top: 20,
              right: 20,
              width: 120,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: buildVideoView(0), // Local video has uid 0
                ),
              ),
            ),
          
          // Loading indicator
          if (!_isInitialized)
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // Control buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildControlButtons(),
          ),
        ],
      ),
    );
  }
}
