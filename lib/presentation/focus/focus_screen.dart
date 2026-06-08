import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/native/focus_silence_service.dart';
import '../../models/pet.dart';
import '../../models/focus_summary.dart';
import '../../models/wallet.dart';
import '../../providers/app_block_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/floating_particles.dart';
import '../widgets/pet_animated_widget.dart';
import 'widgets/focus_claim_panel.dart';
import 'widgets/focus_partner_panel.dart';
import 'widgets/focus_session_summary.dart';
import 'widgets/focus_silence_indicator.dart';
import 'widgets/focus_timer_circle.dart';

// ---------------------------------------------------------------------------
// Motivational phrases for Kiki
// ---------------------------------------------------------------------------
const List<String> _focusPhrases = [
  'Just a little more, Kiki is proud of you!',
  'Stay strong! Kiki is cheering for you! 🎉',
  'You\'re doing great! Kiki believes in you!',
  'Almost there! Keep going, Kiki says! 💪',
  'Kiki is watching – don\'t give up now!',
];

const List<String> _breakPhrases = [
  'Take a breather, you earned it! 🌿',
  'Kiki wants a quick snack. You too? 🍎',
  'Short rest – then back to greatness!',
  'Recharge! Kiki is napping too. 😴',
  'Great session! Rest up for the next one.',
];

