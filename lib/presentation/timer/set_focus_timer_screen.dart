import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/focus_provider.dart';
import '../../routes/app_routes.dart';

class SetFocusTimerScreen extends StatefulWidget {
  const SetFocusTimerScreen({super.key});

  @override
  State<SetFocusTimerScreen> createState() => _SetFocusTimerScreenState();
}

class _SetFocusTimerScreenState extends State<SetFocusTimerScreen> {
  final _goalController = TextEditingController();
  final _tasks = const ['Study', 'Write', 'Break'];
  final _durationPresets = const [25, 45, 50];
  final _companions = const [
    _Companion('Kiki', 'assets/images/fox.png', '+5% Alertness'),
    _Companion('Podo', null, '+5% Calm'),
    _Companion('Luna', null, '+5% Focus'),
    _Companion('Orion', null, '+5% Wisdom'),
  ];

  String _selectedTask = 'Study';
  int _selectedCompanion = 0;
  bool _aiFocusDesignerEnabled = true;
  int _selectedMinutes = 45;

  @override
  void initState() {
    super.initState();
    _goalController.addListener(_handleGoalChanged);
  }

  @override
  void dispose() {
    _goalController.removeListener(_handleGoalChanged);
    _goalController.dispose();
    super.dispose();
  }

  void _handleGoalChanged() => setState(() {});

  void _startFocus() {
    final focus = context.read<FocusProvider>();
    if (focus.phase != FocusPhase.idle) {
      Navigator.of(context).pushNamed(AppRoutes.focus);
      return;
    }
    final label = _goalController.text.trim().isEmpty
        ? _selectedTask
        : _goalController.text.trim();
    focus.start(label: label, durationSeconds: _selectedMinutes * 60);
    Navigator.of(context).pushNamed(AppRoutes.focus);
  }

  int get _rewardTokens => AppConstants.rewardTokensPerBlock + _selectedMinutes;

  int get _rewardExp => AppConstants.rewardExpPerBlock;

  int get _petEnergyCost => (_selectedMinutes / 5).floor();

  String get _suggestedPomodoroText {
    if (_selectedMinutes <= 25) return '1 Pomodoro';
    return 'Deep Focus · 2 Pomodoros';
  }

  String get _focusCategory {
    final goal = _goalController.text.trim().toLowerCase();
    if (_containsAny(goal, const [
      'english',
      'vocabulary',
      'ielts',
      'toeic',
      'listening',
      'speaking',
    ])) {
      return 'English';
    }
    if (_containsAny(goal, const [
      'code',
      'coding',
      'flutter',
      'programming',
      'debug',
      'api',
    ])) {
      return 'Code';
    }
    if (_containsAny(goal, const [
      'write',
      'viết',
      'report',
      'essay',
      'draft',
    ])) {
      return 'Write';
    }
    if (_containsAny(goal, const [
      'ôn',
      'học',
      'study',
      'review',
      'prm',
      'exam',
      'quiz',
    ])) {
      return 'Review';
    }
    if (_selectedTask == 'Break') return 'Reset';
    return _selectedTask;
  }

  String get _focusPlanText {
    final goal = _goalController.text.trim().toLowerCase();
    switch (_focusCategory) {
      case 'English':
        if (_selectedMinutes <= 25) {
          return 'Learn 10 words, then write 5 example sentences.';
        }
        return 'Vocabulary, listening practice, then quick recall review.';
      case 'Code':
        if (_selectedMinutes <= 25) {
          return 'Pick one small feature, code it, then run a quick check.';
        }
        return 'Read requirements, build one slice, then test the flow.';
      case 'Write':
        if (_selectedMinutes <= 25) {
          return 'Create an outline, then draft the first section.';
        }
        return 'Outline, write the draft, then polish weak paragraphs.';
      case 'Review':
        if (goal.contains('prm')) {
          return 'Review PRM concepts, then test yourself with questions.';
        }
        return 'Review key points, then practice recall.';
      case 'Reset':
        return 'Use this as a light reset before the next focus.';
    }
    return 'Focus on one clear task until the timer ends.';
  }

  bool _containsAny(String source, List<String> keywords) {
    return keywords.any(source.contains);
  }

