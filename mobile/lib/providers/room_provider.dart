import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../../data/services/socket_service.dart';

// DevArena Live — Room & Real-Time Session Provider
class RoomProvider extends ChangeNotifier {
  final SocketService _socket = SocketService();

  bool _isInRoom = false;
  String _roomId = '';
  String _myName = '';
  String _myRole = 'interviewer';
  String _interviewTitle = '';
  String _problem = 'Write a function to check if a string is a palindrome. Handle empty strings and make sure comparison is case-insensitive, ignoring whitespace.';

  // Stopwatch timer
  int _sessionSeconds = 0;
  Timer? _sessionTimer;

  // Remote participants: id -> Participant
  final Map<String, Participant> _participants = {};

  // Chat messages
  final List<ChatMessage> _messages = [];

  // Peer typing indicator
  String? _peerTypingName;
  Timer? _typingTimer;

  // Local media controls
  bool _isMuted = false;
  bool _isCamOff = false;
  bool _isScreenSharing = false;

  // Getters
  bool get isInRoom => _isInRoom;
  String get roomId => _roomId;
  String get myName => _myName;
  String get myRole => _myRole;
  String get interviewTitle => _interviewTitle;
  String get problem => _problem;
  int get sessionSeconds => _sessionSeconds;
  String? get peerTypingName => _peerTypingName;

  bool get isMuted => _isMuted;
  bool get isCamOff => _isCamOff;
  bool get isScreenSharing => _isScreenSharing;

  List<Participant> get remoteParticipants => _participants.values.toList();
  int get totalParticipants => _participants.length + 1; // +1 for self
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool get isInterviewer => _myRole == 'interviewer';
  bool get isCandidate => _myRole == 'candidate';

  late final StreamSubscription _connectSub;
  late final StreamSubscription _roomJoinedSub;
  late final StreamSubscription _peerJoinedSub;
  late final StreamSubscription _peerLeftSub;
  late final StreamSubscription _peerTypingSub;
  late final StreamSubscription _chatSub;
  late final StreamSubscription _problemSub;
  late final StreamSubscription _peerStateSub;

  RoomProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socket.connect();

    _roomJoinedSub = _socket.onRoomJoined.listen((data) {
      _isInRoom = true;
      if (data['title'] != null) _interviewTitle = data['title'].toString();
      if (data['problem'] != null) _problem = data['problem'].toString();

      // Populate existing participants
      if (data['participants'] is List) {
        for (final p in (data['participants'] as List)) {
          if (p is Map) {
            final part = Participant.fromJson(Map<String, dynamic>.from(p));
            if (part.id != _socket.socketId) {
              _participants[part.id] = part;
            }
          }
        }
      }

      _startTimer();
      notifyListeners();
    });

    _peerJoinedSub = _socket.onPeerJoined.listen((peer) {
      if (peer.id != _socket.socketId) {
        _participants[peer.id] = peer;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          senderName: 'System',
          text: '${peer.name} (${peer.role}) joined the interview',
          timestamp: DateTime.now(),
          isSystem: true,
        ));
        notifyListeners();
      }
    });

    _peerLeftSub = _socket.onPeerLeft.listen((data) {
      final id = data['id']?.toString();
      final name = data['name']?.toString() ?? 'A participant';
      if (id != null) {
        _participants.remove(id);
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          senderName: 'System',
          text: '$name left the interview',
          timestamp: DateTime.now(),
          isSystem: true,
        ));
        notifyListeners();
      }
    });

    _peerTypingSub = _socket.onPeerTyping.listen((data) {
      final name = data['name']?.toString();
      final isTyping = data['isTyping'] as bool? ?? false;
      if (isTyping && name != null) {
        _peerTypingName = name;
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          _peerTypingName = null;
          notifyListeners();
        });
      } else {
        _peerTypingName = null;
      }
      notifyListeners();
    });

    _chatSub = _socket.onChatMessage.listen((msg) {
      _messages.add(msg);
      notifyListeners();
    });

    _problemSub = _socket.onProblemChange.listen((prob) {
      _problem = prob;
      notifyListeners();
    });

    _peerStateSub = _socket.onPeerStateChange.listen((data) {
      final peerId = data['peerId']?.toString();
      if (peerId != null && _participants.containsKey(peerId)) {
        final p = _participants[peerId]!;
        if (data.containsKey('isMuted')) p.isMuted = data['isMuted'] as bool;
        if (data.containsKey('isCamOff')) p.isCamOff = data['isCamOff'] as bool;
        if (data.containsKey('isScreenSharing')) p.isScreenSharing = data['isScreenSharing'] as bool;
        notifyListeners();
      }
    });
  }

  void joinRoom({
    required String roomId,
    required String name,
    required String role,
    required String title,
    bool isMuted = false,
    bool isCamOff = false,
  }) {
    _roomId = roomId;
    _myName = name;
    _myRole = role;
    _interviewTitle = title;
    _isMuted = isMuted;
    _isCamOff = isCamOff;

    _socket.joinRoom(
      roomId: roomId,
      name: name,
      role: role,
      title: title,
      isMuted: isMuted,
      isCamOff: isCamOff,
    );
  }

  void updateProblem(String newProblem) {
    _problem = newProblem;
    _socket.sendProblemChange(roomId: _roomId, problem: newProblem);
    notifyListeners();
  }

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    _socket.sendChatMessage(
      roomId: _roomId,
      text: text.trim(),
      senderName: _myName,
    );
  }

  void toggleMic() {
    _isMuted = !_isMuted;
    _socket.sendMediaState(
      roomId: _roomId,
      isMuted: _isMuted,
      isCamOff: _isCamOff,
      isScreenSharing: _isScreenSharing,
    );
    notifyListeners();
  }

  void toggleCam() {
    _isCamOff = !_isCamOff;
    _socket.sendMediaState(
      roomId: _roomId,
      isMuted: _isMuted,
      isCamOff: _isCamOff,
      isScreenSharing: _isScreenSharing,
    );
    notifyListeners();
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    _sessionSeconds = 0;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionSeconds++;
      notifyListeners();
    });
  }

  String get formattedSessionTime {
    final mins = _sessionSeconds ~/ 60;
    final secs = _sessionSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void leaveRoom() {
    _sessionTimer?.cancel();
    _typingTimer?.cancel();
    _isInRoom = false;
    _participants.clear();
    _messages.clear();
    _socket.disconnect();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectSub.cancel();
    _roomJoinedSub.cancel();
    _peerJoinedSub.cancel();
    _peerLeftSub.cancel();
    _peerTypingSub.cancel();
    _chatSub.cancel();
    _problemSub.cancel();
    _peerStateSub.cancel();
    _sessionTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}