const List<String> _donePhrases = [
  'Amazing focus session! 🎊',
  'You crushed it! Kiki is dancing!',
  'Reward time! You deserve it! ⭐',
];

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  final _focusSilence = const FocusSilenceService();

  // Phase color tween controller
  late AnimationController _phaseColorController;
  late Animation<Color?> _ringColor;
  late Animation<Color?> _glowColor;

  // Pulsing glow for the timer ring during focus
  late AnimationController _glowController;
  late Animation<double> _glowRadius;

  // Particle trigger (incremented to fire burst)
  int _particleTrigger = 0;

  // Phrase to display below pet
  String _currentPhrase = _focusPhrases[0];
  FocusPhase _lastPhase = FocusPhase.idle;
  int _phraseIndex = 0;

  // Pet state
  PetAnimationState _petState = PetAnimationState.idle;

  @override
  void initState() {
    super.initState();

    _phaseColorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _ringColor =
        ColorTween(
          begin: const Color(0xFF41B8D5),
          end: const Color(0xFFF6A53A),
        ).animate(
          CurvedAnimation(
            parent: _phaseColorController,
            curve: Curves.easeInOut,
          ),
        );

    _glowColor = ColorTween(
      begin: const Color(0x2241B8D5),
      end: const Color(0x44F6A53A),
    ).animate(_phaseColorController);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glowRadius = Tween<double>(begin: 6, end: 20).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _phaseColorController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handlePhaseChange(FocusPhase newPhase) {
    if (newPhase == _lastPhase) return;
    _lastPhase = newPhase;

    switch (newPhase) {
      case FocusPhase.focusing:
        _phaseColorController.reverse(); // teal
        _phraseIndex = (_phraseIndex + 1) % _focusPhrases.length;
        setState(() {
          _currentPhrase = _focusPhrases[_phraseIndex];
          _petState = PetAnimationState.focusing;
        });

      case FocusPhase.breakTime:
        _phaseColorController.forward(); // orange
        setState(() {
          _currentPhrase = _breakPhrases[_phraseIndex % _breakPhrases.length];
          _petState = PetAnimationState.happy;
        });

      case FocusPhase.done:
        unawaited(context.read<AppBlockProvider>().stopBlocking());
        unawaited(_focusSilence.disableFocusSilence());
        _phaseColorController.reverse();
        setState(() {
          _currentPhrase = _donePhrases[_phraseIndex % _donePhrases.length];
          _petState = PetAnimationState.celebrating;
          _particleTrigger++;
        });

      case FocusPhase.idle:
        unawaited(context.read<AppBlockProvider>().stopBlocking());
        unawaited(_focusSilence.disableFocusSilence());
        setState(() {
          _currentPhrase = _focusPhrases[0];
          _petState = PetAnimationState.idle;
        });
    }
  }

  void _schedulePhaseChange(FocusPhase phase) {
    if (phase == _lastPhase) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handlePhaseChange(phase);
    });
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    final pet = context.watch<PetProvider>().pet;
    final settings = context.watch<SettingsProvider>().settings;

    // React to phase changes
    _schedulePhaseChange(focus.phase);

    final isDone = focus.phase == FocusPhase.done;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFE4FFEE)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 44,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Title
                      Text(
                        'YOUR PROCESS',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 24,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FocusSessionSummary(focus: focus),
                      if (settings.silenceNotificationsDuringFocus &&
                          focus.isRunning) ...[
                        const SizedBox(height: 10),
                        const FocusSilenceIndicator(),
                      ],
                      const SizedBox(height: 18),

                      // Animated timer circle with glow
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: focus.isRunning
                                    ? [
                                        BoxShadow(
                                          color:
                                              _glowColor.value ??
                                              Colors.transparent,
                                          blurRadius: _glowRadius.value,
                                          spreadRadius: 4,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: FocusTimerCircle(
                          progress: focus.progress,
                          text: focus.phase == FocusPhase.idle
                              ? AppConstants.useTestFocusDuration
                                    ? '${AppConstants.testFocusSeconds}s'
                                    : '${AppConstants.focusMinutes}\''
                              : focus.formattedRemaining,
                          subtitle: focus.phase == FocusPhase.breakTime
                              ? 'break'
                              : 'left',
                          ringColorAnim: _ringColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Partner panel with animated Kiki + phrase
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          FocusPartnerPanel(
                            petName: pet.name,
                            imagePath: pet.skinAssetPath,
                            phrase: _currentPhrase,
                            petState: _petState,
                          ),
                          // Celebration particles
                          FloatingParticlesWidget(
                            trigger: _particleTrigger,
                            emojis: const ['⭐', '🎉', '⚡', '✨'],
                            count: 12,
                            spread: 120,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Claim panel
                      FocusClaimPanel(
                        canClaim: isDone,
                        rewardTokens:
                            AppConstants.rewardTokensPerBlock +
                            focus.plannedFocusMinutes,
                        rewardExp: AppConstants.rewardExpPerBlock,
                        onClaim: () => _claimReward(context),
                      ),
                      const SizedBox(height: 18),

                      // Action buttons
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildActionButton(focus),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(FocusProvider focus) {
    if (focus.phase == FocusPhase.breakTime) {
      return OutlinedButton(
        key: const ValueKey('break-running'),
        onPressed: null,
        child: Text(
          AppConstants.useTestFocusDuration
              ? 'Break running · ${AppConstants.testFocusSeconds}s'
              : 'Break running · ${AppConstants.breakMinutes} min',
        ),
      );
    } else if (focus.phase == FocusPhase.focusing) {
      return OutlinedButton(
        key: const ValueKey('cancel'),
        onPressed: () => _cancelFocus(focus),
        child: const Text('Cancel focus'),
      );
    } else if (focus.canStartBreakAfterFocus) {
      return ElevatedButton.icon(
        key: const ValueKey('break'),
        onPressed: focus.startBreakAfterFocus,
        icon: const Icon(Icons.free_breakfast_outlined),
        label: Text(
          AppConstants.useTestFocusDuration
              ? 'Start ${AppConstants.testFocusSeconds}s test break'
              : 'Start ${AppConstants.breakMinutes}-min break',
        ),
      );
    } else if (!isDone(focus)) {
      return ElevatedButton(
        key: const ValueKey('start'),
        onPressed: () => _startFocusFromScreen(focus),
        child: Text(
          AppConstants.useTestFocusDuration
              ? 'Start ${AppConstants.testFocusSeconds}s test focus'
              : 'Start ${AppConstants.focusMinutes}-minute focus',
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  bool isDone(FocusProvider focus) => focus.phase == FocusPhase.done;

  Future<void> _startFocusFromScreen(FocusProvider focus) async {
    final settingsProvider = context.read<SettingsProvider>();
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
    focus.start(label: 'Study');
  }

  Future<void> _cancelFocus(FocusProvider focus) async {
    final appBlock = context.read<AppBlockProvider>();
    focus.cancel();
    await _focusSilence.disableFocusSilence();
    await appBlock.stopBlocking();
  }

  Future<void> _claimReward(BuildContext context) async {
    final focus = context.read<FocusProvider>();
    final tokens = context.read<TokenProvider>();
    final pet = context.read<PetProvider>();
    final streak = context.read<StreakProvider>();
    final appBlock = context.read<AppBlockProvider>();

    final result = await focus.claimReward();
    await _focusSilence.disableFocusSilence();
    await appBlock.stopBlocking();
    final walletJson = result?['wallet'] as Map<String, dynamic>?;
    final petJson = result?['pet'] as Map<String, dynamic>?;
    final streakJson = result?['streak'] as Map<String, dynamic>?;
    if (walletJson != null) {
      tokens.syncWallet(Wallet.fromJson(walletJson));
    }
    if (petJson != null) {
      pet.syncPet(Pet.fromJson(petJson));
    }
    streak.syncFromJson(streakJson);
    if (!context.mounted) return;

    // Trigger celebration one more time on claim
    setState(() {
      _particleTrigger++;
      _petState = PetAnimationState.celebrating;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _petState = PetAnimationState.idle);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reward claimed! Kiki feels motivated. 🎉')),
    );
    if (result != null && context.mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.focusSummary,
        arguments: FocusSummary.fromClaimResult(
          result,
          todayFocusMinutes: focus.todayFocusMinutes,
          dailyGoalMinutes: focus.dailyGoalMinutes,
        ),
      );
    }
  }
}
