// DevArena Live — Domain models

class Participant {
  final String id;
  final String name;
  final String role;
  bool isMuted;
  bool isCamOff;
  bool isScreenSharing;
  bool isSpeaking;

  Participant({
    required this.id,
    required this.name,
    required this.role,
    this.isMuted = false,
    this.isCamOff = false,
    this.isScreenSharing = false,
    this.isSpeaking = false,
  });

  Participant copyWith({
    String? id,
    String? name,
    String? role,
    bool? isMuted,
    bool? isCamOff,
    bool? isScreenSharing,
    bool? isSpeaking,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isMuted: isMuted ?? this.isMuted,
      isCamOff: isCamOff ?? this.isCamOff,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'candidate',
      isMuted: json['isMuted'] as bool? ?? false,
      isCamOff: json['isCamOff'] as bool? ?? false,
      isScreenSharing: json['isScreenSharing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'isMuted': isMuted,
        'isCamOff': isCamOff,
        'isScreenSharing': isScreenSharing,
      };
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isSystem': isSystem,
      };
}

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String compileOutput;
  final String status;
  final double? time;
  final int? memory;
  final bool isSuccess;

  const ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.compileOutput,
    required this.status,
    this.time,
    this.memory,
    required this.isSuccess,
  });

  factory ExecutionResult.empty() => const ExecutionResult(
        stdout: '',
        stderr: '',
        compileOutput: '',
        status: '',
        isSuccess: false,
      );

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    final statusObj = json['status'] as Map<String, dynamic>?;
    final statusDesc = statusObj?['description'] as String? ?? '';
    final isSuccess = statusObj?['id'] == 3; // Judge0 id 3 = Accepted

    return ExecutionResult(
      stdout: _decode(json['stdout']),
      stderr: _decode(json['stderr']),
      compileOutput: _decode(json['compile_output']),
      status: statusDesc,
      time: json['time'] != null ? double.tryParse(json['time'].toString()) : null,
      memory: json['memory'] as int?,
      isSuccess: isSuccess,
    );
  }

  static String _decode(dynamic val) {
    if (val == null) return '';
    final str = val.toString();
    // Handle base64-like encoding from server if present
    return str;
  }

  String get combinedOutput {
    final parts = <String>[];
    if (compileOutput.isNotEmpty) parts.add('🔧 Compile:\n$compileOutput');
    if (stdout.isNotEmpty) parts.add(stdout);
    if (stderr.isNotEmpty) parts.add('⚠️ Error:\n$stderr');
    return parts.join('\n');
  }
}

class EvaluationScorecard {
  int problemSolving;
  int codeQuality;
  int algorithms;
  int communication;
  int attitude;
  String verdict;
  String notes;

  EvaluationScorecard({
    this.problemSolving = 0,
    this.codeQuality = 0,
    this.algorithms = 0,
    this.communication = 0,
    this.attitude = 0,
    this.verdict = 'leaning_no_hire',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'problemSolving': problemSolving,
        'codeQuality': codeQuality,
        'algorithms': algorithms,
        'communication': communication,
        'attitude': attitude,
        'verdict': verdict,
        'notes': notes,
      };
}
