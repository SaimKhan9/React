import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

// DevArena Live — Live Session Header Bar
class TopSessionBar extends StatefulWidget implements PreferredSizeWidget {
  final String roomId;
  final String role;
  final String formattedTime;
  final int participantCount;
  final VoidCallback onShare;
  final VoidCallback onToggleTheme;
  final VoidCallback onEndSession;
  final bool isDark;

  const TopSessionBar({
    super.key,
    required this.roomId,
    required this.role,
    required this.formattedTime,
    required this.participantCount,
    required this.onShare,
    required this.onToggleTheme,
    required this.onEndSession,
    required this.isDark,
  });

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  State<TopSessionBar> createState() => _TopSessionBarState();
}

class _TopSessionBarState extends State<TopSessionBar> {
  bool _copied = false;

  void _copyRoomId() {
    Clipboard.setData(ClipboardData(text: widget.roomId));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room ID copied: ${widget.roomId}'),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          // Branding Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.code_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),

          // Room ID Clickable Chip
          GestureDetector(
            onTap: _copyRoomId,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.lightBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.roomId,
                    style: AppTypography.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.sky,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 11,
                    color: _copied ? AppColors.emerald : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: widget.role == 'interviewer'
                  ? AppColors.purple.withOpacity(0.15)
                  : AppColors.sky.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.role == 'interviewer'
                    ? AppColors.purple.withOpacity(0.3)
                    : AppColors.sky.withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.role.toUpperCase(),
              style: AppTypography.inter(
                size: 9,
                weight: FontWeight.w700,
                color: widget.role == 'interviewer' ? AppColors.purple : AppColors.sky,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Live Stopwatch Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface2 : AppColors.lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 13, color: AppColors.amber),
              const SizedBox(width: 4),
              Text(
                widget.formattedTime,
                style: AppTypography.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Participant count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.emerald.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_alt_outlined, size: 12, color: AppColors.emerald),
              const SizedBox(width: 3),
              Text(
                '${widget.participantCount}',
                style: AppTypography.inter(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),

        // Share Button
        IconButton(
          tooltip: 'Invite Candidate',
          icon: const Icon(Icons.share_outlined, size: 18),
          onPressed: widget.onShare,
        ),

        // End Call Button
        IconButton(
          tooltip: 'Leave Session',
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.call_end_rounded, color: AppColors.red, size: 16),
          ),
          onPressed: widget.onEndSession,
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
