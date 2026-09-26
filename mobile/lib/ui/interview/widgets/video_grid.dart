import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/webrtc_provider.dart';

// DevArena Live — Responsive Video Calling Grid & Participant Tiles
class VideoGrid extends StatelessWidget {
  final bool isHorizontalStrip;

  const VideoGrid({super.key, this.isHorizontalStrip = false});

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final webrtcProvider = context.watch<WebRTCProvider>();

    final localRenderer = webrtcProvider.localRenderer;
    final remoteRenderers = webrtcProvider.remoteRenderers;
    final remoteParticipants = roomProvider.remoteParticipants;

    final tiles = <Widget>[
      // Local User Tile
      _VideoTile(
        name: '${roomProvider.myName} (You)',
        role: roomProvider.myRole,
        isMuted: roomProvider.isMuted,
        isCamOff: roomProvider.isCamOff,
        isSpeaking: webrtcProvider.isSpeaking,
        isLocal: true,
        renderer: (webrtcProvider.isInitialized && !roomProvider.isCamOff) ? localRenderer : null,
        isFrontCamera: webrtcProvider.isFrontCamera,
        onToggleMic: () {
          roomProvider.toggleMic();
          webrtcProvider.toggleMic();
        },
        onToggleCam: () {
          roomProvider.toggleCam();
          webrtcProvider.toggleCam();
        },
        onSwitchCam: webrtcProvider.switchCamera,
      ),
    ];

    // Remote Participants Tiles
    for (final participant in remoteParticipants) {
      final renderer = remoteRenderers[participant.id];
      tiles.add(
        _VideoTile(
          name: participant.name,
          role: participant.role,
          isMuted: participant.isMuted,
          isCamOff: participant.isCamOff,
          isSpeaking: participant.isSpeaking,
          isLocal: false,
          renderer: (!participant.isCamOff && renderer != null) ? renderer : null,
          isFrontCamera: false,
        ),
      );
    }

    if (isHorizontalStrip) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: tiles.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) => SizedBox(
            width: 170,
            child: tiles[index],
          ),
        ),
      );
    }

    // Grid layout for tablet or full video mode
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: tiles.length > 2 ? 2 : 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 16 / 10,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) => tiles[index],
    );
  }
}

class _VideoTile extends StatelessWidget {
  final String name;
  final String role;
  final bool isMuted;
  final bool isCamOff;
  final bool isSpeaking;
  final bool isLocal;
  final RTCVideoRenderer? renderer;
  final bool isFrontCamera;
  final VoidCallback? onToggleMic;
  final VoidCallback? onToggleCam;
  final VoidCallback? onSwitchCam;

  const _VideoTile({
    required this.name,
    required this.role,
    required this.isMuted,
    required this.isCamOff,
    required this.isSpeaking,
    required this.isLocal,
    this.renderer,
    this.isFrontCamera = true,
    this.onToggleMic,
    this.onToggleCam,
    this.onSwitchCam,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.black87,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSpeaking
              ? AppColors.emerald
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSpeaking ? 2.5 : 1,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: AppColors.emerald.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Feed or Avatar
            if (!isCamOff && renderer != null && renderer!.srcObject != null)
              RTCVideoView(
                renderer!,
                mirror: isLocal && isFrontCamera,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              Container(
                color: isDark ? AppColors.darkSurface : const Color(0xFF1E242B),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface2 : Colors.grey.shade800,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            role == 'interviewer' ? '👔' : '🧑‍💻',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          size: 11,
                          weight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Badges: Name and Role
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          size: 10,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: role == 'interviewer'
                          ? AppColors.purple.withOpacity(0.8)
                          : AppColors.sky.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: AppTypography.inter(
                        size: 8,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Audio Indicator & Local Controls
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mic Status Icon
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isMuted ? AppColors.red.withOpacity(0.85) : Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),

                  // Local Controls (Flip / Mute / Cam)
                  if (isLocal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onToggleMic,
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Icon(
                                isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                size: 13,
                                color: isMuted ? AppColors.red : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onToggleCam,
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Icon(
                                isCamOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                                size: 13,
                                color: isCamOff ? AppColors.red : Colors.white,
                              ),
                            ),
                          ),
                          if (!isCamOff) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: onSwitchCam,
                              child: const Padding(
                                padding: EdgeInsets.all(3.0),
                                child: Icon(
                                  Icons.flip_camera_ios_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
