import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

// DevArena Live — Share Interview Link & Room ID Dialog
class ShareDialog extends StatefulWidget {
  final String roomId;

  const ShareDialog({super.key, required this.roomId});

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  bool _copied = false;

  String get _inviteUrl => 'https://devarena-live.vercel.app/?room=${widget.roomId}&role=candidate';

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _inviteUrl));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Candidate invite link copied to clipboard!')),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sky.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link_rounded, color: AppColors.sky, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Interview Link',
                        style: AppTypography.inter(size: 15, weight: FontWeight.w700),
                      ),
                      Text(
                        'Invite candidate or observer to join',
                        style: AppTypography.inter(
                          size: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Room ID Box
            Text(
              'ROOM ID',
              style: AppTypography.inter(
                size: 10.5,
                weight: FontWeight.w700,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.roomId,
                    style: AppTypography.mono(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.sky,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.roomId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room ID copied!')),
                      );
                    },
                    child: const Text('Copy ID', style: TextStyle(color: AppColors.sky, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Candidate URL Box
            Text(
              'ONE-CLICK WEB/APP INVITE URL',
              style: AppTypography.inter(
                size: 10.5,
                weight: FontWeight.w700,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _inviteUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(size: 11, color: AppColors.sky),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(60, 32),
                    ),
                    icon: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 13,
                    ),
                    label: Text(_copied ? 'Copied' : 'Copy', style: const TextStyle(fontSize: 11)),
                    onPressed: _copyUrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Info Notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emerald.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.emerald.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.devices_rounded, size: 16, color: AppColors.emerald),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Candidates can join instantly from any browser (laptop/desktop) or another mobile device with zero signup required.',
                      style: AppTypography.inter(
                        size: 10.5,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
