import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/native/focus_silence_service.dart';
import '../../models/focus_plan.dart';
import '../../providers/app_block_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/focus_plan_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shop_provider.dart';
import '../../routes/app_routes.dart';

part 'widgets/set_focus_timer_widgets.dart';

class SetFocusTimerScreen extends StatefulWidget {
  const SetFocusTimerScreen({super.key});

  @override
  State<SetFocusTimerScreen> createState() => _SetFocusTimerScreenState();
}

class _SetFocusTimerScreenState extends State<SetFocusTimerScreen> {
  final _focusSilence = const FocusSilenceService();
  final _goalController = TextEditingController();
  final _tasks = const ['Study', 'Write', 'Break'];
  final _durationPresets = const [25, 45, 50];
  final _companions = const [
    _Companion('kiki', 'Kiki', '🦊', 'assets/images/fox.png', '+5% EXP'),
    _Companion(
      'companion_eagle',
      'Eagle',
      '🦅',
      'assets/images/companion_eagle.png',
      '+10% tokens',
    ),
    _Companion(
      'companion_frog',
      'Frog',
      '🐸',
      'assets/images/companion_frog.png',
      '20% less energy loss',
    ),
    _Companion(
      'companion_giraffe',
      'Giraffe',
      '🦒',
      'assets/images/companion_giraffe.png',
      '+10 tokens for 45+ min',
    ),
  ];

  String _selectedTask = 'Study';
  int _selectedCompanion = 0;
  int _selectedMinutes = 45;
  FocusPlan? _appliedPlan;

  @override
  void initState() {
    super.initState();
    _goalController.addListener(_handleGoalChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadCatalog().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _goalController.removeListener(_handleGoalChanged);
    _goalController.dispose();
    super.dispose();
  }

  void _handleGoalChanged() {
    _clearFocusPlan();
  }

  void _clearFocusPlan() {
    if (!mounted) return;
    _appliedPlan = null;
    context.read<FocusPlanProvider>().clear();
    setState(() {});
  }

  Future<void> _startFocus() async {
    final focus = context.read<FocusProvider>();
    if (focus.phase != FocusPhase.idle) {
      Navigator.of(context).pushNamed(AppRoutes.focus);
      return;
    }
    final appBlock = context.read<AppBlockProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    if (appBlock.blockingEnabled) {
      final started = await appBlock.startBlocking();
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Focus Guard needs all required permissions.'),
          ),
        );
      }
    }
    if (settingsProvider.profile == null) {
      await settingsProvider.load();
    }
    if (settingsProvider.settings.silenceNotificationsDuringFocus) {
      final hasAccess = await _focusSilence.hasNotificationPolicyAccess();
      if (!hasAccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Grant Do Not Disturb access, then start focus again.',
            ),
          ),
        );
        await _focusSilence.openNotificationPolicySettings();
        return;
      }
      final enabled = await _focusSilence.enableFocusSilence();
      if (!enabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not silence notifications.')),
        );
      }
    }
    if (!mounted) return;
    final label =
        _appliedPlan?.normalizedLabel ??
        (_goalController.text.trim().isEmpty
            ? _selectedTask
            : _goalController.text.trim());
    focus.start(
      label: label,
      durationSeconds: _selectedMinutes * 60,
      companionCode: _companions[_selectedCompanion].code,
    );
    Navigator.of(context).pushNamed(AppRoutes.focus);
  }

  Future<void> _analyzeFocusPlan() {
    return context.read<FocusPlanProvider>().analyze(
      goal: _goalController.text,
      selectedMinutes: _selectedMinutes,
      selectedTask: _selectedTask,
    );
  }

  void _applyFocusPlan(FocusPlan plan) {
    setState(() {
      _appliedPlan = plan;
      _selectedMinutes = plan.recommendedMinutes;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.focusMode} applied to this session.')),
    );
  }

  int get _baseRewardTokens =>
      AppConstants.rewardTokensPerBlock + _selectedMinutes;

  int get _rewardTokens {
    final companion = _companions[_selectedCompanion];
    if (companion.code == 'companion_eagle') {
      return _baseRewardTokens + (_baseRewardTokens * 0.1).ceil();
    }
    if (companion.code == 'companion_giraffe' && _selectedMinutes >= 45) {
      return _baseRewardTokens + 10;
    }
    return _baseRewardTokens;
  }

  int get _rewardExp {
    final baseExp = AppConstants.rewardExpPerBlock;
    if (_companions[_selectedCompanion].code == 'kiki') {
      return baseExp + (baseExp * 0.05).ceil();
    }
    return baseExp;
  }

  int get _petEnergyCost {
    final baseCost = (_selectedMinutes / 5).floor();
    if (_companions[_selectedCompanion].code == 'companion_frog') {
      return (baseCost - (baseCost * 0.2).ceil()).clamp(0, baseCost);
    }
    return baseCost;
  }

  @override
  Widget build(BuildContext context) {
    final companion = _companions[_selectedCompanion];
    final focus = context.watch<FocusProvider>();
    final focusPlanState = context.watch<FocusPlanProvider>();
    final shop = context.watch<ShopProvider>();
    final hasActiveFocus = focus.phase != FocusPhase.idle;
    final activePlan =
        focusPlanState.plan ??
        FocusPlan.fallback(
          goal: _goalController.text,
          selectedMinutes: _selectedMinutes,
          selectedTask: _selectedTask,
        );

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
                        onSelected: (task) {
                          _clearFocusPlan();
                          setState(() => _selectedTask = task);
                        },
                      ),
                      const SizedBox(height: 28),
                      _TimerDial(minutes: _selectedMinutes),
                      const SizedBox(height: 16),
                      _DurationPresets(
                        presets: _durationPresets,
                        selectedMinutes: _selectedMinutes,
                        onSelected: (minutes) {
                          _clearFocusPlan();
                          setState(() => _selectedMinutes = minutes);
                        },
                      ),
                      const SizedBox(height: 28),
                      _CompanionSelector(
                        companions: _companions,
                        selectedIndex: _selectedCompanion,
                        selectedBonus: companion.bonus,
                        isUnlocked: shop.isCompanionUnlocked,
                        onSelected: (index) =>
                            setState(() => _selectedCompanion = index),
                      ),
                      const SizedBox(height: 12),
                      _CompanionSummary(companion: companion),
                      const SizedBox(height: 26),
                      _AiFocusDesignerCard(
                        plan: activePlan,
                        status: focusPlanState.status,
                        error: focusPlanState.error,
                        applied: _appliedPlan == activePlan,
                        rewardTokens: _rewardTokens,
                        rewardExp: _rewardExp,
                        petEnergyCost: _petEnergyCost,
                        onAnalyze: _analyzeFocusPlan,
                        onApply: () => _applyFocusPlan(activePlan),
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
