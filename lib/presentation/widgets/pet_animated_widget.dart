import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PetAnimationState { idle, happy, focusing, celebrating, sad }

/// A reusable, animated widget that displays the pet (Kiki the fox).
/// It supports 5 animation states driven by an external [state] parameter.
class PetAnimatedWidget extends StatefulWidget {
  const PetAnimatedWidget({
    super.key,
    required this.imagePath,
    this.width = 120,
    this.state = PetAnimationState.idle,
    this.enableMotion = true,
    this.onTap,
  });

  final String imagePath;
  final double width;
  final PetAnimationState state;
  final bool enableMotion;
  final VoidCallback? onTap;

  @override
  State<PetAnimatedWidget> createState() => _PetAnimatedWidgetState();
}

class _PetAnimatedWidgetState extends State<PetAnimatedWidget>
    with TickerProviderStateMixin {
  // --- Controllers ---
  late AnimationController _idleController; // continuous idle bob
  late AnimationController _actionController; // one-shot action animations

  // --- Idle: gentle floating bob ---
  late Animation<double> _idleBobY; // vertical offset
  late Animation<double> _idleSway; // slight horizontal sway for focusing

  // --- Action: one-shot ---
  late Animation<double> _actionScale;
  late Animation<double> _actionOffsetY;
  late Animation<double> _actionRotate;

  PetAnimationState _currentState = PetAnimationState.idle;

  @override
  void initState() {
    super.initState();

    // Idle controller loops forever
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _idleBobY = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
    _idleSway = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Action controller for one-shot animations
    _actionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rebuildActionAnimations(widget.state);
    _applyState(widget.state);
  }

  @override
  void didUpdateWidget(PetAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _applyState(widget.state);
    }
  }

  void _rebuildActionAnimations(PetAnimationState state) {
    switch (state) {
      case PetAnimationState.happy:
        _actionController.duration = const Duration(milliseconds: 700);
        _actionScale =
            TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween(begin: 1.0, end: 1.25),
                weight: 40,
              ),
              TweenSequenceItem(
                tween: Tween(begin: 1.25, end: 0.92),
                weight: 20,
              ),
              TweenSequenceItem(
                tween: Tween(begin: 0.92, end: 1.10),
                weight: 20,
              ),
              TweenSequenceItem(
                tween: Tween(begin: 1.10, end: 1.0),
                weight: 20,
              ),
            ]).animate(
              CurvedAnimation(parent: _actionController, curve: Curves.easeOut),
            );
        _actionOffsetY = Tween<double>(begin: 0, end: -18).animate(
          CurvedAnimation(parent: _actionController, curve: Curves.easeOut),
        );
        _actionRotate = Tween<double>(
          begin: 0,
          end: 0,
        ).animate(_actionController);

      case PetAnimationState.celebrating:
        _actionController.duration = const Duration(milliseconds: 900);
        _actionScale = Tween<double>(begin: 1.0, end: 1.18).animate(
          CurvedAnimation(parent: _actionController, curve: Curves.elasticOut),
        );
        _actionOffsetY = Tween<double>(begin: 0, end: -18).animate(
          CurvedAnimation(parent: _actionController, curve: Curves.easeOut),
        );
        _actionRotate = Tween<double>(begin: -0.08, end: 0.08).animate(
          CurvedAnimation(parent: _actionController, curve: Curves.easeInOut),
        );

      case PetAnimationState.sad:
        _actionController.duration = const Duration(milliseconds: 1200);
        _actionScale = Tween<double>(begin: 1.0, end: 0.92).animate(
          CurvedAnimation(parent: _actionController, curve: Curves.easeIn),
        );
        _actionOffsetY = Tween<double>(begin: 0, end: 6).animate(
          CurvedAnimation(parent: _actionController, curve: Curves.easeIn),
        );
        _actionRotate = Tween<double>(begin: 0, end: 0.06).animate(
          CurvedAnimation(parent: _actionController, curve: Curves.easeIn),
        );

      default:
        _actionScale = Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(_actionController);
        _actionOffsetY = Tween<double>(
          begin: 0,
          end: 0,
        ).animate(_actionController);
        _actionRotate = Tween<double>(
          begin: 0,
          end: 0,
        ).animate(_actionController);
    }
  }

  void _applyState(PetAnimationState state) {
    _currentState = state;
    _rebuildActionAnimations(state);

    switch (state) {
      case PetAnimationState.idle:
        _idleController.duration = const Duration(milliseconds: 2600);
        _actionController.stop();
        _actionController.reset();

      case PetAnimationState.focusing:
        // Slower idle sway – focusing mode
        _idleController.duration = const Duration(milliseconds: 4000);
        _actionController.stop();
        _actionController.reset();

      case PetAnimationState.happy:
        _actionController.forward(from: 0).then((_) {
          // Return to idle after happy anim
          if (mounted) _applyState(PetAnimationState.idle);
        });

      case PetAnimationState.celebrating:
        _actionController.forward(from: 0).then((_) {
          if (mounted) _applyState(PetAnimationState.idle);
        });

      case PetAnimationState.sad:
        _actionController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petImage = Image.asset(
      widget.imagePath,
      width: widget.width,
      fit: BoxFit.contain,
    );

    if (!widget.enableMotion) {
      return GestureDetector(onTap: widget.onTap, child: petImage);
    }

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        // Trigger happy bounce when tapped (unless celebrating)
        if (_currentState != PetAnimationState.celebrating) {
          _applyState(PetAnimationState.happy);
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleController, _actionController]),
        builder: (context, child) {
          // Determine offsets depending on state
          final bool isAction =
              _currentState == PetAnimationState.happy ||
              _currentState == PetAnimationState.celebrating ||
              _currentState == PetAnimationState.sad;

          final double bobY = isAction ? _actionOffsetY.value : _idleBobY.value;
          final double swayX = _currentState == PetAnimationState.focusing
              ? _idleSway.value
              : 0;
          final double scale = isAction ? _actionScale.value : 1.0;
          final double rotate = isAction ? _actionRotate.value : 0.0;
          final double sadSway = _currentState == PetAnimationState.sad
              ? math.sin(_idleController.value * math.pi) * 1.5
              : 0;

          return Transform.translate(
            offset: Offset(swayX + sadSway, bobY),
            child: Transform.rotate(
              angle: rotate,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: petImage,
      ),
    );
  }
}
