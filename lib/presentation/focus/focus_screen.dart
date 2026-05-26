import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/focus_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    final pet = context.watch<PetProvider>().pet;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDone = focus.phase == FocusPhase.done;

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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'YOUR PROCESS',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 24,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: _TimerCircle(
                          progress: focus.progress,
                          text: focus.phase == FocusPhase.idle
                              ? AppConstants.useTestFocusDuration
                                    ? '${AppConstants.testFocusSeconds}s'
                                    : '${AppConstants.focusMinutes}’'
                              : focus.formattedRemaining,
                          subtitle: focus.phase == FocusPhase.breakTime
                              ? 'break'
                              : 'left',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PartnerPanel(petName: pet.name),
                      const SizedBox(height: 24),
                      _ClaimPanel(
                        canClaim: isDone,
                        onClaim: () => _claimReward(context),
                      ),
                      const SizedBox(height: 18),
                      if (focus.phase == FocusPhase.breakTime)
                        ElevatedButton(
                          onPressed: focus.start,
                          child: const Text('Continue focus'),
                        )
                      else if (focus.phase == FocusPhase.focusing)
                        OutlinedButton(
                          onPressed: focus.cancel,
                          child: const Text('Cancel focus'),
                        )
                      else if (!isDone)
                        ElevatedButton(
                          onPressed: () => focus.start(label: 'Study'),
                          child: Text(
                            AppConstants.useTestFocusDuration
                                ? 'Start 3-second test focus'
                                : 'Start ${AppConstants.focusMinutes}-minute focus',
                          ),
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

  Future<void> _claimReward(BuildContext context) async {
    final focus = context.read<FocusProvider>();
    final tokens = context.read<TokenProvider>();
    final pet = context.read<PetProvider>();
    final streak = context.read<StreakProvider>();

    await tokens.add(
      AppConstants.rewardTokensPerBlock + AppConstants.focusMinutes,
    );
    await pet.addFocusReward(
      exp: AppConstants.rewardExpPerBlock,
      minutes: AppConstants.focusMinutes,
    );
    await streak.markFocusedToday();
    await focus.claimReward();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reward claimed! Kiki feels motivated.')),
    );
  }
}

class _PartnerPanel extends StatelessWidget {
  const _PartnerPanel({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 32,
            right: 0,
            top: 14,
            child: Container(
              height: 40,
              padding: const EdgeInsets.only(left: 60, right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.accentSky),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    'Partner',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 24,
                      color: AppColors.accentSky,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/fox.png',
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            left: 88,
            right: 18,
            top: 38,
            child: Text(
              'Just a little more, $petName is proud of you!',
              style: AppTextStyles.muted.copyWith(color: AppColors.primaryBlue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  const _TimerCircle({
    required this.progress,
    required this.text,
    required this.subtitle,
  });

  final double progress;
  final String text;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 190,
            width: 190,
            child: CircularProgressIndicator(
              value: progress <= 0 ? 0.78 : progress.clamp(0, 1),
              strokeWidth: 16,
              backgroundColor: Colors.white,
              color: const Color(0xFF41B8D5),
            ),
          ),
          Container(
            height: 142,
            width: 142,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 118,
                  height: 62,
                  child: FittedBox(
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

class _ClaimPanel extends StatelessWidget {
  const _ClaimPanel({required this.canClaim, required this.onClaim});

  final bool canClaim;
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primaryBlue),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    '20 ⚡',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    '50 EXP',
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
              ElevatedButton(
                onPressed: canClaim ? onClaim : null,
                child: Text(
                  canClaim ? 'Claim reward' : 'Finish focus to claim',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