  @override
  Widget build(BuildContext context) {
    final companion = _companions[_selectedCompanion];
    final focus = context.watch<FocusProvider>();
    final hasActiveFocus = focus.phase != FocusPhase.idle;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0FFF4), Color(0xFFE5FFF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GoalInput(controller: _goalController),
                      const SizedBox(height: 14),
                      _TaskChips(
                        tasks: _tasks,
                        selectedTask: _selectedTask,
                        onSelected: (task) =>
                            setState(() => _selectedTask = task),
                      ),
                      const SizedBox(height: 28),
                      _TimerDial(minutes: _selectedMinutes),
                      const SizedBox(height: 16),
                      _DurationPresets(
                        presets: _durationPresets,
                        selectedMinutes: _selectedMinutes,
                        onSelected: (minutes) =>
                            setState(() => _selectedMinutes = minutes),
                      ),
                      const SizedBox(height: 28),
                      _CompanionSelector(
                        companions: _companions,
                        selectedIndex: _selectedCompanion,
                        onSelected: (index) =>
                            setState(() => _selectedCompanion = index),
                      ),
                      const SizedBox(height: 12),
                      _CompanionSummary(companion: companion),
                      const SizedBox(height: 26),
                      _AiFocusDesignerCard(
                        enabled: _aiFocusDesignerEnabled,
                        category: _focusCategory,
                        suggestedText: _suggestedPomodoroText,
                        planText: _focusPlanText,
                        rewardTokens: _rewardTokens,
                        rewardExp: _rewardExp,
                        petEnergyCost: _petEnergyCost,
                        onChanged: (value) =>
                            setState(() => _aiFocusDesignerEnabled = value),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _PotentialEarningsBar(
                rewardTokens: _rewardTokens,
                rewardExp: _rewardExp,
                hasActiveFocus: hasActiveFocus,
                onStart: _startFocus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, color: AppColors.primaryBlue),
          ),
          Expanded(
            child: Text(
              'SET FOCUS TIMER',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading.copyWith(
                fontSize: 21,
                color: const Color(0xFF4367A3),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _GoalInput extends StatelessWidget {
  const _GoalInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'What are you focusing on?',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF90A1B9)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCFCE7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5),
        ),
      ),
    );
  }
}

class _TaskChips extends StatelessWidget {
  const _TaskChips({
    required this.tasks,
    required this.selectedTask,
    required this.onSelected,
  });

  final List<String> tasks;
  final String selectedTask;
  final ValueChanged<String> onSelected;

