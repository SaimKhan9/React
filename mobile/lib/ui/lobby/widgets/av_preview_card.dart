import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/theme/app_theme.dart';

// DevArena Live — Camera & Mic Preview Card in Lobby
class AVPreviewCard extends StatelessWidget {
  final RTCVideoRenderer? renderer;
  final bool isCameraOn;
  final bool isMicOn;
  final bool isFrontCamera;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleMic;
  final VoidCallback onSwitchCamera;

  const AVPreviewCard({
    super.key,
    required this.renderer,
    required this.isCameraOn,
    required this.isMicOn,
    required this.isFrontCamera,
    required this.onToggleCamera,
    required this.onToggleMic,
    required this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AV DEVICE CHECK',
                  style: AppTypography.inter(
                    size: 11,
                    weight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Live Preview',
                        style: AppTypography.inter(
                          size: 11,
                          weight: FontWeight.w600,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Video Preview Box
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isCameraOn && renderer != null && renderer!.srcObject != null)
                        RTCVideoView(
                          renderer!,
                          mirror: isFrontCamera,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface2 : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('🧑‍💻', style: TextStyle(fontSize: 26)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Camera is off',
                              style: AppTypography.inter(
                                size: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),

                      // Bottom Floating Controls inside preview
                      Positioned(
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mic Toggle
                              _MediaBtn(
                                icon: isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                                isActive: isMicOn,
                                activeColor: AppColors.sky,
                                inactiveColor: AppColors.red,
                                onTap: onToggleMic,
                              ),
                              const SizedBox(width: 8),
                              // Cam Toggle
                              _MediaBtn(
                                icon: isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                                isActive: isCameraOn,
                                activeColor: AppColors.sky,
                                inactiveColor: AppColors.red,
                                onTap: onToggleCamera,
                              ),
                              if (isCameraOn) ...[
                                const SizedBox(width: 8),
                                // Flip Cam
                                _MediaBtn(
                                  icon: Icons.flip_camera_ios_rounded,
                                  isActive: true,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white,
                                  onTap: onSwitchCamera,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Feature Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FeaturePill(
                  icon: Icons.lock_outline_rounded,
                  label: 'P2P Encrypted',
                  color: AppColors.sky,
                ),
                _FeaturePill(
                  icon: Icons.flash_on_rounded,
                  label: 'Judge0 Engine',
                  color: AppColors.amber,
                ),
                _FeaturePill(
                  icon: Icons.group_outlined,
                  label: 'Multi-User',
                  color: AppColors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _MediaBtn({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.15) : AppColors.red.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 17,
          color: isActive ? activeColor : inactiveColor,
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.inter(size: 11, color: color, weight: FontWeight.w500),
        ),
      ],
    );
  }
}
