import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';

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

  // --- Battery-saver dimming ---
  // While focusing/resting there's no reason to keep the screen bright: the
  // user is looking at their books, not the phone. We lower the *window*
  // brightness (no permission, auto-restores) to save battery and remove the
  // phone as a temptation. Tap the screen to "peek" the time, then it re-dims.
  static const double _dimLevel = 0.12;
  bool _dimmed = false;
  Timer? _peekTimer;

  // Token penalty when the user gives up a focus session early. Small enough to
  // not wreck the economy, big enough to make "Give up" feel like it costs
  // something — the way Forest's withering tree does.
  static const int _giveUpPenalty = 10;

  // Live "Focus Guard blocked N distractions" counter, polled from native.
  Timer? _guardPollTimer;

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

    // Safety net: if the user backgrounds the app, restore system brightness.
    ScreenBrightness().setAutoReset(true).catchError((_) {});
  }

  void _startGuardPoll() {
    _guardPollTimer?.cancel();
    final appBlock = context.read<AppBlockProvider>();
    if (!appBlock.blockingEnabled) return;
    unawaited(appBlock.refreshBlockedAttempts());
    _guardPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      unawaited(context.read<AppBlockProvider>().refreshBlockedAttempts());
    });
  }

  void _stopGuardPoll() {
    _guardPollTimer?.cancel();
    _guardPollTimer = null;
  }

  @override
  void dispose() {
    _phaseColorController.dispose();
    _glowController.dispose();
    _peekTimer?.cancel();
    _guardPollTimer?.cancel();
    unawaited(ScreenBrightness().resetApplicationScreenBrightness().catchError(
      (_) {},
    ));
    super.dispose();
  }

  /// Dim (or restore) the window brightness for the battery-saver focus mode.
  Future<void> _setDimmed(bool dim) async {
    if (_dimmed == dim) return;
    _dimmed = dim;
    _peekTimer?.cancel();
    try {
      if (dim) {
        await ScreenBrightness().setApplicationScreenBrightness(_dimLevel);
      } else {
        await ScreenBrightness().resetApplicationScreenBrightness();
      }
    } catch (_) {
      // Brightness control is best-effort (e.g. unsupported on some devices).
    }
  }

  /// Briefly brighten so the user can glance at the time, then re-dim.
  Future<void> _peek() async {
    if (!_dimmed) return;
    _peekTimer?.cancel();
    try {
      await ScreenBrightness().setApplicationScreenBrightness(0.55);
    } catch (_) {}
    _peekTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted || !_dimmed) return;
      try {
        await ScreenBrightness().setApplicationScreenBrightness(_dimLevel);
      } catch (_) {}
    });
  }

  void _handlePhaseChange(FocusPhase newPhase) {
    if (newPhase == _lastPhase) return;
    _lastPhase = newPhase;

    // Battery-saver: dim while focusing/resting, restore for the bright
    // celebration on done and when idle.
    _setDimmed(
      newPhase == FocusPhase.focusing || newPhase == FocusPhase.breakTime,
    );

    switch (newPhase) {
      case FocusPhase.focusing:
        _phaseColorController.reverse(); // teal
        _startGuardPoll();
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
        _stopGuardPoll();
        unawaited(context.read<AppBlockProvider>().stopBlocking());
        unawaited(_focusSilence.disableFocusSilence());
        _phaseColorController.reverse();
        setState(() {
          _currentPhrase = _donePhrases[_phraseIndex % _donePhrases.length];
          _petState = PetAnimationState.celebrating;
          _particleTrigger++;
        });

      case FocusPhase.idle:
        _stopGuardPoll();
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

    // Immersive, battery-saving "Deep Focus" mode while a session or break is
    // running. The bright celebratory/claim layout below is kept for done/idle.
    if (focus.isRunning) {
      return Scaffold(backgroundColor: Colors.black, body: _buildDeepFocus(focus, pet));
    }

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
                        'YOUR PROGRESS',
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

  Widget _buildDeepFocus(FocusProvider focus, Pet pet) {
    final isBreak = focus.phase == FocusPhase.breakTime;
    final accent = isBreak ? const Color(0xFFF6A53A) : AppColors.accentTeal;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _peek,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isBreak
                ? const [Color(0xFF241A10), Color(0xFF12100A)]
                : const [Color(0xFF0C1C28), Color(0xFF070E14)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: Colors.white54),
                  ),
                ),
                const Spacer(),
                Text(
                  isBreak ? 'BREAK' : 'DEEP FOCUS',
                  style: AppTextStyles.muted.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  focus.label,
                  style: AppTextStyles.label.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: focus.progress),
                          duration: const Duration(milliseconds: 400),
                          builder: (context, value, _) =>
                              CircularProgressIndicator(
                                value: value,
                                strokeWidth: 7,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accent,
                                ),
                              ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            focus.formattedRemaining,
                            style: AppTextStyles.heading.copyWith(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            isBreak ? 'resting' : 'remaining',
                            style: AppTextStyles.muted.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    pet.skinAssetPath,
                    width: 84,
                    height: 84,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentPhrase,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                if (!isBreak) _buildGuardStatus(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.brightness_low_rounded,
                      color: Colors.white30,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Screen dimmed to save battery · tap to peek',
                        style: AppTextStyles.muted.copyWith(
                          color: Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (!isBreak)
                  TextButton(
                    onPressed: () => _cancelFocus(focus),
                    child: Text(
                      'Give up',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Text(
                    'Break running…',
                    style: AppTextStyles.muted.copyWith(color: Colors.white38),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Live "you're protected" panel inside Deep Focus. Surfaces the silent
  /// background protections (DND + app blocking) so the user can see the app is
  /// actively working for them — and celebrates each blocked distraction.
  Widget _buildGuardStatus() {
    final settings = context.watch<SettingsProvider>().settings;
    final appBlock = context.watch<AppBlockProvider>();
    final dndOn = settings.silenceNotificationsDuringFocus;
    final guardOn = appBlock.blockingEnabled;
    final blocked = appBlock.blockedAttempts;

    if (!dndOn && !guardOn) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dndOn)
                const _GuardChip(
                  icon: Icons.notifications_off_rounded,
                  label: 'Notifications off',
                ),
              if (dndOn && guardOn) const SizedBox(width: 8),
              if (guardOn)
                const _GuardChip(
                  icon: Icons.shield_rounded,
                  label: 'Apps blocked',
                ),
            ],
          ),
          if (guardOn && blocked > 0) ...[
            const SizedBox(height: 10),
            Text(
              blocked == 1
                  ? 'Kiki blocked 1 distraction for you 🛡️'
                  : 'Kiki blocked $blocked distractions for you 🛡️',
              style: AppTextStyles.muted.copyWith(
                color: AppColors.accentTeal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
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
    // Giving up has weight: confirm with a sad Kiki, then apply a small token
    // penalty so quitting actually costs something (Forest-style stakes).
    final tokens = context.read<TokenProvider>();
    final hasTokens = tokens.tokens > 0;
    final penalty = hasTokens ? _giveUpPenalty.clamp(0, tokens.tokens) : 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GiveUpDialog(
        penalty: penalty,
        petImagePath: context.read<PetProvider>().pet.skinAssetPath,
      ),
    );
    if (confirmed != true || !mounted) return;

    final appBlock = context.read<AppBlockProvider>();
    focus.cancel();
    await _focusSilence.disableFocusSilence();
    await appBlock.stopBlocking();
    if (penalty > 0) {
      await tokens.spend(penalty);
    }
    if (!mounted) return;
    setState(() => _petState = PetAnimationState.idle);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          penalty > 0
              ? 'Focus ended early. Kiki lost $penalty tokens of trust. 😔'
              : 'Focus ended early. Kiki is a little sad. 😔',
        ),
      ),
    );
    Navigator.of(context).pop();
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

/// A small "this protection is active" pill shown in the Deep Focus status row.
class _GuardChip extends StatelessWidget {
  const _GuardChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.muted.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation shown when the user taps "Give up" mid-session. Gives the act
/// emotional weight (a sad Kiki) and states the token cost up front so quitting
/// is a real decision, not a reflex.
class _GiveUpDialog extends StatelessWidget {
  const _GiveUpDialog({required this.penalty, required this.petImagePath});

  final int penalty;
  final String petImagePath;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.9,
              child: Image.asset(
                petImagePath,
                width: 88,
                height: 88,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Give up on Kiki?',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              penalty > 0
                  ? "Kiki has been focusing with you. Quitting now will cost $penalty tokens and disappoint Kiki."
                  : 'Kiki has been focusing with you. Quitting now will disappoint Kiki.',
              textAlign: TextAlign.center,
              style: AppTextStyles.muted.copyWith(height: 1.4),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keep focusing'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Give up'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