  IconData _iconFor(String task) {
    return switch (task) {
      'Study' => Icons.menu_book_outlined,
      'Write' => Icons.edit_outlined,
      _ => Icons.coffee_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tasks.map((task) {
        final selected = task == selectedTask;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton.icon(
              onPressed: () => onSelected(task),
              icon: Icon(_iconFor(task), size: 16),
              label: Text(task),
              style: OutlinedButton.styleFrom(
                foregroundColor: selected
                    ? AppColors.primaryBlue
                    : const Color(0xFF45556C),
                backgroundColor: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.62),
                side: BorderSide(
                  color: selected
                      ? AppColors.accentTeal
                      : const Color(0xFFDCFCE7),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF48BB78), Color(0xFF00D5BE), Color(0xFF8EC5FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF0FFF4),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:00',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 58,
                    color: const Color(0xFF28A2A6),
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Text(
                  AppConstants.useTestFocusDuration
                      ? 'FOCUS · TEST ${AppConstants.testFocusSeconds}s'
                      : 'FOCUS',
                  style: AppTextStyles.label.copyWith(
                    color: const Color(0xFF90A1B9),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationPresets extends StatelessWidget {
  const _DurationPresets({
    required this.presets,
    required this.selectedMinutes,
    required this.onSelected,
  });

  final List<int> presets;
  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: presets.map((minutes) {
        final selected = minutes == selectedMinutes;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              onPressed: () => onSelected(minutes),
              style: OutlinedButton.styleFrom(
                backgroundColor: selected
                    ? AppColors.primaryBlue
                    : Colors.white.withValues(alpha: 0.72),
                foregroundColor: selected
                    ? Colors.white
                    : AppColors.primaryBlue,
                side: BorderSide(
                  color: selected
                      ? AppColors.primaryBlue
                      : const Color(0xFFDCFCE7),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                '$minutes min',
                style: AppTextStyles.muted.copyWith(
                  color: selected ? Colors.white : AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CompanionSelector extends StatelessWidget {
  const _CompanionSelector({
    required this.companions,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Companion> companions;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Companion Selector',
              style: AppTextStyles.title.copyWith(
                fontSize: 18,
                color: const Color(0xFF1D293D),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F8EF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '+5% Alertness',
                style: AppTextStyles.muted.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(companions.length, (index) {
            final companion = companions[index];
            final locked = index != 0;
            final selected = !locked && index == selectedIndex;
            return GestureDetector(
              onTap: () {
                if (locked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This companion is coming soon.'),
                    ),
                  );
                  return;
                }
                onSelected(index);
              },
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Opacity(
                        opacity: locked ? 0.58 : 1,
                        child: Container(
                          width: selected ? 72 : 64,
                          height: selected ? 72 : 64,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF48BB78),
                                      Color(0xFF46ECD5),
                                    ],
                                  )
                                : null,
                            color: selected ? null : Colors.white,
                            boxShadow: selected
                                ? const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: companion.assetPath == null
                                ? Container(
                                    color: const Color(0xFFE8F4EF),
                                    child: Center(
                                      child: Text(
                                        ['🦝', '🐈‍⬛', '🦉'][index - 1],
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    companion.assetPath!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      if (locked)
                        const Positioned(
                          right: -2,
                          bottom: -2,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.lock,
                              size: 13,
                              color: Color(0xFF90A1B9),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 72,
                    child: Text(
                      companion.name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: selected
                            ? const Color(0xFF1D293D)
                            : const Color(0xFF90A1B9),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (locked)
                    Text(
                      'Soon',
                      style: AppTextStyles.muted.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF90A1B9),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CompanionSummary extends StatelessWidget {
  const _CompanionSummary({required this.companion});

  final _Companion companion;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: const Color(0xFFDCFCE7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text.rich(
        TextSpan(
          text: '${companion.name}: ',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1D293D),
          ),
          children: [
            TextSpan(
              text: companion.bonus,
              style: AppTextStyles.label.copyWith(
                color: const Color(0xFF45556C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiFocusDesignerCard extends StatelessWidget {
  const _AiFocusDesignerCard({
    required this.enabled,
    required this.category,
    required this.suggestedText,
    required this.planText,
    required this.rewardTokens,
    required this.rewardExp,
    required this.petEnergyCost,
    required this.onChanged,
  });

  final bool enabled;
  final String category;
  final String suggestedText;
  final String planText;
  final int rewardTokens;
  final int rewardExp;
  final int petEnergyCost;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF51A2FF), width: 1.2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60A5FA).withValues(alpha: 0.28),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFDBEAFE),
                child: Icon(Icons.auto_awesome, color: Color(0xFF2B7FFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Focus Designer',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF1D293D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: AppTextStyles.muted.copyWith(
                    color: const Color(0xFF2B7FFF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Suggested', value: suggestedText),
          const SizedBox(height: 10),
          _InfoRow(label: 'Plan', value: planText),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predicted Rewards',
                  style: AppTextStyles.muted.copyWith(
                    color: const Color(0xFF62748E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _RewardBadge(
                      label: '+$rewardTokens Tokens',
                      icon: Icons.add_circle_outline,
                      color: AppColors.warning,
                      backgroundColor: const Color(0xFFFFF8E6),
                    ),
                    const SizedBox(width: 12),
                    _RewardBadge(
                      label: '$rewardExp EXP',
                      icon: Icons.emoji_events_outlined,
                      color: const Color(0xFF2B7FFF),
                      backgroundColor: const Color(0xFFEFF6FF),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Kiki spends about $petEnergyCost energy after completion.',
                  style: AppTextStyles.muted.copyWith(
                    color: const Color(0xFF62748E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: AppTextStyles.muted.copyWith(
                color: const Color(0xFF62748E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: const Color(0xFF1D293D),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PotentialEarningsBar extends StatelessWidget {
  const _PotentialEarningsBar({
    required this.rewardTokens,
    required this.rewardExp,
    required this.hasActiveFocus,
    required this.onStart,
  });

  final int rewardTokens;
  final int rewardExp;
  final bool hasActiveFocus;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'POTENTIAL REWARDS',
                style: AppTextStyles.muted.copyWith(
                  color: const Color(0xFF90A1B9),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _RewardBadge(
                label: '+$rewardTokens',
                icon: Icons.add_circle_outline,
                color: AppColors.warning,
                backgroundColor: const Color(0xFFFEF3C6),
              ),
              const SizedBox(width: 8),
              _RewardBadge(
                label: '$rewardExp EXP',
                color: const Color(0xFF155DFC),
                backgroundColor: const Color(0xFFDBEAFE),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 58,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48BB78),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 10,
                shadowColor: const Color(0x5548BB78),
              ),
              child: Text(
                hasActiveFocus ? 'RETURN TO FOCUS' : 'START FOCUS',
                style: AppTextStyles.title.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.muted.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Companion {
  const _Companion(this.name, this.assetPath, this.bonus);

  final String name;
  final String? assetPath;
  final String bonus;
}
