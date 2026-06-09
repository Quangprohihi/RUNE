part of '../home_screen.dart';

// ---------------------------------------------------------------------------
// Greeting header — brand + personalised welcome + streak + quick actions
// ---------------------------------------------------------------------------

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.greeting,
    required this.name,
    required this.streak,
    required this.onStreak,
    required this.onMail,
    required this.onSettings,
  });

  final String greeting;
  final String name;
  final int streak;
  final VoidCallback onStreak;
  final VoidCallback onMail;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('🦊', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'ZenZoo',
                    style: AppTextStyles.muted.copyWith(
                      color: AppColors.accentSky,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$greeting,',
                style: AppTextStyles.muted.copyWith(
                  color: AppColors.primaryBlue.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$name 👋',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StreakChip(streak: streak, onTap: onStreak),
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(
          icon: Icons.mark_email_unread_outlined,
          onTap: onMail,
          showDot: true,
        ),
        const SizedBox(width: AppSpacing.xs),
        _CircleIconButton(icon: Icons.settings_outlined, onTap: onSettings),
      ],
    );
  }
}

/// A compact, glowing streak chip. The flame gently pulses so the streak reads
/// as "alive and hot — don't let it die" without taking over the header.
class _StreakChip extends StatefulWidget {
  const _StreakChip({required this.streak, required this.onTap});

  final int streak;
  final VoidCallback onTap;

  @override
  State<_StreakChip> createState() => _StreakChipState();
}

class _StreakChipState extends State<_StreakChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.streak > 0;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB347), Color(0xFFFF7A1A)],
              ),
              borderRadius: AppRadius.brPill,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(
                          0xFFFF7A1A,
                        ).withValues(alpha: 0.28 + 0.22 * t),
                        blurRadius: 8 + 8 * t,
                        spreadRadius: 0.5 + 1.5 * t,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: active ? 1 + 0.12 * t : 1,
                  child: const Text('🔥', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.streak}',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: AppColors.primaryBlue.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          width: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: AppColors.accentSky),
              if (showDot)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A6E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resource bar — three labelled wallet pills so the numbers actually mean
// something to a new user.
// ---------------------------------------------------------------------------

class _ResourceBar extends StatelessWidget {
  const _ResourceBar({
    required this.energy,
    required this.coins,
    required this.diamonds,
  });

  final int energy;
  final int coins;
  final int diamonds;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ResourcePill(
            icon: Icons.bolt,
            iconColor: const Color(0xFFF6A53A),
            label: 'Energy',
            value: energy,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ResourcePill(
            icon: Icons.monetization_on,
            iconColor: const Color(0xFFFFB400),
            label: 'Coins',
            value: coins,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ResourcePill(
            icon: Icons.diamond,
            iconColor: AppColors.accentSky,
            label: 'Diamonds',
            value: diamonds,
          ),
        ),
      ],
    );
  }
}

class _ResourcePill extends StatelessWidget {
  const _ResourcePill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.brMd,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatValue(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.muted.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
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

  String _formatValue(int v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return '$v';
  }
}

// ---------------------------------------------------------------------------
// Habitat hero — the scene with Kiki as the emotional centre: a soft glow
// behind the fox plus a speech bubble that greets the user by name.
// ---------------------------------------------------------------------------

class _HabitatHero extends StatelessWidget {
  const _HabitatHero({
    required this.scale,
    required this.kikiAssetPath,
    required this.ownedCompanions,
    required this.message,
    required this.petName,
  });

  final double scale;
  final String kikiAssetPath;
  final List<String> ownedCompanions;
  final String message;
  final String petName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _Habitat(
          scale: scale,
          kikiAssetPath: kikiAssetPath,
          ownedCompanions: ownedCompanions,
        ),
        Positioned(
          right: 18 * scale,
          top: 6,
          child: _KikiSpeechBubble(petName: petName, message: message),
        ),
      ],
    );
  }
}

class _KikiSpeechBubble extends StatelessWidget {
  const _KikiSpeechBubble({required this.petName, required this.message});

