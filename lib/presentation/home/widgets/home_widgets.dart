part of '../home_screen.dart';

// ---------------------------------------------------------------------------
// Asset paths for the new island scene. Drop these files into assets/images/
// (the folder is already declared in pubspec). Until they exist, each widget
// falls back gracefully so the app still runs.
//   • cloud.jpg        → sky background
//   • island_main.png  → the big buildable island
//   • shop_island.png  → the small floating shop island
// ---------------------------------------------------------------------------

const String _kCloudAsset = 'assets/images/cloud.jpg';
const String _kIslandAsset = 'assets/images/island_main.png';
const String _kShopIslandAsset = 'assets/images/shop_island.png';
const String _kIslandFallbackAsset = 'assets/images/home_habitat_figma.png';

/// Logical aspect ratio (w / h) of the island artwork (≈ 2000×1251).
const double _kIslandAspect = 1.6;

/// Warm ambient tone sampled from island_main.png's sunlight. Washed lightly
/// over every pet sprite so they read as lit by the same sun as the island.
const Color _kSceneAmbient = Color(0xFFFFD9A0);

/// Native horizontal facing of a sprite asset, used to mirror pets so they
/// look toward the island's centre instead of off the edge of the world.
enum _Facing { left, right, front }

_Facing _nativeFacing(String assetPath) {
  if (assetPath.contains('giraffe')) return _Facing.left;
  if (assetPath.contains('eagle')) return _Facing.right;
  return _Facing.front; // fox skins and the frog are drawn facing the camera
}

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
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$greeting, $name 👋',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 20,
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
        color: Colors.white.withValues(alpha: 0.94),
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
// Cloud background — static sky photo + procedural clouds drifting across it.
// ---------------------------------------------------------------------------

class _CloudBackground extends StatelessWidget {
  const _CloudBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _kCloudAsset,
          fit: BoxFit.cover,
          // Until cloud.jpg is added, paint a soft pastel sky gradient.
          errorBuilder: (context, error, stack) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFBFE8E6),
                  Color(0xFFDDF5EC),
                  Color(0xFFF4F7DA),
                ],
              ),
            ),
          ),
        ),
        const _CloudDriftLayer(),
      ],
    );
  }
}

/// A few soft clouds drifting horizontally at different heights and speeds.
class _CloudDriftLayer extends StatelessWidget {
  const _CloudDriftLayer();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _DriftingCloud(
            topFraction: 0.08,
            scale: 1.1,
            durationMs: 38000,
            startFraction: 0.0,
            opacity: 0.85,
          ),
          _DriftingCloud(
            topFraction: 0.20,
            scale: 0.7,
            durationMs: 52000,
            startFraction: 0.45,
            opacity: 0.7,
          ),
          _DriftingCloud(
            topFraction: 0.42,
            scale: 0.9,
            durationMs: 46000,
            startFraction: 0.7,
            opacity: 0.6,
          ),
          _DriftingCloud(
            topFraction: 0.62,
            scale: 0.55,
            durationMs: 60000,
            startFraction: 0.2,
            opacity: 0.55,
          ),
        ],
      ),
    );
  }
}

class _DriftingCloud extends StatefulWidget {
  const _DriftingCloud({
    required this.topFraction,
    required this.scale,
    required this.durationMs,
    required this.startFraction,
    required this.opacity,
  });

  /// Vertical position as a fraction of the available height.
  final double topFraction;
  final double scale;
  final int durationMs;

  /// Where in its travel the cloud starts (0..1) so they don't move in lockstep.
  final double startFraction;
  final double opacity;

  @override
  State<_DriftingCloud> createState() => _DriftingCloudState();
}

class _DriftingCloudState extends State<_DriftingCloud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat();
    _c.value = widget.startFraction;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const cloudWidth = 150.0;
        final travel = w + cloudWidth * 2;
        // Translate within the (expanded) full-size box rather than using a
        // Positioned, which is only valid as a direct child of a Stack.
        return AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final dx = -cloudWidth + _c.value * travel;
            return Transform.translate(
              offset: Offset(dx, h * widget.topFraction),
              child: Align(alignment: Alignment.topLeft, child: child),
            );
          },
          child: Opacity(
            opacity: widget.opacity,
            child: CustomPaint(
              size: Size(cloudWidth * widget.scale, 60 * widget.scale),
              painter: const _CloudPuffPainter(),
            ),
          ),
        );
      },
    );
  }
}

