import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/editor_provider.dart';

// DevArena Live — Terminal Output Panel (Console)
class TerminalOutput extends StatefulWidget {
  const TerminalOutput({super.key});

  @override
  State<TerminalOutput> createState() => _TerminalOutputState();
}

class _TerminalOutputState extends State<TerminalOutput> {
  final TextEditingController _stdinController = TextEditingController();
  bool _showStdin = false;

  @override
  void dispose() {
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    final result = editor.executionResult;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF090D12) : const Color(0xFF1E242B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Terminal Header Bar ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFF242B33),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.white10,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, size: 16, color: AppColors.sky),
                const SizedBox(width: 8),
                Text(
                  'OUTPUT TERMINAL',
                  style: AppTypography.inter(
                    size: 11,
                    weight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),

                // Status Pill
                if (result.status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: result.isSuccess
                          ? AppColors.emerald.withOpacity(0.18)
                          : AppColors.red.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: result.isSuccess ? AppColors.emerald : AppColors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      result.status,
                      style: AppTypography.inter(
                        size: 10,
                        weight: FontWeight.w700,
                        color: result.isSuccess ? AppColors.emerald : AppColors.red,
                      ),
                    ),
                  ),

                // Execution time
                if (result.time != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${result.time}s',
                    style: AppTypography.mono(size: 10, color: Colors.white38),
                  ),
                ],

                const Spacer(),

                // Toggle Stdin
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    minimumSize: const Size(40, 26),
                  ),
                  icon: Icon(
                    _showStdin ? Icons.keyboard_arrow_up : Icons.input_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                  label: Text(
                    'Stdin',
                    style: AppTypography.inter(size: 10, color: Colors.white70),
                  ),
                  onPressed: () => setState(() => _showStdin = !_showStdin),
                ),

                // Clear Output
                IconButton(
                  tooltip: 'Clear Console',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.white54),
                  onPressed: () => editor.clearOutput(),
                ),
              ],
            ),
          ),

          // ── Stdin Input Drawer ──────────────────────────────────────────────
          if (_showStdin)
            Container(
              padding: const EdgeInsets.all(8),
              color: isDark ? AppColors.darkSurface2 : const Color(0xFF1E242B),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stdinController,
                      style: AppTypography.mono(size: 12, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter standard input (stdin)...',
                        hintStyle: AppTypography.inter(size: 11, color: Colors.white38),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(50, 32),
                    ),
                    onPressed: () => editor.runCode(stdin: _stdinController.text),
                    child: const Text('Run with Stdin', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),

          // ── Output Content Area ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: editor.isRunning
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
                            SizedBox(height: 10),
                            Text(
                              'Executing code sandboxed in Judge0 container...',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SelectableText(
                      result.combinedOutput.isNotEmpty
                          ? result.combinedOutput
                          : '⚡ Click "Run" to compile and execute your solution.\nOutput will stream live to both interviewer and candidate.',
                      style: AppTypography.mono(
                        size: 12.5,
                        color: result.isSuccess
                            ? const Color(0xFF79C0FF)
                            : (result.stderr.isNotEmpty || result.compileOutput.isNotEmpty)
                                ? const Color(0xFFFF7B72)
                                : Colors.white54,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
