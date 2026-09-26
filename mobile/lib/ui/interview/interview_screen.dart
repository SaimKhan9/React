import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/room_provider.dart';
import '../../providers/webrtc_provider.dart';
import '../lobby/lobby_screen.dart';
import 'widgets/chat_panel.dart';
import 'widgets/code_editor_panel.dart';
import 'widgets/interviewer_tools.dart';
import 'widgets/share_dialog.dart';
import 'widgets/terminal_output.dart';
import 'widgets/top_session_bar.dart';
import 'widgets/video_grid.dart';

// DevArena Live — Live Technical Interview Session Screen (Adaptive Phone & Tablet)
class InterviewScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const InterviewScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  int _activeNavIndex = 0; // 0: Editor, 1: Video, 2: Terminal, 3: Chat, 4: Tools
  bool _isVideoStripVisible = true;

  void _onShare() {
    final room = context.read<RoomProvider>();
    showDialog(
      context: context,
      builder: (_) => ShareDialog(roomId: room.roomId),
    );
  }

  void _onEndSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Interview Session?'),
        content: const Text('Are you sure you want to exit? Your video and real-time connection will be closed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final room = context.read<RoomProvider>();
              final webrtc = context.read<WebRTCProvider>();

              await webrtc.hangUp();
              room.leaveRoom();

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LobbyScreen(
                      onToggleTheme: widget.onToggleTheme,
                      isDark: widget.isDark,
                    ),
                  ),
                );
              }
            },
            child: const Text('Leave Session'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomProvider>();
    final isDark = widget.isDark;

    return Scaffold(
      appBar: TopSessionBar(
        roomId: room.roomId,
        role: room.myRole,
        formattedTime: room.formattedSessionTime,
        participantCount: room.totalParticipants,
        onShare: _onShare,
        onToggleTheme: widget.onToggleTheme,
        onEndSession: _onEndSession,
        isDark: isDark,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 800;

            if (isTablet) {
              return _buildTabletLayout(room, isDark);
            }

            return _buildMobileLayout(room, isDark);
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width > 800
          ? null
          : BottomNavigationBar(
              currentIndex: _activeNavIndex,
              onTap: (index) => setState(() => _activeNavIndex = index),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.code_rounded),
                  label: 'Editor',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.videocam_rounded),
                  label: 'Video',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.terminal_rounded),
                  label: 'Terminal',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded),
                      if (room.messages.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.sky,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Chat',
                ),
                if (room.isInterviewer)
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.grading_rounded),
                    label: 'Tools',
                  ),
              ],
            ),
    );
  }

  // ── Mobile Portrait Layout ────────────────────────────────────────────────
  Widget _buildMobileLayout(RoomProvider room, bool isDark) {
    switch (_activeNavIndex) {
      case 1:
        // Full Video Grid
        return const VideoGrid(isHorizontalStrip: false);

      case 2:
        // Full Output Terminal
        return const TerminalOutput();

      case 3:
        // Live Chat Panel
        return const ChatPanel();

      case 4:
        // Interviewer Notes & Rubric
        return const InterviewerTools();

      case 0:
      default:
        // Main Editor view with Collapsible Top Video Strip
        return Column(
          children: [
            // Collapsible Video Strip
            if (_isVideoStripVisible) ...[
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: Row(
                  children: [
                    const Expanded(
                      child: VideoGrid(isHorizontalStrip: true),
                    ),
                    IconButton(
                      tooltip: 'Hide Video Strip',
                      icon: const Icon(Icons.unfold_less_rounded, size: 16),
                      onPressed: () => setState(() => _isVideoStripVisible = false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ] else ...[
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: Row(
                  children: [
                    const Icon(Icons.videocam_rounded, size: 14, color: AppColors.emerald),
                    const SizedBox(width: 6),
                    Text(
                      '${room.totalParticipants} in call',
                      style: AppTypography.inter(size: 10.5, color: AppColors.emerald),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _isVideoStripVisible = true),
                      child: Row(
                        children: [
                          Text(
                            'Show Video',
                            style: AppTypography.inter(size: 10.5, color: AppColors.sky),
                          ),
                          const Icon(Icons.unfold_more_rounded, size: 14, color: AppColors.sky),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // Code Editor
            Expanded(
              child: CodeEditorPanel(
                onOpenTerminal: () => setState(() => _activeNavIndex = 2),
              ),
            ),
          ],
        );
    }
  }

  // ── Tablet / Landscape Split Pane Layout ───────────────────────────────────
  Widget _buildTabletLayout(RoomProvider room, bool isDark) {
    return Row(
      children: [
        // Left Column: Video Grid + Chat / Tools
        SizedBox(
          width: 320,
          child: Column(
            children: [
              // Video Tiles Area
              const SizedBox(
                height: 240,
                child: VideoGrid(isHorizontalStrip: false),
              ),
              const Divider(height: 1),
              // Side Panel (Chat or Tools)
              Expanded(
                child: room.isInterviewer ? const InterviewerTools() : const ChatPanel(),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // Center / Right Column: Editor + Output Terminal Split
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: CodeEditorPanel(onOpenTerminal: () {}),
              ),
              const Divider(height: 1),
              const Expanded(
                flex: 4,
                child: TerminalOutput(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
