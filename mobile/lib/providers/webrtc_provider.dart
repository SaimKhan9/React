import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../data/services/webrtc_service.dart';
import '../../data/services/socket_service.dart';

// DevArena Live — WebRTC Media & Calling Provider
class WebRTCProvider extends ChangeNotifier {
  final WebRTCService _webrtcService = WebRTCService();
  final SocketService _socket = SocketService();

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  bool _isInitialized = false;
  bool _isLocalMuted = false;
  bool _isLocalCamOff = false;
  bool _isFrontCamera = true;
  String? _roomId;

  // Speaking indicator (simulated RMS from audio track or timer fluctuation)
  bool _isSpeaking = false;
  Timer? _speakingTimer;

  // Getters
  RTCVideoRenderer get localRenderer => _localRenderer;
  Map<String, RTCVideoRenderer> get remoteRenderers => _remoteRenderers;
  bool get isInitialized => _isInitialized;
  bool get isLocalMuted => _isLocalMuted;
  bool get isLocalCamOff => _isLocalCamOff;
  bool get isFrontCamera => _isFrontCamera;
  bool get isSpeaking => _isSpeaking;

  late final StreamSubscription _remoteStreamSub;
  late final StreamSubscription _peerJoinedSub;
  late final StreamSubscription _peerLeftSub;

  WebRTCProvider() {
    _initListeners();
  }

  void _initListeners() {
    _remoteStreamSub = _webrtcService.onRemoteStream.listen((entry) async {
      final peerId = entry.key;
      final stream = entry.value;

      if (!_remoteRenderers.containsKey(peerId)) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = stream;
        _remoteRenderers[peerId] = renderer;
        notifyListeners();
      } else {
        _remoteRenderers[peerId]!.srcObject = stream;
        notifyListeners();
      }
    });

    _peerJoinedSub = _socket.onPeerJoined.listen((peer) {
      // When a new peer joins, establish WebRTC offer if we're already in the room
      if (_roomId != null && peer.id != _socket.socketId) {
        _webrtcService.createOffer(peer.id);
      }
    });

    _peerLeftSub = _webrtcService.onPeerLeft.listen((peerId) {
      if (_remoteRenderers.containsKey(peerId)) {
        _remoteRenderers[peerId]!.srcObject = null;
        _remoteRenderers[peerId]!.dispose();
        _remoteRenderers.remove(peerId);
        notifyListeners();
      }
    });
  }

  Future<void> initialize({
    required String roomId,
    bool isMuted = false,
    bool isCamOff = false,
  }) async {
    _roomId = roomId;
    _isLocalMuted = isMuted;
    _isLocalCamOff = isCamOff;

    await _localRenderer.initialize();
    _webrtcService.init();

    final stream = await _webrtcService.initLocalStream(
      video: !isCamOff,
      audio: !isMuted,
    );

    if (stream != null) {
      _localRenderer.srcObject = stream;
      _isInitialized = true;
      _startSpeakingSimulation();
      notifyListeners();
    }
  }

  void _startSpeakingSimulation() {
    // Pulse speaking ring subtly when mic is unmuted
    _speakingTimer?.cancel();
    _speakingTimer = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      if (!_isLocalMuted && _isInitialized) {
        _isSpeaking = (t.tick % 3 != 0);
        notifyListeners();
      } else {
        if (_isSpeaking) {
          _isSpeaking = false;
          notifyListeners();
        }
      }
    });
  }

  void toggleMic() {
    _isLocalMuted = !_isLocalMuted;
    _webrtcService.toggleAudio(!_isLocalMuted);
    notifyListeners();
  }

  void toggleCam() {
    _isLocalCamOff = !_isLocalCamOff;
    _webrtcService.toggleVideo(!_isLocalCamOff);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _webrtcService.switchCamera();
    _isFrontCamera = _webrtcService.isFrontCamera;
    notifyListeners();
  }

  Future<void> hangUp() async {
    _speakingTimer?.cancel();
    _localRenderer.srcObject = null;
    await _localRenderer.dispose();
    _localRenderer = RTCVideoRenderer();

    for (final r in _remoteRenderers.values) {
      r.srcObject = null;
      await r.dispose();
    }
    _remoteRenderers.clear();

    _webrtcService.dispose();
    _isInitialized = false;
    _roomId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _remoteStreamSub.cancel();
    _peerJoinedSub.cancel();
    _peerLeftSub.cancel();
    _speakingTimer?.cancel();
    _localRenderer.dispose();
    for (final r in _remoteRenderers.values) {
      r.dispose();
    }
    _webrtcService.dispose();
    super.dispose();
  }
}
