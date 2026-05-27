import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single floating particle (star ⭐, heart ❤️, bolt ⚡, food 🍖).
class FloatingParticle {
  FloatingParticle({
    required this.emoji,
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.size,
  });

  final String emoji;
  final double startX;
  final double startY;
  final double angle; // direction in radians
  final double speed;
  final double size;
}

/// Overlays floating particles that fly upward and fade out.
/// Wrap this in a [Stack] and position it wherever particles should originate.
///
/// Example:
/// ```dart
/// Stack(children: [
///   myWidget,
///   FloatingParticlesWidget(trigger: _showParticles, emojis: ['❤️', '⚡']),
/// ])
/// ```
class FloatingParticlesWidget extends StatefulWidget {
  const FloatingParticlesWidget({
    super.key,
    required this.trigger,
    this.emojis = const ['⭐', '❤️', '⚡'],
    this.count = 8,
    this.originAlignment = Alignment.center,
    this.spread = 80.0,
  });

  /// Increment this to trigger a new burst of particles.
  final int trigger;

  final List<String> emojis;
  final int count;
  final Alignment originAlignment;
  final double spread;

  @override
  State<FloatingParticlesWidget> createState() =>
      _FloatingParticlesWidgetState();
}

class _FloatingParticlesWidgetState extends State<FloatingParticlesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  final _rand = math.Random();
  late List<FloatingParticle> _particles;
  int _lastTrigger = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _particles = [];
  }

  @override
  void didUpdateWidget(FloatingParticlesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != _lastTrigger && widget.trigger > 0) {
      _lastTrigger = widget.trigger;
      _spawnBurst();
    }
  }

  void _spawnBurst() {
    _particles = List.generate(widget.count, (i) {
      final angle = (_rand.nextDouble() * math.pi) + math.pi; // upward arc
      return FloatingParticle(
        emoji: widget.emojis[_rand.nextInt(widget.emojis.length)],
        startX: (_rand.nextDouble() - 0.5) * widget.spread,
        startY: (_rand.nextDouble() - 0.5) * 20,
        angle: angle,
        speed: 60 + _rand.nextDouble() * 80,
        size: 14 + _rand.nextDouble() * 14,
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();

    final size = widget.spread * 2;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final t = _progress.value;
          return IgnorePointer(
            child: Stack(
              clipBehavior: Clip.none,
              children: _particles.map((p) {
                final dx = p.startX + math.cos(p.angle) * p.speed * t;
                final dy = p.startY + math.sin(p.angle) * p.speed * t - 40 * t;
                final opacity = (1 - t).clamp(0.0, 1.0);
                return Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(dx, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: Center(
                        child: Text(
                          p.emoji,
                          style: TextStyle(fontSize: p.size),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