  final String petName;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.brLg,
            boxShadow: AppShadows.raised,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                petName,
                style: AppTextStyles.muted.copyWith(
                  color: AppColors.accentTeal,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        // Tail pointing down toward Kiki. Drawn with CustomPaint (a plain
        // filled triangle) — NOT a rotated Container with a negative margin,
        // which overflowed a Clip.none Stack and rendered as a red GPU artifact.
        const Padding(
          padding: EdgeInsets.only(left: 22),
          child: CustomPaint(
            size: Size(20, 10),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.35, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Habitat widget – background scene + animated Kiki overlay
// ---------------------------------------------------------------------------

class _Habitat extends StatelessWidget {
  const _Habitat({
    required this.scale,
    required this.kikiAssetPath,
    required this.ownedCompanions,
  });

  final double scale;
  final String kikiAssetPath;
  final List<String> ownedCompanions;

  @override
  Widget build(BuildContext context) {
    final hasEagle = ownedCompanions.contains('companion_eagle');
    final hasFrog = ownedCompanions.contains('companion_frog');
    final hasGiraffe = ownedCompanions.contains('companion_giraffe');

    return SizedBox(
      height: 455,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 1 * scale,
            top: 1,
            child: Image.asset(
              'assets/images/home_habitat_figma.png',
              width: 376.205 * scale,
              height: 440.433,
              fit: BoxFit.contain,
            ),
          ),
          // Soft hero glow behind Kiki so the eye lands on the fox first.
          Positioned(
            left: 230 * scale,
            top: 96,
            child: _HeroGlow(size: 150 * scale),
          ),
          Positioned(
            left: 250.25 * scale,
            top: 94.37,
            child: _AnimatedKiki(
              assetPath: kikiAssetPath,
              width: 81.852 * scale,
              height: 102.324,
            ),
          ),
          if (hasEagle)
            Positioned(
              left: 89.76 * scale,
              top: 24,
              child: _IslandAnimalLayer(
                assetPath: 'assets/images/companion_eagle.png',
                width: 68.373 * scale,
                height: 85.457,
              ),
            ),
          if (hasFrog)
            Positioned(
              left: 175.48 * scale,
              top: 123.77,
              child: _IslandAnimalLayer(
                assetPath: 'assets/images/companion_frog.png',
                width: 62.969 * scale,
                height: 78.711,
              ),
            ),
          if (hasGiraffe)
            Positioned(
              left: 53.25 * scale,
              top: 156.73,
              child: _IslandAnimalLayer(
                assetPath: 'assets/images/companion_giraffe.png',
                width: 116.942 * scale,
                height: 146.177,
              ),
            ),
        ],
      ),
    );
  }
}

/// A breathing radial glow that sits behind Kiki to make the fox the visual
/// hero of the scene.
class _HeroGlow extends StatefulWidget {
  const _HeroGlow({required this.size});

  final double size;

