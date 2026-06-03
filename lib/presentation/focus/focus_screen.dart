import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/pet.dart';
import '../../models/focus_summary.dart';
import '../../models/wallet.dart';
import '../../providers/app_block_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/floating_particles.dart';
import '../widgets/pet_animated_widget.dart';

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
        _phaseColorController.reverse();
        setState(() {
          _currentPhrase = _donePhrases[_phraseIndex % _donePhrases.length];
          _petState = PetAnimationState.celebrating;
          _particleTrigger++;
        });

      case FocusPhase.idle:
        unawaited(context.read<AppBlockProvider>().stopBlocking());
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
                      _FocusSessionSummary(focus: focus),
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
                        child: _TimerCircle(
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
                          _PartnerPanel(
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
                      _ClaimPanel(
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
        onPressed: () => focus.start(label: 'Study'),
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

  Future<void> _cancelFocus(FocusProvider focus) async {
    focus.cancel();
    await context.read<AppBlockProvider>().stopBlocking();
  }

  Future<void> _claimReward(BuildContext context) async {
    final focus = context.read<FocusProvider>();
    final tokens = context.read<TokenProvider>();
    final pet = context.read<PetProvider>();
    final streak = context.read<StreakProvider>();
    final appBlock = context.read<AppBlockProvider>();

    final result = await focus.claimReward();
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

class _FocusSessionSummary extends StatelessWidget {
  const _FocusSessionSummary({required this.focus});

  final FocusProvider focus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              focus.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: const Color(0xFF1D293D),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            focus.pomodoroLabel,
            style: AppTextStyles.muted.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Partner panel – animated Kiki + dynamic phrase
// ---------------------------------------------------------------------------

class _PartnerPanel extends StatelessWidget {
  const _PartnerPanel({
    required this.petName,
    required this.imagePath,
    required this.phrase,
    required this.petState,
  });

  final String petName;
  final String imagePath;
  final String phrase;
  final PetAnimationState petState;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card background
          Positioned(
            left: 32,
            right: 0,
            top: 14,
            child: Container(
              height: 60,
              padding: const EdgeInsets.only(left: 60, right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.accentSky),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Partner',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 20,
                      color: AppColors.accentSky,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      phrase,
                      key: ValueKey(phrase),
                      style: AppTextStyles.muted.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animated Kiki avatar
          Positioned(
            left: 0,
            top: 0,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: PetAnimatedWidget(
                imagePath: imagePath,
                width: 72,
                state: petState,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timer circle with animated progress and colour transition
// ---------------------------------------------------------------------------

class _TimerCircle extends StatelessWidget {
  const _TimerCircle({
    required this.progress,
    required this.text,
    required this.subtitle,
    required this.ringColorAnim,
  });

  final double progress;
  final String text;
  final String subtitle;
  final Animation<Color?> ringColorAnim;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated progress ring
          SizedBox(
            height: 200,
            width: 200,
            child: AnimatedBuilder(
              animation: ringColorAnim,
              builder: (context, _) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: progress <= 0 ? 0.78 : progress.clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 16,
                      backgroundColor: Colors.white,
                      color: ringColorAnim.value ?? const Color(0xFF41B8D5),
                    );
                  },
                );
              },
            ),
          ),

          // Inner circle with text
          Container(
            height: 152,
            width: 152,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 64,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: FittedBox(
                      key: ValueKey(text),
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextStyles.heading.copyWith(
                          fontSize: text.contains(':') ? 42 : 54,
                          height: 1,
                          color: const Color(0xFF6CE5E8),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFF41B8D5),
                    fontSize: 22,
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

// ---------------------------------------------------------------------------
// Claim panel
// ---------------------------------------------------------------------------

class _ClaimPanel extends StatelessWidget {
  const _ClaimPanel({
    required this.canClaim,
    required this.rewardTokens,
    required this.rewardExp,
    required this.onClaim,
  });

  final bool canClaim;
  final int rewardTokens;
  final int rewardExp;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(16, 8),
          child: Text(
            'Claim',
            style: AppTextStyles.heading.copyWith(
              fontSize: 24,
              color: AppColors.accentSky,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: canClaim ? AppColors.success : AppColors.primaryBlue,
              width: canClaim ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: canClaim
                ? const [
                    BoxShadow(
                      color: Color(0x3342A779),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    '+$rewardTokens ⚡',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    '$rewardExp EXP',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'after finish',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryBlue,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedScale(
                scale: canClaim ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: canClaim ? onClaim : null,
                  child: Text(
                    canClaim ? 'Claim reward 🎉' : 'Finish focus to claim',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
