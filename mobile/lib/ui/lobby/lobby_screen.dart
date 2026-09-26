import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/room_provider.dart';
import '../../providers/webrtc_provider.dart';
import '../../providers/editor_provider.dart';
import '../interview/interview_screen.dart';
import 'widgets/av_preview_card.dart';
import 'widgets/room_form_card.dart';

// DevArena Live — Lobby Screen
class LobbyScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const LobbyScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  RTCVideoRenderer? _localRenderer;
  MediaStream? _previewStream;

  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isFrontCamera = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  Future<void> _initMedia() async {
    // Request permissions
    await [Permission.camera, Permission.microphone].request();

    try {
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      _previewStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        },
      });

      if (mounted && _previewStream != null) {
        setState(() {
          _localRenderer!.srcObject = _previewStream;
        });
      }
    } catch (e) {
      debugPrint('[Lobby] Camera init warning: $e');
    }
  }

  void _toggleCamera() {
    setState(() => _isCameraOn = !_isCameraOn);
    _previewStream?.getVideoTracks().forEach((track) {
      track.enabled = _isCameraOn;
    });
  }

  void _toggleMic() {
    setState(() => _isMicOn = !_isMicOn);
    _previewStream?.getAudioTracks().forEach((track) {
      track.enabled = _isMicOn;
    });
  }

  Future<void> _switchCamera() async {
    if (_previewStream == null) return;
    final videoTrack = _previewStream!.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
      setState(() => _isFrontCamera = !_isFrontCamera);
    }
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final p1 = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    final p2 = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'IV-$p1$p2';
  }

  Future<void> _handleStartSession({
    required bool isCreate,
    required String name,
    required String role,
    required String titleOrRoomId,
  }) async {
    setState(() => _isLoading = true);

    final roomId = isCreate ? _generateRoomId() : titleOrRoomId;
    final title = isCreate ? titleOrRoomId : 'Technical Interview';

    final roomProvider = context.read<RoomProvider>();
    final webrtcProvider = context.read<WebRTCProvider>();
    final editorProvider = context.read<EditorProvider>();

    // Dispose preview before starting session to release camera
    _previewStream?.dispose();
    _previewStream = null;
    await _localRenderer?.dispose();
    _localRenderer = null;

    // Join room on Socket.io
    roomProvider.joinRoom(
      roomId: roomId,
      name: name,
      role: role,
      title: title,
      isMuted: !_isMicOn,
      isCamOff: !_isCameraOn,
    );

    // Init Editor Provider
    editorProvider.init(roomId: roomId, myName: name);

    // Init WebRTC Provider
    await webrtcProvider.initialize(
      roomId: roomId,
      isMuted: !_isMicOn,
      isCamOff: !_isCameraOn,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InterviewScreen(
            onToggleTheme: widget.onToggleTheme,
            isDark: widget.isDark,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _previewStream?.dispose();
    _localRenderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.sky,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.code_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: AppTypography.inter(
                  size: 15,
                  weight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                children: const [
                  TextSpan(text: 'Dev'),
                  TextSpan(text: 'Arena ', style: TextStyle(color: AppColors.sky)),
                  TextSpan(text: 'Live', style: TextStyle(fontSize: 12, color: AppColors.emerald)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.amber : AppColors.sky,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.sky),
                  SizedBox(height: 16),
                  Text('Connecting to DevArena Live...'),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 700;

                    if (isTablet) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: AVPreviewCard(
                              renderer: _localRenderer,
                              isCameraOn: _isCameraOn,
                              isMicOn: _isMicOn,
                              isFrontCamera: _isFrontCamera,
                              onToggleCamera: _toggleCamera,
                              onToggleMic: _toggleMic,
                              onSwitchCamera: _switchCamera,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: RoomFormCard(
                              onSubmit: _handleStartSession,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AVPreviewCard(
                          renderer: _localRenderer,
                          isCameraOn: _isCameraOn,
                          isMicOn: _isMicOn,
                          isFrontCamera: _isFrontCamera,
                          onToggleCamera: _toggleCamera,
                          onToggleMic: _toggleMic,
                          onSwitchCamera: _switchCamera,
                        ),
                        const SizedBox(height: 14),
                        RoomFormCard(
                          onSubmit: _handleStartSession,
                        ),
                        const SizedBox(height: 20),
                        // Footer credit
                        Center(
                          child: Text(
                            '© 2026 DevArena Live • Sayim Khan',
                            style: AppTypography.inter(
                              size: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}