  @override
  State<_HeroGlow> createState() => _HeroGlowState();
}

class _HeroGlowState extends State<_HeroGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        // A blurred BoxShadow gives the soft "hero" glow without a
        // transparent-stop gradient, which renders as artifacts under the
        // Impeller engine on Android.
        return Container(
          width: widget.size * 0.7,
          height: widget.size * 0.7,
          margin: EdgeInsets.all(widget.size * 0.15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF3C4).withValues(alpha: 0.35 + 0.15 * t),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFE9A8).withValues(alpha: 0.4 + 0.2 * t),
                blurRadius: 32 + 12 * t,
                spreadRadius: 6 + 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IslandAnimalLayer extends StatelessWidget {
  const _IslandAnimalLayer({
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Companions float a touch slower than Kiki so the scene never looks like
    // it's bobbing in lockstep.
    return _FloatingSprite(
      duration: const Duration(milliseconds: 3300),
      travel: 5,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Kiki, alive.
///
/// Idle: a gentle float-up plus a barely-there "breathing" scale, so the fox
/// reads as a living pet rather than a sticker. Tap it and Kiki does a happy
/// squash-stretch bounce while a little burst of hearts floats up — a reward
/// for poking your companion. The tap is absorbed here so it doesn't also fire
/// the island's "open Pet profile" navigation; tapping the island still does.
class _AnimatedKiki extends StatefulWidget {
  const _AnimatedKiki({
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  State<_AnimatedKiki> createState() => _AnimatedKikiState();
}

class _AnimatedKikiState extends State<_AnimatedKiki>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _react;
  late final Animation<double> _bounce;
  final List<_KikiHeart> _hearts = [];

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.93).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.0).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 44,
      ),
    ]).animate(_react);
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  void _onTap() {
    final rnd = math.Random();
    _hearts
      ..clear()
      ..addAll(
        List.generate(5, (i) {
          return _KikiHeart(
            dx: (rnd.nextDouble() - 0.5) * widget.width * 0.95,
            rise: 44 + rnd.nextDouble() * 36,
            delay: i * 0.06,
            scale: 0.7 + rnd.nextDouble() * 0.5,
          );
        }),
      );
    _react.forward(from: 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _react,
              builder: (context, _) {
                if (_react.isDismissed) return const SizedBox.shrink();
                return Stack(
                  clipBehavior: Clip.none,
                  children: [for (final h in _hearts) _buildHeart(h)],
                );
              },
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_idle, _react]),
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_idle.value);
                final bounceScale = _react.isAnimating ? _bounce.value : 1.0;
                return Transform.translate(
                  offset: Offset(0, -4 * t),
                  child: Transform.scale(
                    scale: (1 + 0.02 * t) * bounceScale,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                widget.assetPath,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeart(_KikiHeart h) {
    final p = (_react.value - h.delay).clamp(0.0, 1.0);
    if (p <= 0) return const SizedBox.shrink();
    final opacity = p < 0.2 ? p / 0.2 : (1 - (p - 0.2) / 0.8).clamp(0.0, 1.0);
    return Positioned(
      left: widget.width / 2 + h.dx - 9,
      top: widget.height * 0.08 - h.rise * p,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: h.scale,
          child: const Icon(
            Icons.favorite,
            color: Color(0xFFFF6B8A),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _KikiHeart {
  _KikiHeart({
    required this.dx,
    required this.rise,
    required this.delay,
    required this.scale,
  });

  final double dx;
  final double rise;
  final double delay;
  final double scale;
}

/// Reusable idle-float wrapper: bobs [child] up by [travel] px and optionally
/// "breathes" by [breathe] scale, looping forever with an ease-in-out feel.
/// Uses only `Transform`, so it never disturbs the surrounding layout.
class _FloatingSprite extends StatefulWidget {
  const _FloatingSprite({
    required this.child,
    required this.duration,
    this.travel = 4,
  });

  final Widget child;
  final Duration duration;
  final double travel;

  @override
  State<_FloatingSprite> createState() => _FloatingSpriteState();
}

class _FloatingSpriteState extends State<_FloatingSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -widget.travel * t),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Primary focus CTA — the one clear thing to do on Home.
// ---------------------------------------------------------------------------

class _PrimaryFocusButton extends StatefulWidget {
  const _PrimaryFocusButton({required this.focus, required this.onTap});

  final FocusProvider focus;
  final VoidCallback onTap;

  @override
  State<_PrimaryFocusButton> createState() => _PrimaryFocusButtonState();
}

class _PrimaryFocusButtonState extends State<_PrimaryFocusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focus = widget.focus;
    final running = focus.isRunning;
    final title = running ? 'Resume your session' : 'Start a focus session';
    final subtitle = running
        ? '${focus.formattedRemaining} left · stay with Kiki'
        : 'Pick a goal & timer · earn rewards';
    final icon = running ? Icons.play_arrow_rounded : Icons.bolt_rounded;

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brXl,
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF68C7BF), Color(0xFF3A9BBE)],
            ),
            borderRadius: AppRadius.brXl,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.muted.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Idle → gently pulse (scale + glow) to invite the first tap. Running →
    // calm, no pulse.
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = running ? 0.0 : Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scale: 1 + 0.02 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.brXl,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentSky.withValues(alpha: 0.30 + 0.24 * t),
                  blurRadius: 18 + 14 * t,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Daily goal progress
// ---------------------------------------------------------------------------

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.focus});

  final FocusProvider focus;

  @override
  Widget build(BuildContext context) {
    final percent = (focus.dailyGoalProgress * 100).round();
    final message = focus.dailyGoalCompleted
        ? 'Goal complete! Kiki is proud of you.'
        : '${focus.dailyGoalRemainingMinutes} min left to complete today.';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7EFE7), width: 1.2),
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 18,
                color: AppColors.accentTeal,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Today's Goal",
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: focus.dailyGoalProgress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                minHeight: 8,
                value: value,
                backgroundColor: const Color(0xFFEAF7FF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentTeal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${focus.todayFocusMinutes} / ${focus.dailyGoalMinutes} min focused · $message',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.muted.copyWith(
              color: const Color(0xFF4367A3),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.onFocus,
    required this.onShop,
    required this.onTasks,
    required this.onPro,
  });

  final VoidCallback onFocus;
  final VoidCallback onShop;
  final VoidCallback onTasks;
  final VoidCallback onPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFF9CD0C8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.timer_outlined,
            label: 'Set timer',
            onTap: onFocus,
          ),
          _NavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Shop',
            onTap: onShop,
          ),
          _NavItem(icon: Icons.task_alt, label: 'Tasks', onTap: onTasks),
          _NavItem(
            icon: Icons.local_offer_outlined,
            label: 'Go Pro',
            onTap: onPro,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 34),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.muted.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings popover menu
// ---------------------------------------------------------------------------

class _SettingsMenuCard extends StatelessWidget {
  const _SettingsMenuCard({required this.onSetting, required this.onLogin});

  final VoidCallback onSetting;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SettingsMenuButton(label: 'Setting', onTap: onSetting),
          const SizedBox(height: 8),
          _SettingsMenuButton(label: 'Log in', onTap: onLogin),
          const SizedBox(height: 8),
          _SettingsMenuButton(label: 'Sign in', onTap: onLogin),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _SettingsSoundButton(icon: Icons.music_note),
              SizedBox(width: 10),
              _SettingsSoundButton(icon: Icons.volume_up),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuButton extends StatelessWidget {
  const _SettingsMenuButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF8AD8D0),
          foregroundColor: AppColors.primaryBlue,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: AppTextStyles.muted.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SettingsSoundButton extends StatelessWidget {
  const _SettingsSoundButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFF8AD8D0),
      child: Icon(icon, color: AppColors.primaryBlue, size: 16),
    );
  }
}