/// Draws a soft, blurred cloud from a few overlapping white circles.
class _CloudPuffPainter extends CustomPainter {
  const _CloudPuffPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.30, h * 0.62), h * 0.42, paint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.48), h * 0.55, paint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.60), h * 0.46, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.66, w * 0.64, h * 0.30),
        Radius.circular(h * 0.2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudPuffPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Island scene — the big buildable island with up to 4 tappable pets plus the
// floating shop island. Pets are positioned by fractional coordinates on the
// island rect so the layout scales with any screen size.
// ---------------------------------------------------------------------------

class _IslandScene extends StatelessWidget {
  const _IslandScene({
    required this.pets,
    required this.activePetId,
    required this.message,
    required this.onPetTap,
    required this.onShopTap,
  });

  final List<Pet> pets;
  final String activePetId;
  final String message;
  final ValueChanged<String> onPetTap;
  final VoidCallback onShopTap;

  /// Ground anchor (bottom-centre of each sprite) as a fraction of the island
  /// artwork rect, hand-placed on the walkable zones of island_main.png.
  /// Tweak these four points to reposition pets on the island.
  static const List<Offset> _slots = [
    Offset(0.45, 0.58), // active pet — central green clearing
    Offset(0.26, 0.48), // left — green beside the ice ponds
    Offset(0.70, 0.50), // right — on the dark lava field
    Offset(0.57, 0.66), // front — green beside the little volcano
  ];

  /// Slot indices for [count] pets sorted by ground-anchor depth, so the Stack
  /// paints far pets first and near pets last.
  static List<int> _drawOrder(int count) {
    final order = [for (var i = 0; i < count && i < _slots.length; i++) i]
      ..sort((a, b) => _slots[a].dy.compareTo(_slots[b].dy));
    return order;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = Size(constraints.maxWidth, constraints.maxHeight);

        // Fit the island within the band at base zoom, leaving headroom around
        // it for sky, the floating shop island and the speech bubble.
        var islandW = available.width * 0.98;
        var islandH = islandW / _kIslandAspect;
        final maxH = available.height * 0.86;
        if (islandH > maxH) {
          islandH = maxH;
          islandW = islandH * _kIslandAspect;
        }
        final islandLeft = (available.width - islandW) / 2;
        // Bias the island slightly below centre: fills the lower headroom so it
        // feels grounded rather than floating dead-centre, while leaving room
        // above for the shop island + speech bubble (and for pinch/pan).
        final islandTop =
            (available.height - islandH) / 2 + available.height * 0.05;

        // Pets are the emotional hero of Home, so size them large enough to
        // read at the default (un-zoomed) view; pinch-zoom still lets the user
        // get even closer.
        final petW = islandW * 0.185;
        final petH = petW * 1.22;

        // Depth scale: the island is painted from a ~35° three-quarter view,
        // so pets lower on the artwork (nearer the camera) must render larger
        // than pets higher up (farther away). Obeying the painting's own
        // perspective is what makes sprites sit "in" the scene, not on it.
        double depthScale(int slot) {
          const nearDy = 0.66, farDy = 0.48;
          final t = ((_slots[slot].dy - farDy) / (nearDy - farDy)).clamp(
            0.0,
            1.0,
          );
          return 0.82 + (1.06 - 0.82) * t;
        }

        List<Widget> petAt(int slot, Pet pet) {
          final anchor = _slots[slot];
          final scale = depthScale(slot);
          final w = petW * scale;
          final h = petH * scale;
          final groundX = islandLeft + anchor.dx * islandW;
          final groundY = islandTop + anchor.dy * islandH;
          final isActive = pet.id == activePetId;
          // Turn pets toward the island's centre so nobody stares off the
          // edge of the world.
          final facing = _nativeFacing(pet.skinAssetPath);
          final flipX =
              (facing == _Facing.left && anchor.dx < 0.5) ||
              (facing == _Facing.right && anchor.dx > 0.5);
          // The island is painted with its sun high on the left, so every
          // contact shadow falls slightly to the right of its pet.
          final sunOffset = w * 0.05;
          // Soft elliptical contact shadow at the feet — the single strongest
          // cue that the sprite is standing on the island instead of floating
          // in front of it.
          final shadowW = w * 0.72;
          final shadowH = w * 0.20;
          return [
            // Warm pool of light on the grass under the active pet — the
            // ground-plane version of a hero highlight. (A halo floating
            // behind the sprite would just re-introduce the sticker look.)
            if (isActive)
              Positioned(
                left: groundX - w * 0.75,
                top: groundY - w * 0.23,
                width: w * 1.5,
                height: w * 0.42,
                child: const _GroundOval(color: Color(0x66FFE9A8)),
              ),
            Positioned(
              left: groundX - shadowW / 2 + sunOffset,
              top: groundY - shadowH * 0.62,
              width: shadowW,
              height: shadowH,
              child: const _GroundOval(color: Color(0x4D000000)),
            ),
            Positioned(
              left: groundX - w / 2,
              top: groundY - h,
              width: w,
              height: h,
              child: _TappablePet(
                pet: pet,
                isActive: isActive,
                flipX: flipX,
                breatheMs: 2000 + slot * 180,
                onTap: () => onPetTap(pet.id),
              ),
            ),
          ];
        }

        final shopW = islandW * 0.26;
        final shopH = shopW;
        // Pin to the top-right with an 8px margin, and keep at least 12px of
        // headroom so the bobbing (_FloatingSprite) never clips off the top.
        final shopLeft = (available.width - shopW - 8)
            .clamp(0.0, available.width - shopW)
            .toDouble();
        final shopTop = (islandTop - shopH * 0.10)
            .clamp(12.0, available.height - shopH)
            .toDouble();

        // Speech bubble floats just above the active (front-centre) pet.
        final activeTop =
            islandTop + _slots[0].dy * islandH - petH * depthScale(0);
        final bubbleLeft = islandLeft + _slots[0].dx * islandW - 24;
        final bubbleTop = (activeTop - 62)
            .clamp(0.0, available.height)
            .toDouble();

        final scene = SizedBox(
          width: available.width,
          height: available.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // --- Island artwork (falls back to the legacy habitat art) ---
              Positioned(
                left: islandLeft,
                top: islandTop,
                width: islandW,
                height: islandH,
                child: Image.asset(
                  _kIslandAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => Image.asset(
                    _kIslandFallbackAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        const _IslandPlaceholder(),
                  ),
                ),
              ),

              // --- Pets, painted back-to-front (painter's algorithm) so a
              // nearer pet correctly overlaps a farther one. The active pet's
              // warm ground pad is emitted inside petAt. ---
              for (final i in _drawOrder(pets.length)) ...petAt(i, pets[i]),

              // --- Grass occluder: repaints the island's own pixels over the
              // frontmost pet's toes, so the environment visibly overlaps the
              // sprite — the strongest "it lives inside the scene" cue. The
              // patch samples the exact spot it covers, so its edges are
              // invisible; only the overlap across the pet shows. ---
              if (pets.isNotEmpty)
                _grassOccluder(
                  frontSlot: _drawOrder(pets.length).last,
                  islandLeft: islandLeft,
                  islandTop: islandTop,
                  islandW: islandW,
                  islandH: islandH,
                  petW: petW,
                  depthScale: depthScale,
                ),

              // --- Speech bubble for the active pet ---
              Positioned(
                left: bubbleLeft,
                top: bubbleTop,
                child: _KikiSpeechBubble(
                  petName: pets.isNotEmpty ? pets.first.name : 'Kiki',
                  message: message,
                ),
              ),

              // --- Floating shop island ---
              Positioned(
                left: shopLeft,
                top: shopTop,
                width: shopW,
                height: shopH,
                child: _ShopIsland(onTap: onShopTap),
              ),
            ],
          ),
        );

        // Pinch-to-zoom and drag-to-pan the whole island as one unit, so the
        // pets and the shop stay locked to their spots on the island.
        return InteractiveViewer(
          minScale: 0.9,
          maxScale: 3.5,
          boundaryMargin: const EdgeInsets.symmetric(
            horizontal: 48,
            vertical: 32,
          ),
          child: scene,
        );
      },
    );
  }

  /// Repaints a thin strip of the island's own artwork over the frontmost
  /// pet's toes. Because the strip shows exactly the pixels it sits on, its
  /// edges are invisible — it only becomes visible where it overlaps the pet,
  /// reading as grass growing in front of the feet.
  Widget _grassOccluder({
    required int frontSlot,
    required double islandLeft,
    required double islandTop,
    required double islandW,
    required double islandH,
    required double petW,
    required double Function(int) depthScale,
  }) {
    final anchor = _slots[frontSlot];
    final w = petW * depthScale(frontSlot);
    final patchW = w * 0.95;
    final patchH = w * 0.12;
    final left = islandLeft + anchor.dx * islandW - patchW / 2;
    final top = islandTop + anchor.dy * islandH - patchH * 0.25;
    final ax = islandW - patchW <= 0
        ? 0.0
        : (left - islandLeft) / (islandW - patchW);
    final ay = islandH - patchH <= 0
        ? 0.0
        : (top - islandTop) / (islandH - patchH);
    return Positioned(
      left: left,
      top: top,
      width: patchW,
      height: patchH,
      child: IgnorePointer(
        child: ClipRect(
          child: Align(
            alignment: FractionalOffset(ax, ay),
            widthFactor: patchW / islandW,
            heightFactor: patchH / islandH,
            child: SizedBox(
              width: islandW,
              height: islandH,
              child: Image.asset(
                _kIslandAsset,
                fit: BoxFit.contain,
                // If the main art is missing, the island itself fell back to
                // different artwork — a mismatched patch would show as a hard
                // seam, so render nothing instead.
                errorBuilder: (context, error, stack) => const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback island when neither the new art nor the legacy art is available.
class _IslandPlaceholder extends StatelessWidget {
  const _IslandPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.9,
        heightFactor: 0.7,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7FD17A), Color(0xFF4Fae73)],
            ),
            borderRadius: BorderRadius.circular(180),
            boxShadow: AppShadows.raised,
          ),
          alignment: Alignment.center,
          child: Text(
            'Add island_main.png',
            style: AppTextStyles.muted.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// A pet on the island: gently floats, shows a small nameplate, and opens its
/// status profile when tapped.
class _TappablePet extends StatelessWidget {
  const _TappablePet({
    required this.pet,
    required this.isActive,
    required this.onTap,
    this.flipX = false,
    this.breatheMs = 2200,
  });

  final Pet pet;
  final bool isActive;
  final VoidCallback onTap;

  /// Mirror the sprite horizontally (to face the island's centre).
  final bool flipX;

  /// Breathing period — varied per slot so the pets don't inhale in lockstep.
  final int breatheMs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _BreathingSprite(
        duration: Duration(milliseconds: breatheMs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Transform.flip(
                flipX: flipX,
                // Fake contact occlusion: multiply the feet zone toward a
                // darker ground tone — real creatures are never studio-bright
                // from head to toe, the contact area always picks up shade.
                child: ShaderMask(
                  blendMode: BlendMode.modulate,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFFCDC3B2), Colors.white],
                    stops: [0.0, 0.32],
                  ).createShader(rect),
                  // Wash the sprite with the island's warm ambient light so
                  // the flat vector colours share the painted scene's palette
                  // (srcATop tints only the sprite's pixels, not the alpha).
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _kSceneAmbient.withValues(alpha: 0.12),
                      BlendMode.srcATop,
                    ),
                    child: Image.asset(
                      pet.skinAssetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) =>
                          const Icon(Icons.pets, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            // Only the active pet shows a nameplate — keeps the scene clean and
            // avoids cramped, truncated labels stacking in the centre. Tapping
            // any pet opens its profile (where its full name lives).
            if (isActive) ...[
              const SizedBox(height: 2),
              _PetNamePlate(name: pet.name, level: pet.level),
            ],
          ],
        ),
      ),
    );
  }
}

class _PetNamePlate extends StatelessWidget {
  const _PetNamePlate({required this.name, required this.level});

  final String name;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: AppRadius.brPill,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accentTeal,
              borderRadius: AppRadius.brPill,
            ),
            child: Text(
              '$level',
              style: AppTextStyles.muted.copyWith(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.muted.copyWith(
                color: AppColors.primaryBlue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small floating shop island. Bobs gently and opens the Shop when tapped.
class _ShopIsland extends StatelessWidget {
  const _ShopIsland({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _FloatingSprite(
        duration: const Duration(milliseconds: 3000),
        travel: 7,
        child: Image.asset(
          _kShopIslandAsset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) =>
              const _ShopIslandPlaceholder(),
        ),
      ),
    );
  }
}

class _ShopIslandPlaceholder extends StatelessWidget {
  const _ShopIslandPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE7B85C), Color(0xFFC8852F)],
            ),
            borderRadius: AppRadius.brMd,
            boxShadow: AppShadows.raised,
          ),
          child: Text(
            'SHOP',
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B5A2B), Color(0xFF5E3A18)],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: AppShadows.raised,
            ),
            child: const Center(
              child: Icon(Icons.storefront, color: Colors.white, size: 30),
            ),
          ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
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
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // Tail pointing down toward the pet. Drawn with CustomPaint (a plain
        // filled triangle) — NOT a rotated Container, which overflowed the
        // Clip.none Stack and rendered as a red GPU artifact under Impeller.
        const Padding(
          padding: EdgeInsets.only(left: 22),
          child: CustomPaint(size: Size(20, 10), painter: _BubbleTailPainter()),
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

/// Soft elliptical pool of colour lying flat on the ground plane. Used for
/// both the contact shadows (dark) and the active pet's warm light pad. The
/// radial falloff is painted with a gradient shader (no MaskFilter blur, which
/// misrenders under Impeller).
class _GroundOval extends StatelessWidget {
  const _GroundOval({required this.color});

  /// Centre colour; it fades to fully transparent at the oval's edge.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GroundOvalPainter(color),
        size: Size.infinite,
      ),
    );
  }
}

