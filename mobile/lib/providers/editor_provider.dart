import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/constants/languages.dart';
import '../../data/models/models.dart';
import '../../data/services/execution_service.dart';
import '../../data/services/socket_service.dart';

// DevArena Live — Code Editor & Execution Provider
class EditorProvider extends ChangeNotifier {
  final SocketService _socket = SocketService();
  final ExecutionService _executionService = ExecutionService();

  LanguageConfig _currentLanguage = kLanguages.first; // Python default
  String _code = '';
  String _roomId = '';
  String _myName = '';

  // Execution state
  bool _isRunning = false;
  ExecutionResult _executionResult = ExecutionResult.empty();

  // Debouncer for outgoing code changes (300ms)
  Timer? _debounceTimer;

  // Typing state
  bool _isTyping = false;
  Timer? _typingDebounce;

  // Getters
  LanguageConfig get currentLanguage => _currentLanguage;
  String get code => _code;
  bool get isRunning => _isRunning;
  ExecutionResult get executionResult => _executionResult;

  late final StreamSubscription _codeChangeSub;
  late final StreamSubscription _langChangeSub;
  late final StreamSubscription _execRunSub;
  late final StreamSubscription _execOutputSub;

  EditorProvider() {
    _code = _currentLanguage.starterCode;
    _initListeners();
  }

  void init({required String roomId, required String myName}) {
    _roomId = roomId;
    _myName = myName;
  }

  void _initListeners() {
    // Remote code updates
    _codeChangeSub = _socket.onCodeChange.listen((data) {
      final incomingCode = data['code']?.toString();
      final incomingLang = data['language']?.toString();

      if (incomingCode != null && incomingCode != _code) {
        _code = incomingCode;
        if (incomingLang != null && incomingLang != _currentLanguage.id) {
          _currentLanguage = getLanguageById(incomingLang);
        }
        notifyListeners();
      }
    });

    // Remote language change
    _langChangeSub = _socket.onLanguageChange.listen((langId) {
      if (langId != _currentLanguage.id) {
        _currentLanguage = getLanguageById(langId);
        notifyListeners();
      }
    });

    // Remote execution trigger
    _execRunSub = _socket.onExecutionRun.listen((data) {
      _isRunning = true;
      notifyListeners();
    });

    // Remote execution output
    _execOutputSub = _socket.onExecutionOutput.listen((data) {
      _isRunning = false;
      _executionResult = ExecutionResult.fromJson(data);
      notifyListeners();
    });
  }

  // Called whenever user edits code in the editor
  void onCodeChanged(String newCode) {
    if (newCode == _code) return;
    _code = newCode;

    // Send typing presence
    _sendTyping();

    // Debounce code broadcast by 300ms to prevent cursor jumping on peers
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_roomId.isNotEmpty) {
        _socket.sendCodeChange(
          roomId: _roomId,
          code: _code,
          language: _currentLanguage.id,
        );
      }
    });
  }

  void changeLanguage(LanguageConfig lang) {
    _currentLanguage = lang;
    _code = lang.starterCode;

    if (_roomId.isNotEmpty) {
      _socket.sendLanguageChange(roomId: _roomId, language: lang.id);
      _socket.sendCodeChange(roomId: _roomId, code: _code, language: lang.id);
    }
    notifyListeners();
  }

  void resetCode() {
    _code = _currentLanguage.starterCode;
    if (_roomId.isNotEmpty) {
      _socket.sendCodeChange(roomId: _roomId, code: _code, language: _currentLanguage.id);
    }
    notifyListeners();
  }

  Future<void> runCode({String stdin = ''}) async {
    if (_isRunning) return;

    _isRunning = true;
    notifyListeners();

    // Notify peers that execution started
    if (_roomId.isNotEmpty) {
      _socket.sendExecutionRun(roomId: _roomId, language: _currentLanguage.id);
    }

    try {
      final result = await _executionService.execute(
        language: _currentLanguage.id,
        sourceCode: _code,
        stdin: stdin,
      );

      _executionResult = result;

      // Broadcast result to peers
      if (_roomId.isNotEmpty) {
        _socket.sendExecutionOutput(
          roomId: _roomId,
          output: {
            'stdout': result.stdout,
            'stderr': result.stderr,
            'compile_output': result.compileOutput,
            'status': {'description': result.status, 'id': result.isSuccess ? 3 : 6},
            'time': result.time,
            'memory': result.memory,
          },
        );
      }
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  void clearOutput() {
    _executionResult = ExecutionResult.empty();
    notifyListeners();
  }

  void _sendTyping() {
    if (!_isTyping && _roomId.isNotEmpty) {
      _isTyping = true;
      _socket.sendTyping(roomId: _roomId, name: _myName, isTyping: true);
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      if (_roomId.isNotEmpty) {
        _socket.sendTyping(roomId: _roomId, name: _myName, isTyping: false);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _typingDebounce?.cancel();
    _codeChangeSub.cancel();
    _langChangeSub.cancel();
    _execRunSub.cancel();
    _execOutputSub.cancel();
    super.dispose();
  }
}
