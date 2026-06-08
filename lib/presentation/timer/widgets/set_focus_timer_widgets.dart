part of '../set_focus_timer_screen.dart';

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
    required this.selectedBonus,
    required this.isUnlocked,
    required this.onSelected,
  });

  final List<_Companion> companions;
  final int selectedIndex;
  final String selectedBonus;
  final bool Function(String code) isUnlocked;
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
                selectedBonus,
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
            final locked = !isUnlocked(companion.code);
            final selected = !locked && index == selectedIndex;
            return GestureDetector(
              onTap: () {
                if (locked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Buy this companion in Shop to unlock.'),
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
                            child: Container(
                              color: const Color(0xFFE8F4EF),
                              alignment: Alignment.center,
                              child: companion.assetPath == null
                                  ? Text(
                                      companion.emoji,
                                      style: const TextStyle(fontSize: 30),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Image.asset(
                                        companion.assetPath!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
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
                      'Shop',
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
    required this.plan,
    required this.status,
    required this.error,
    required this.applied,
    required this.rewardTokens,
    required this.rewardExp,
    required this.petEnergyCost,
    required this.onAnalyze,
    required this.onApply,
  });

  final FocusPlan plan;
  final FocusPlanStatus status;
  final String? error;
  final bool applied;
  final int rewardTokens;
  final int rewardExp;
  final int petEnergyCost;
  final VoidCallback onAnalyze;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final isLoading = status == FocusPlanStatus.loading;
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
                  'Focus Plan Preview',
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
                  plan.subject,
                  style: AppTextStyles.muted.copyWith(
                    color: const Color(0xFF2B7FFF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Clarity', value: plan.clarityLabel),
          const SizedBox(height: 10),
          _InfoRow(label: 'Mode', value: plan.focusMode),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Suggested',
            value: '${plan.recommendedMinutes} min · ${plan.pomodoroLabel}',
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Advice', value: plan.advice),
          const SizedBox(height: 12),
          ...plan.steps
              .take(3)
              .map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PlanStep(text: step),
                ),
              ),
          if (plan.warnings.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...plan.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PlanWarning(text: warning),
              ),
            ),
          ],
          if (error != null && status == FocusPlanStatus.error) ...[
            const SizedBox(height: 8),
            _PlanWarning(text: 'Backend unavailable, using local fallback.'),
          ],
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onAnalyze,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(isLoading ? 'Analyzing...' : 'Analyze Focus'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onApply,
                  icon: Icon(applied ? Icons.check_circle : Icons.task_alt),
                  label: Text(applied ? 'Applied' : 'Apply Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48BB78),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 16, color: Color(0xFF48BB78)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.muted.copyWith(
              color: const Color(0xFF45556C),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanWarning extends StatelessWidget {
  const _PlanWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        text,
        style: AppTextStyles.muted.copyWith(
          color: const Color(0xFF92400E),
          fontWeight: FontWeight.w700,
        ),
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
  const _Companion(
    this.code,
    this.name,
    this.emoji,
    this.assetPath,
    this.bonus,
  );

  final String code;
  final String name;
  final String emoji;
  final String? assetPath;
  final String bonus;
}
