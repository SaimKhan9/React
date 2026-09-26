import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/languages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/editor_provider.dart';
import '../../../providers/room_provider.dart';

// DevArena Live — Mobile Code Editor Panel with Language Toolbar & Problem Bar
class CodeEditorPanel extends StatefulWidget {
  final VoidCallback onOpenTerminal;

  const CodeEditorPanel({super.key, required this.onOpenTerminal});

  @override
  State<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends State<CodeEditorPanel> {
  late TextEditingController _textController;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _lineScrollController = ScrollController();
  bool _showProblem = true;

  @override
  void initState() {
    super.initState();
    final editor = context.read<EditorProvider>();
    _textController = TextEditingController(text: editor.code);

    // Sync line number scrolling with code scrolling
    _scrollController.addListener(() {
      if (_lineScrollController.hasClients) {
        _lineScrollController.jumpTo(_scrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _lineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    final room = context.watch<RoomProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Keep textController in sync with remote edits if user is not actively typing
    if (_textController.text != editor.code) {
      final cursor = _textController.selection;
      _textController.value = TextEditingValue(
        text: editor.code,
        selection: cursor.baseOffset <= editor.code.length
            ? cursor
            : TextSelection.collapsed(offset: editor.code.length),
      );
    }

    final lineCount = '\n'.allMatches(editor.code).length + 1;

    return Column(
      children: [
        // ── Problem Question Bar ──────────────────────────────────────────────
        if (_showProblem)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : const Color(0xFFF0F4F8),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.sky),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    room.problem,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      size: 11.5,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showProblem = false),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.close, size: 14, color: AppColors.darkTextMuted),
                  ),
                ),
              ],
            ),
          ),

        // ── Editor Toolbar ───────────────────────────────────────────────────
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
              // Language Selector Dropdown
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface2 : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: editor.currentLanguage.id,
                    dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                    style: AppTypography.inter(
                      size: 11,
                      weight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, size: 16),
                    items: kLanguages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang.id,
                        child: Text(lang.displayName),
                      );
                    }).toList(),
                    onChanged: (langId) {
                      if (langId != null) {
                        editor.changeLanguage(getLanguageById(langId));
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Peer typing indicator pill
              if (room.peerTypingName != null)
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.sky),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${room.peerTypingName} is typing...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(size: 10, color: AppColors.sky),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),

              // Show problem banner toggle if hidden
              if (!_showProblem)
                IconButton(
                  tooltip: 'Show Question',
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  onPressed: () => setState(() => _showProblem = true),
                ),

              // Reset Code Button
              IconButton(
                tooltip: 'Reset to starter code',
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset Code?'),
                      content: const Text('This will reset editor to the default starter template.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            editor.resetCode();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 4),

              // RUN CODE BUTTON (Green)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(64, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: editor.isRunning
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(
                  editor.isRunning ? 'Running' : 'Run',
                  style: AppTypography.inter(size: 11, weight: FontWeight.w700),
                ),
                onPressed: editor.isRunning
                    ? null
                    : () async {
                        await editor.runCode();
                        widget.onOpenTerminal();
                      },
              ),
            ],
          ),
        ),

        // ── Code Editor Body (Line Numbers + Text Area) ──────────────────────
        Expanded(
          child: Container(
            color: isDark ? AppColors.darkBg : Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Numbers Gutter
                Container(
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF090D12) : const Color(0xFFF6F8FA),
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    controller: _lineScrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lineCount,
                    itemBuilder: (context, index) {
                      return Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: AppTypography.mono(
                          size: 11.5,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      );
                    },
                  ),
                ),

                // Monospace Code TextField
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TextField(
                      controller: _textController,
                      scrollController: _scrollController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: AppTypography.mono(
                        size: 13,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                      onChanged: (val) => editor.onCodeChanged(val),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
