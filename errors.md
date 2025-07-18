name RtcEngine_enableVideo result 0 outdata {"result":0}
I/spdlog  (23948): [2025-07-18 12:19:03.864][28125][I][iris_rtc_api_engine.cc:438] api name RtcEngine_startPreview_4fd718e params "{"sourceType":0}"
I/spdlog  (23948): [2025-07-18 12:19:03.882][28125][I][iris_rtc_api_engine.cc:504] api name RtcEngine_startPreview_4fd718e result 0 outdata {"result":0}
I/PlatformViewsController(23948): Hosting view in view hierarchy for platform view: 1
I/PlatformViewsController(23948): PlatformView is using SurfaceProducer backend
D/NativeCustomFrequencyManager(23948): [NativeCFMS] BpCustomFrequencyManager::BpCustomFrequencyManager()
D/OpenGLRenderer(23948): eglCreateWindowSurface
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
D/OpenGLRenderer(23948): CFMS:: SetUp Pid : 23948    Tid : 24062
W/Parcel  (23948): Expecting binder but got null!
I/spdlog  (23948): [2025-07-18 12:19:03.916][28125][I][iris_rtc_api_engine.cc:436] api name RtcEngine_joinChannel_cdbb747 params "{"token":"","channelId":"nursejoy_DWTj6XqLHVYdWAxNSJmNBx5YCdJ3_PaBvgts4pKS2m4aehJocZApBjXT2","uid":0,"options":{"publishCameraTrack":true,"publishMicrophoneTrack":true,"autoSubscribeAudio":true,"autoSubscribeVideo":true,"clientRoleType":1}}"
I/spdlog  (23948): [2025-07-18 12:19:03.916][28125][I][iris_rtc_api_engine.cc:504] api name RtcEngine_joinChannel_cdbb747 result 0 outdata {"result":-102}
I/flutter (23948): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23948): │ #0   VideoCallService.startVideoCall (package:nursejoyapp/features/video_call/data/video_call_service.dart:267:14)
I/flutter (23948): │ #1   <asynchronous suspension>
I/flutter (23948): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23948): │ ⛔ Error starting video call: AgoraRtcException(-102, null)
I/flutter (23948): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
E/flutter (23948): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: AgoraRtcException(-102, null)
E/flutter (23948): #0      RtcEngineImpl.joinChannel (package:agora_rtc_engine/src/binding/agora_rtc_engine_impl.dart:352:7)
E/flutter (23948): <asynchronous suspension>
E/flutter (23948): #1      VideoCallService.joinChannel (package:nursejoyapp/features/video_call/data/video_call_service.dart:194:5)
E/flutter (23948): <asynchronous suspension>
E/flutter (23948): #2      VideoCallService.startVideoCall (package:nursejoyapp/features/video_call/data/video_call_service.dart:259:7)
E/flutter (23948): <asynchronous suspension>
E/flutter (23948): #3      _VideoCallPageState._startCall (package:nursejoyapp/features/video_call/ui/video_call_page.dart:72:5)
E/flutter (23948): <asynchronous suspension>
E/flutter (23948):
D/NativeCustomFrequencyManager(23948): [NativeCFMS] BpCustomFrequencyManager::BpCustomFrequencyManager()
D/OpenGLRenderer(23948): eglCreateWindowSurface
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
D/OpenGLRenderer(23948): CFMS:: SetUp Pid : 23948    Tid : 24062
W/Parcel  (23948): Expecting binder but got null!
I/spdlog  (23948): [2025-07-18 12:19:03.933][28125][I][iris_rtc_api_engine.cc:438] api name RtcEngine_setupLocalVideo_acc9c38 params "{"canvas":{"uid":0,"view":14198}}"
I/spdlog  (23948): [2025-07-18 12:19:03.934][28125][I][iris_rtc_api_engine.cc:504] api name RtcEngine_setupLocalVideo_acc9c38 result 0 outdata {"result":0}
E/ple.nursejoyapp(23948): No package ID ff found for ID 0xffffffff.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
D/OpenGLRenderer(23948): setSurface called with nullptr
D/OpenGLRenderer(23948): setSurface() destroyed EGLSurface
D/OpenGLRenderer(23948): destroyEglSurface
I/CameraManagerGlobal(23948): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_OPEN for client com.example.nursejoyapp API Level 2User Id 0
I/CameraManager(23948): registerAvailabilityCallback: Is device callback = false
I/CameraManagerGlobal(23948): postSingleUpdate device: camera id 0 status STATUS_PRESENT
I/CameraManagerGlobal(23948): postSingleUpdate device: camera id 1 status STATUS_NOT_AVAILABLE
I/CameraManagerGlobal(23948): postSingleUpdate device: camera id 2 status STATUS_PRESENT
I/CameraManagerGlobal(23948): postSingleUpdate device: camera id 3 status STATUS_PRESENT
I/CameraManagerGlobal(23948): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_ACTIVE for client com.example.nursejoyapp API Level 2User Id 0
D/CommonUtility(23948): VideoCaptureCamera getDisplayRotation: 0
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.
E/FrameEvents(23948): updateAcquireFence: Did not find frame.