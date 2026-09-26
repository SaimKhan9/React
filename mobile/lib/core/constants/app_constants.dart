// DevArena Live — App-wide constants
// backend: https://devarena-server-9z6z.onrender.com

const String kServerUrl = 'https://devarena-server-9z6z.onrender.com';
const String kAppName = 'DevArena Live';
const String kAppVersion = '1.0.0';
const String kStorageThemeKey = 'devarena_theme';
const String kStorageNotesKeyPrefix = 'devarena_notes_';

// ICE servers for WebRTC peer connection (Google STUN)
const List<Map<String, dynamic>> kIceServers = [
  {'urls': 'stun:stun.l.google.com:19302'},
  {'urls': 'stun:stun1.l.google.com:19302'},
  {'urls': 'stun:stun2.l.google.com:19302'},
  {'urls': 'stun:stun3.l.google.com:19302'},
  {'urls': 'stun:stun4.l.google.com:19302'},
];

// WebRTC peer connection config
const Map<String, dynamic> kWebRTCConfig = {
  'iceServers': kIceServers,
  'iceCandidatePoolSize': 10,
};

// Judge0 language IDs (mapped to language names)
const Map<String, int> kJudge0LanguageIds = {
  'python': 71,
  'javascript': 63,
  'typescript': 74,
  'cpp': 54,
  'java': 62,
  'go': 60,
  'rust': 73,
  'ruby': 72,
  'php': 68,
};
