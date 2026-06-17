import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable animation presets — 200-300ms per UI/UX Pro Max guidelines.
/// Dispose controllers properly (handled by flutter_animate internally).
extension AppAnimations on Widget {
  // ── Entrance animations ──────────────────────────────────────

  /// Fade + slide up — standard card entrance
  Widget fadeSlideUp({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
    double offsetY = 24,
  }) =>
      animate(delay: delay)
          .fadeIn(duration: duration, curve: Curves.easeOut)
          .slideY(
            begin: offsetY / 100,
            end: 0,
            duration: duration,
            curve: Curves.easeOut,
          );

  /// Fade + slide from left
  Widget fadeSlideLeft({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 350),
  }) =>
      animate(delay: delay)
          .fadeIn(duration: duration, curve: Curves.easeOut)
          .slideX(begin: -0.15, end: 0, duration: duration, curve: Curves.easeOut);

  /// Scale in — for icons, badges, chips
  Widget scaleIn({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      animate(delay: delay)
          .scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1, 1),
            duration: duration,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: duration);

  /// Shimmer — skeleton loading state
  Widget shimmer({Color? baseColor, Color? highlightColor}) => animate(
        onPlay: (c) => c.repeat(),
      ).shimmer(
        duration: const Duration(milliseconds: 1200),
        color: highlightColor ?? Colors.white.withValues(alpha: 0.08),
      );

  /// Staggered list item — use with index
  Widget staggered(int index, {double offsetY = 20}) => fadeSlideUp(
        delay: Duration(milliseconds: 60 * index),
        offsetY: offsetY,
      );
}

/// Neon pulse animation for glowing elements
class NeonPulse extends StatefulWidget {
  const NeonPulse({
    super.key,
    required this.child,
    this.color = const Color(0xFFADC6FF),
    this.minOpacity = 0.3,
    this.maxOpacity = 0.8,
    this.duration = const Duration(seconds: 2),
  });

  final Widget child;
  final Color color;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  @override
  State<NeonPulse> createState() => _NeonPulseState();
}

class _NeonPulseState extends State<NeonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Opacity(opacity: _anim.value, child: child),
        child: widget.child,
      );
}

/// Floating animation — gentle vertical bob
class FloatingWidget extends StatefulWidget {
  const FloatingWidget({
    super.key,
    required this.child,
    this.amplitude = 10.0,
    this.duration = const Duration(seconds: 3),
    this.delay = Duration.zero,
  });

  final Widget child;
  final double amplitude;
  final Duration duration;
  final Duration delay;

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: -widget.amplitude).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, _anim.value), child: child),
        child: widget.child,
      );
}

/// Scanline overlay painter — cyberpunk aesthetic
class ScanlinePainter extends CustomPainter {
  const ScanlinePainter({this.opacity = 0.03});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Dot grid painter — atmospheric background
class DotGridPainter extends CustomPainter {
  const DotGridPainter({this.color = const Color(0xFFADC6FF), this.opacity = 0.04});
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
