import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/constants/app_constants.dart';
import 'socket_service.dart';

// DevArena Live — Native WebRTC Peer-to-Peer Mesh Manager
class WebRTCService {
  final SocketService _socket = SocketService();

  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, MediaStream> _remoteStreams = {};
  final Map<String, List<RTCIceCandidate>> _queuedCandidates = {};

  final _remoteStreamController = StreamController<MapEntry<String, MediaStream>>.broadcast();
  final _peerLeftController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<MapEntry<String, RTCPeerConnectionState>>.broadcast();

  Stream<MapEntry<String, MediaStream>> get onRemoteStream => _remoteStreamController.stream;
  Stream<String> get onPeerLeft => _peerLeftController.stream;
  Stream<MapEntry<String, RTCPeerConnectionState>> get onConnectionState => _connectionStateController.stream;

  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams => _remoteStreams;

  bool _isFrontCamera = true;
  bool get isFrontCamera => _isFrontCamera;

  late final StreamSubscription _offerSub;
  late final StreamSubscription _answerSub;
  late final StreamSubscription _iceSub;
  late final StreamSubscription _peerLeftSub;

  void init() {
    _offerSub = _socket.onSignalOffer.listen(_handleOffer);
    _answerSub = _socket.onSignalAnswer.listen(_handleAnswer);
    _iceSub = _socket.onSignalIceCandidate.listen(_handleIceCandidate);
    _peerLeftSub = _socket.onPeerLeft.listen((data) {
      final peerId = data['id']?.toString();
      if (peerId != null) closePeer(peerId);
    });
  }

  // ── Local Media Stream ────────────────────────────────────────────────────

  Future<MediaStream?> initLocalStream({
    bool video = true,
    bool audio = true,
  }) async {
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': audio,
        'video': video
            ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': _isFrontCamera ? 'user' : 'environment',
                'optional': [],
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      debugPrint('[WebRTC] Local stream initialized: ${_localStream?.id}');
      return _localStream;
    } catch (e) {
      debugPrint('[WebRTC] Error acquiring media: $e');
      return null;
    }
  }

  Future<void> switchCamera() async {
    if (_localStream == null) return;
    final videoTrack = _localStream!.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
      _isFrontCamera = !_isFrontCamera;
    }
  }

  void toggleAudio(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  void toggleVideo(bool enabled) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  // ── Peer Connection Creation ──────────────────────────────────────────────

  Future<RTCPeerConnection> _createPeerConnection(String targetId) async {
    final pc = await createPeerConnection(kWebRTCConfig);

    _peers[targetId] = pc;

    // Add local tracks to peer connection
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    // ICE candidate handler
    pc.onIceCandidate = (candidate) {
      _socket.sendIceCandidate(
        targetId: targetId,
        candidate: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    // Remote stream handler
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        _remoteStreams[targetId] = stream;
        _remoteStreamController.add(MapEntry(targetId, stream));
      }
    };

    // Connection state changes
    pc.onConnectionState = (state) {
      debugPrint('[WebRTC] Peer $targetId state: $state');
      _connectionStateController.add(MapEntry(targetId, state));
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        closePeer(targetId);
      }
    };

    return pc;
  }

  // ── WebRTC Signaling Handlers ─────────────────────────────────────────────

  Future<void> createOffer(String targetId) async {
    try {
      final pc = await _createPeerConnection(targetId);
      final offer = await pc.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      await pc.setLocalDescription(offer);

      _socket.sendOffer(
        targetId: targetId,
        sdp: {'type': offer.type, 'sdp': offer.sdp},
      );
    } catch (e) {
      debugPrint('[WebRTC] Error creating offer: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      final senderId = data['senderId']?.toString();
      final sdpData = data['sdp'] as Map<String, dynamic>?;
      if (senderId == null || sdpData == null) return;

      final pc = await _createPeerConnection(senderId);
      final description = RTCSessionDescription(
        sdpData['sdp']?.toString(),
        sdpData['type']?.toString(),
      );
      await pc.setRemoteDescription(description);

      // Process queued ICE candidates
      if (_queuedCandidates.containsKey(senderId)) {
        for (final candidate in _queuedCandidates[senderId]!) {
          await pc.addCandidate(candidate);
        }
        _queuedCandidates.remove(senderId);
      }

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _socket.sendAnswer(
        targetId: senderId,
        sdp: {'type': answer.type, 'sdp': answer.sdp},
      );
    } catch (e) {
      debugPrint('[WebRTC] Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      final senderId = data['senderId']?.toString();
      final sdpData = data['sdp'] as Map<String, dynamic>?;
      if (senderId == null || sdpData == null) return;

      final pc = _peers[senderId];
      if (pc != null) {
        final description = RTCSessionDescription(
          sdpData['sdp']?.toString(),
          sdpData['type']?.toString(),
        );
        await pc.setRemoteDescription(description);

        if (_queuedCandidates.containsKey(senderId)) {
          for (final candidate in _queuedCandidates[senderId]!) {
            await pc.addCandidate(candidate);
          }
          _queuedCandidates.remove(senderId);
        }
      }
    } catch (e) {
      debugPrint('[WebRTC] Error handling answer: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      final senderId = data['senderId']?.toString();
      final candidateData = data['candidate'] as Map<String, dynamic>?;
      if (senderId == null || candidateData == null) return;

      final candidate = RTCIceCandidate(
        candidateData['candidate']?.toString(),
        candidateData['sdpMid']?.toString(),
        candidateData['sdpMLineIndex'] as int?,
      );

      final pc = _peers[senderId];
      if (pc != null) {
        final remoteDesc = await pc.getRemoteDescription();
        if (remoteDesc != null) {
          await pc.addCandidate(candidate);
        } else {
          _queuedCandidates.putIfAbsent(senderId, () => []).add(candidate);
        }
      } else {
        _queuedCandidates.putIfAbsent(senderId, () => []).add(candidate);
      }
    } catch (e) {
      debugPrint('[WebRTC] Error handling ICE candidate: $e');
    }
  }

  void closePeer(String peerId) {
    _peers[peerId]?.close();
    _peers.remove(peerId);
    _remoteStreams[peerId]?.dispose();
    _remoteStreams.remove(peerId);
    _queuedCandidates.remove(peerId);
    _peerLeftController.add(peerId);
  }

  void dispose() {
    _offerSub.cancel();
    _answerSub.cancel();
    _iceSub.cancel();
    _peerLeftSub.cancel();

    _peers.forEach((_, pc) => pc.close());
    _peers.clear();

    _remoteStreams.forEach((_, s) => s.dispose());
    _remoteStreams.clear();

    _localStream?.dispose();
    _localStream = null;

    _remoteStreamController.close();
    _peerLeftController.close();
    _connectionStateController.close();
  }
}