class _GroundOvalPainter extends CustomPainter {
  const _GroundOvalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    // Draw a circular radial falloff, squashed into the box's flat aspect so
    // it reads as an oval lying on the ground plane.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(1.0, size.height / size.width);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(rect);
    canvas.drawCircle(Offset.zero, radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GroundOvalPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Foot-anchored "breathing" idle: a subtle squash-and-stretch scaled from the
/// bottom-centre, so the feet stay glued to the ground. Grounded pets use this
/// instead of the floating bob — hovering up and down is exactly what made
/// them read as paper cutouts rather than creatures with weight.
class _BreathingSprite extends StatefulWidget {
  const _BreathingSprite({required this.child, required this.duration});

  final Widget child;
  final Duration duration;

  @override
  State<_BreathingSprite> createState() => _BreathingSpriteState();
}

class _BreathingSpriteState extends State<_BreathingSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(
              1 + 0.015 * t,
              1 - 0.025 * t,
              1,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Reusable idle-float wrapper: bobs [child] up by [travel] px, looping forever
/// with an ease-in-out feel. Uses only `Transform`, so it never disturbs the
/// surrounding layout.
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
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
                          fontSize: 16,
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
// Daily goal — compact progress strip (fits under the focus CTA on the map).
// ---------------------------------------------------------------------------

class _DailyGoalStrip extends StatelessWidget {
  const _DailyGoalStrip({required this.focus});

  final FocusProvider focus;

  @override
  Widget build(BuildContext context) {
    final percent = (focus.dailyGoalProgress * 100).round();
    final message = focus.dailyGoalCompleted
        ? 'Goal complete! Kiki is proud of you.'
        : '${focus.dailyGoalRemainingMinutes} min left today';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: const Color(0xFFB7EFE7), width: 1.2),
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, size: 18, color: AppColors.accentTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Today's Goal · $message",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.muted.copyWith(
                          color: const Color(0xFF4367A3),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: focus.dailyGoalProgress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      minHeight: 7,
                      value: value,
                      backgroundColor: const Color(0xFFEAF7FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentTeal,
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
            Icon(icon, color: AppColors.primaryBlue, size: 30),
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
