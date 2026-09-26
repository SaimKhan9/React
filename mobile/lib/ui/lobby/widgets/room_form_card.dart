import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// DevArena Live — Room Form Card (Create or Join Session)
class RoomFormCard extends StatefulWidget {
  final void Function({
    required bool isCreate,
    required String name,
    required String role,
    required String titleOrRoomId,
  }) onSubmit;

  const RoomFormCard({super.key, required this.onSubmit});

  @override
  State<RoomFormCard> createState() => _RoomFormCardState();
}

class _RoomFormCardState extends State<RoomFormCard> {
  bool _isCreateTab = true;

  final _nameController = TextEditingController(text: 'Ahmed Khan');
  final _titleController = TextEditingController(
    text: 'Senior Full-Stack Engineer – Technical Round',
  );
  final _roomIdController = TextEditingController();

  String _selectedRole = 'interviewer';

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (_isCreateTab) {
      final title = _titleController.text.trim().isEmpty
          ? 'Technical Interview'
          : _titleController.text.trim();
      widget.onSubmit(
        isCreate: true,
        name: name,
        role: _selectedRole,
        titleOrRoomId: title,
      );
    } else {
      String cleanRoomId = _roomIdController.text.trim();
      // Handle pasted links like ...?room=IV-XXXX
      if (cleanRoomId.contains('room=')) {
        final match = RegExp(r'room=([A-Za-z0-9\-_]+)').firstMatch(cleanRoomId);
        if (match != null) cleanRoomId = match.group(1) ?? cleanRoomId;
      }
      if (cleanRoomId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid Room ID')),
        );
        return;
      }
      widget.onSubmit(
        isCreate: false,
        name: name,
        role: _selectedRole,
        titleOrRoomId: cleanRoomId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Tabs (Create vs Join)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: '⚡ Create Interview',
                      isSelected: _isCreateTab,
                      onTap: () => setState(() {
                        _isCreateTab = true;
                        _selectedRole = 'interviewer';
                        if (_nameController.text == 'Sara Ali') {
                          _nameController.text = 'Ahmed Khan';
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _TabButton(
                      label: '🔗 Join Interview',
                      isSelected: !_isCreateTab,
                      onTap: () => setState(() {
                        _isCreateTab = false;
                        _selectedRole = 'candidate';
                        if (_nameController.text == 'Ahmed Khan') {
                          _nameController.text = 'Sara Ali';
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Name Field
            _FieldLabel('YOUR NAME'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Alex Johnson',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 14),

            // Dynamic Field: Title vs Room ID
            if (_isCreateTab) ...[
              _FieldLabel('INTERVIEW TITLE / ROLE'),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Senior Frontend Engineer',
                  prefixIcon: Icon(Icons.work_outline_rounded, size: 18),
                ),
              ),
            ] else ...[
              _FieldLabel('ROOM ID OR INVITE LINK'),
              const SizedBox(height: 6),
              TextField(
                controller: _roomIdController,
                style: AppTypography.mono(size: 13, color: AppColors.sky),
                decoration: const InputDecoration(
                  hintText: 'e.g. IV-A9X2Z1 or paste full URL',
                  prefixIcon: Icon(Icons.link_rounded, size: 18, color: AppColors.sky),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Role Selector
            _FieldLabel('JOINING AS'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _RolePill(
                    icon: '🧑‍💻',
                    label: 'Candidate',
                    isSelected: _selectedRole == 'candidate',
                    onTap: () => setState(() => _selectedRole = 'candidate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RolePill(
                    icon: '👔',
                    label: 'Interviewer',
                    isSelected: _selectedRole == 'interviewer',
                    onTap: () => setState(() => _selectedRole = 'interviewer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RolePill(
                    icon: '👁️',
                    label: 'Observer',
                    isSelected: _selectedRole == 'observer',
                    onTap: () => setState(() => _selectedRole = 'observer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Submit Button
            ElevatedButton(
              onPressed: _submit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCreateTab ? Icons.bolt_rounded : Icons.login_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(_isCreateTab ? 'Launch Interview & Get Link' : 'Enter Interview Room'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: AppTypography.inter(
        size: 11,
        weight: FontWeight.w700,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface2 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.inter(
            size: 12,
            weight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? (isDark ? AppColors.darkText : AppColors.lightText)
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RolePill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sky.withOpacity(0.12)
              : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.sky
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.inter(
                size: 11,
                weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.sky
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
