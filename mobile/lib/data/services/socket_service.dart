import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/app_constants.dart';
import '../models/models.dart';

// DevArena Live — Socket.io Service (matching web socketService exactly)
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get socketId => _socket?.id;

  // Stream controllers for socket events
  final _connectController = StreamController<bool>.broadcast();
  final _roomJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _peerJoinedController = StreamController<Participant>.broadcast();
  final _peerLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final _codeChangeController = StreamController<Map<String, dynamic>>.broadcast();
  final _languageChangeController = StreamController<String>.broadcast();
  final _peerTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _executionRunController = StreamController<Map<String, dynamic>>.broadcast();
  final _executionOutputController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageController = StreamController<ChatMessage>.broadcast();
  final _problemChangeController = StreamController<String>.broadcast();
  final _peerStateChangeController = StreamController<Map<String, dynamic>>.broadcast();

  // WebRTC signaling streams
  final _signalOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _signalAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final _signalIceCandidateController = StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<bool> get onConnect => _connectController.stream;
  Stream<Map<String, dynamic>> get onRoomJoined => _roomJoinedController.stream;
  Stream<Participant> get onPeerJoined => _peerJoinedController.stream;
  Stream<Map<String, dynamic>> get onPeerLeft => _peerLeftController.stream;
  Stream<Map<String, dynamic>> get onCodeChange => _codeChangeController.stream;
  Stream<String> get onLanguageChange => _languageChangeController.stream;
  Stream<Map<String, dynamic>> get onPeerTyping => _peerTypingController.stream;
  Stream<Map<String, dynamic>> get onExecutionRun => _executionRunController.stream;
  Stream<Map<String, dynamic>> get onExecutionOutput => _executionOutputController.stream;
  Stream<ChatMessage> get onChatMessage => _chatMessageController.stream;
  Stream<String> get onProblemChange => _problemChangeController.stream;
  Stream<Map<String, dynamic>> get onPeerStateChange => _peerStateChangeController.stream;

  Stream<Map<String, dynamic>> get onSignalOffer => _signalOfferController.stream;
  Stream<Map<String, dynamic>> get onSignalAnswer => _signalAnswerController.stream;
  Stream<Map<String, dynamic>> get onSignalIceCandidate => _signalIceCandidateController.stream;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      kServerUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setTimeout(15000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected: ${_socket?.id}');
      _isConnected = true;
      _connectController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected');
      _isConnected = false;
      _connectController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Error: $err');
      _isConnected = false;
      _connectController.add(false);
    });

    // ── Room Events ──────────────────────────────────────────────────────────
    _socket!.on('room-joined', (data) {
      debugPrint('[Socket] Room joined: $data');
      if (data is Map) {
        _roomJoinedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('peer-joined', (data) {
      debugPrint('[Socket] Peer joined: $data');
      if (data is Map) {
        _peerJoinedController.add(Participant.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    _socket!.on('peer-left', (data) {
      debugPrint('[Socket] Peer left: $data');
      if (data is Map) {
        _peerLeftController.add(Map<String, dynamic>.from(data));
      }
    });

    // ── Code / Editor Events ─────────────────────────────────────────────────
    _socket!.on('code-changed', (data) {
      if (data is Map) {
        _codeChangeController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('language-changed', (data) {
      final lang = data is Map ? data['language']?.toString() : data?.toString();
      if (lang != null) _languageChangeController.add(lang);
    });

    _socket!.on('peer-typing', (data) {
      if (data is Map) {
        _peerTypingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('code-executed', (data) {
      if (data is Map) {
        _executionRunController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('execution-output', (data) {
      if (data is Map) {
        _executionOutputController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('problem-changed', (data) {
      final prob = data is Map ? data['problem']?.toString() : data?.toString();
      if (prob != null) _problemChangeController.add(prob);
    });

    // ── Chat ────────────────────────────────────────────────────────────────
    _socket!.on('chat-message', (data) {
      if (data is Map) {
        _chatMessageController.add(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    // ── AV / Media State Sync ────────────────────────────────────────────────
    _socket!.on('peer-state-changed', (data) {
      if (data is Map) {
        _peerStateChangeController.add(Map<String, dynamic>.from(data));
      }
    });

    // ── WebRTC Signaling ─────────────────────────────────────────────────────
    _socket!.on('signal-offer', (data) {
      if (data is Map) _signalOfferController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('signal-answer', (data) {
      if (data is Map) _signalAnswerController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('signal-ice-candidate', (data) {
      if (data is Map) _signalIceCandidateController.add(Map<String, dynamic>.from(data));
    });
  }

  // ── Emit Actions ──────────────────────────────────────────────────────────

  void joinRoom({
    required String roomId,
    required String name,
    required String role,
    required String title,
    bool isMuted = false,
    bool isCamOff = false,
  }) {
    _socket?.emit('join-room', {
      'roomId': roomId,
      'name': name,
      'role': role,
      'title': title,
      'isMuted': isMuted,
      'isCamOff': isCamOff,
    });
  }

  void sendCodeChange({
    required String roomId,
    required String code,
    required String language,
  }) {
    _socket?.emit('code-change', {
      'roomId': roomId,
      'code': code,
      'language': language,
    });
  }

  void sendLanguageChange({
    required String roomId,
    required String language,
  }) {
    _socket?.emit('language-change', {
      'roomId': roomId,
      'language': language,
    });
  }

  void sendTyping({
    required String roomId,
    required String name,
    required bool isTyping,
  }) {
    _socket?.emit('typing', {
      'roomId': roomId,
      'name': name,
      'isTyping': isTyping,
    });
  }

  void sendExecutionRun({
    required String roomId,
    required String language,
  }) {
    _socket?.emit('run-code', {
      'roomId': roomId,
      'language': language,
    });
  }

  void sendExecutionOutput({
    required String roomId,
    required Map<String, dynamic> output,
  }) {
    _socket?.emit('execution-output', {
      'roomId': roomId,
      'output': output,
    });
  }

  void sendChatMessage({
    required String roomId,
    required String text,
    required String senderName,
  }) {
    _socket?.emit('chat-message', {
      'roomId': roomId,
      'text': text,
      'senderName': senderName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void sendProblemChange({
    required String roomId,
    required String problem,
  }) {
    _socket?.emit('problem-change', {
      'roomId': roomId,
      'problem': problem,
    });
  }

  void sendMediaState({
    required String roomId,
    required bool isMuted,
    required bool isCamOff,
    required bool isScreenSharing,
  }) {
    _socket?.emit('peer-state-change', {
      'roomId': roomId,
      'isMuted': isMuted,
      'isCamOff': isCamOff,
      'isScreenSharing': isScreenSharing,
    });
  }

  // ── WebRTC Signaling Emitters ─────────────────────────────────────────────

  void sendOffer({
    required String targetId,
    required Map<String, dynamic> sdp,
  }) {
    _socket?.emit('signal-offer', {
      'targetId': targetId,
      'sdp': sdp,
    });
  }

  void sendAnswer({
    required String targetId,
    required Map<String, dynamic> sdp,
  }) {
    _socket?.emit('signal-answer', {
      'targetId': targetId,
      'sdp': sdp,
    });
  }

  void sendIceCandidate({
    required String targetId,
    required Map<String, dynamic> candidate,
  }) {
    _socket?.emit('signal-ice-candidate', {
      'targetId': targetId,
      'candidate': candidate,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }
}
