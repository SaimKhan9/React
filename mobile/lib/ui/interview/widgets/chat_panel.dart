import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/room_provider.dart';

// DevArena Live — Live Session Chat Panel
class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final room = context.read<RoomProvider>();
    room.sendChatMessage(text);
    _msgController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomProvider>();
    final messages = room.messages;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: Column(
        children: [
          // ── Chat Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.sky),
                const SizedBox(width: 8),
                Text(
                  'INTERVIEW CHAT',
                  style: AppTypography.inter(
                    size: 11,
                    weight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${messages.length} messages',
                  style: AppTypography.inter(
                    size: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // ── Messages List ───────────────────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 36,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No messages yet',
                          style: AppTypography.inter(
                            size: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _MessageBubble(
                        message: msg,
                        isSelf: msg.senderName == room.myName,
                        isDark: isDark,
                      );
                    },
                  ),
          ),

          // ── Message Input Bar ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: AppTypography.inter(size: 13),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.sky,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSelf;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isSelf,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface2 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              style: AppTypography.inter(
                size: 10.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
        ),
      );
    }

    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSelf ? 'You' : message.senderName,
                style: AppTypography.inter(
                  size: 10.5,
                  weight: FontWeight.w600,
                  color: isSelf ? AppColors.sky : (isDark ? AppColors.darkText : AppColors.lightText),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: AppTypography.inter(size: 9.5, color: isDark ? Colors.white30 : Colors.black38),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelf
                  ? AppColors.sky
                  : (isDark ? AppColors.darkSurface2 : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: !isSelf
                  ? Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  : null,
            ),
            child: Text(
              message.text,
              style: AppTypography.inter(
                size: 12.5,
                color: isSelf ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
