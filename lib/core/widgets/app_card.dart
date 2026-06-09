import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// The shared surface for the whole app.
///
/// One card to rule them all: consistent radius, padding, shadow and (when
/// [onTap] is given) a ripple plus a subtle press-down animation so taps feel
/// physical. Reach for this instead of hand-rolling a `Container` + `BoxShadow`
/// on every screen.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.borderColor,
    this.borderWidth = 1.5,
    this.radius,
    this.elevated = false,
    this.shadows,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? radius;

  /// Use the stronger "raised" shadow (sheets, claimable/highlighted cards).
  final bool elevated;

  /// Fully override the shadow stack (e.g. a gold reward glow).
  final List<BoxShadow>? shadows;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? AppRadius.brLg;
    final shadows =
        widget.shadows ?? (widget.elevated ? AppShadows.raised : AppShadows.card);

    final surface = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? Colors.white,
        borderRadius: radius,
        border: widget.borderColor == null
            ? null
            : Border.all(color: widget.borderColor!, width: widget.borderWidth),
        boxShadow: _pressed ? AppShadows.card : shadows,
      ),
      child: widget.child,
    );

    if (!_interactive) return surface;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.transparent,
            child: surface,
          ),
        ),
      ),
    );
  }
}
