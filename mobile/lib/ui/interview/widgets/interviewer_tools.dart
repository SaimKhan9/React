import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/room_provider.dart';

// DevArena Live — Interviewer Confidential Notes & Evaluation Rubric Scorecard
class InterviewerTools extends StatefulWidget {
  const InterviewerTools({super.key});

  @override
  State<InterviewerTools> createState() => _InterviewerToolsState();
}

class _InterviewerToolsState extends State<InterviewerTools> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();

  final EvaluationScorecard _evaluation = EvaluationScorecard();
  bool _isSavingNotes = false;

  final List<Map<String, String>> _presets = [
    {
      'title': 'Palindrome Verification',
      'desc': 'Write a function to check if a string is a palindrome. Handle empty strings and make sure comparison is case-insensitive, ignoring whitespace.',
    },
    {
      'title': 'Two Sum',
      'desc': 'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target. You may not use the same element twice.',
    },
    {
      'title': 'Valid Parentheses',
      'desc': 'Given a string containing just \'(\', \')\', \'{\', \'}\', \'[\' and \']\', determine if the input string is valid. Open brackets must be closed by the same type of brackets in the correct order.',
    },
    {
      'title': 'Reverse Words in String',
      'desc': 'Given an input string s, reverse the order of the words. A word is defined as a sequence of non-space characters. Words will be separated by at least one space.',
    },
    {
      'title': 'Maximum Subarray (Kadane)',
      'desc': 'Given an integer array nums, find the subarray with the largest sum, and return its sum. Must solve in O(n) time complexity.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final room = context.read<RoomProvider>();
    _problemController.text = room.problem;
    _loadNotes(room.roomId);
  }

  Future<void> _loadNotes(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$kStorageNotesKeyPrefix$roomId');
    if (saved != null && mounted) {
      _notesController.text = saved;
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSavingNotes = true);
    final room = context.read<RoomProvider>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$kStorageNotesKeyPrefix${room.roomId}', _notesController.text);
    if (mounted) {
      setState(() => _isSavingNotes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Private notes saved locally!'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: Column(
        children: [
          // ── Tabs ────────────────────────────────────────────────────────────
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.help_outline_rounded, size: 16), text: 'Question'),
                Tab(icon: Icon(Icons.note_alt_outlined, size: 16), text: 'Notes'),
                Tab(icon: Icon(Icons.star_outline_rounded, size: 16), text: 'Evaluation'),
              ],
            ),
          ),

          // ── Tab Views ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Question / Problem Editor Tab
                _buildQuestionTab(room, isDark),

                // 2. Private Notes Tab
                _buildNotesTab(isDark),

                // 3. Evaluation Rubric Tab
                _buildEvaluationTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Question Editor ────────────────────────────────────────────────
  Widget _buildQuestionTab(RoomProvider room, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PROBLEM STATEMENT (BROADCASTS TO CANDIDATE)',
            style: AppTypography.inter(
              size: 11,
              weight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _problemController,
            maxLines: 4,
            style: AppTypography.inter(size: 13),
            decoration: const InputDecoration(
              hintText: 'Enter technical question...',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Broadcast Question Update'),
            onPressed: () {
              room.updateProblem(_problemController.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Question updated and synced to all participants!')),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'CURATED PROBLEM PRESETS',
            style: AppTypography.inter(
              size: 11,
              weight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          ..._presets.map((preset) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  preset['title']!,
                  style: AppTypography.inter(size: 13, weight: FontWeight.w600),
                ),
                subtitle: Text(
                  preset['desc']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    size: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                onTap: () {
                  _problemController.text = preset['desc']!;
                  room.updateProblem(preset['desc']!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Applied preset: ${preset['title']}')),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Tab 2: Confidential Notes ─────────────────────────────────────────────
  Widget _buildNotesTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRIVATE INTERVIEWER NOTES',
                style: AppTypography.inter(
                  size: 11,
                  weight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.save_outlined, size: 14),
                label: Text(_isSavingNotes ? 'Saving...' : 'Save', style: const TextStyle(fontSize: 11)),
                onPressed: _saveNotes,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              style: AppTypography.inter(size: 13),
              decoration: const InputDecoration(
                hintText: '• Candidate Approach & Problem Understanding\n• Time & Space Complexity Discussion\n• Edge Cases Handled\n• Code Modularity & Cleanliness\n• Key Red Flags / Strengths...',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => _saveNotes(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Evaluation Scorecard ───────────────────────────────────────────
  Widget _buildEvaluationTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CANDIDATE ASSESSMENT RUBRIC',
            style: AppTypography.inter(
              size: 11,
              weight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 12),

          _buildRatingRow('Problem Solving', _evaluation.problemSolving, (v) => setState(() => _evaluation.problemSolving = v)),
          _buildRatingRow('Code Quality', _evaluation.codeQuality, (v) => setState(() => _evaluation.codeQuality = v)),
          _buildRatingRow('Data Structures & Algo', _evaluation.algorithms, (v) => setState(() => _evaluation.algorithms = v)),
          _buildRatingRow('Communication', _evaluation.communication, (v) => setState(() => _evaluation.communication = v)),
          _buildRatingRow('Attitude & Culture Fit', _evaluation.attitude, (v) => setState(() => _evaluation.attitude = v)),

          const SizedBox(height: 16),
          Text(
            'HIRING VERDICT',
            style: AppTypography.inter(
              size: 11,
              weight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildVerdictChip('Strong Hire', 'strong_hire', AppColors.emerald),
              _buildVerdictChip('Hire', 'hire', AppColors.sky),
              _buildVerdictChip('Leaning Hire', 'leaning_hire', AppColors.amber),
              _buildVerdictChip('Leaning No Hire', 'leaning_no_hire', AppColors.indigo),
              _buildVerdictChip('No Hire', 'no_hire', AppColors.red),
            ],
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Save Candidate Evaluation'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Candidate scorecard evaluation recorded successfully!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String title, int current, ValueChanged<int> onRate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.inter(size: 12.5, weight: FontWeight.w500)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final star = index + 1;
              return GestureDetector(
                onTap: () => onRate(star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    star <= current ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color: star <= current ? AppColors.amber : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictChip(String label, String value, Color color) {
    final isSelected = _evaluation.verdict == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      side: BorderSide(color: isSelected ? color : Colors.transparent),
      labelStyle: AppTypography.inter(
        size: 11,
        weight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? color : null,
      ),
      onSelected: (_) => setState(() => _evaluation.verdict = value),
    );
  }
}
