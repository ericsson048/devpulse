import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_animations.dart';
import '../../core/router/app_router.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key, this.score = 7, this.total = 10});
  final int score;
  final int total;

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scoreCtrl;
  late final Animation<double> _scoreAnim;
  late final AnimationController _confettiCtrl;
  final List<_Particle> _particles = [];

  int get _xpEarned => (widget.score / widget.total * 250).round();
  double get _pct => widget.score / widget.total;

  String get _grade {
    if (_pct >= 0.9) return 'S';
    if (_pct >= 0.8) return 'A';
    if (_pct >= 0.7) return 'B';
    if (_pct >= 0.6) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    if (_pct >= 0.9) return AppColors.secondary;
    if (_pct >= 0.8) return AppColors.primary;
    if (_pct >= 0.7) return AppColors.primary;
    if (_pct >= 0.6) return AppColors.tertiary;
    return AppColors.error;
  }

  String get _message {
    if (_pct >= 0.9) return 'Outstanding!';
    if (_pct >= 0.8) return 'Excellent work!';
    if (_pct >= 0.7) return 'Well done!';
    if (_pct >= 0.6) return 'Good effort!';
    return 'Keep practicing!';
  }

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(vsync: this, duration: 1500.ms);
    _scoreAnim = Tween<double>(begin: 0, end: _pct).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic),
    );
    _confettiCtrl =
        AnimationController(vsync: this, duration: 3000.ms);

    // Generate particles
    final rng = Random();
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 1.5,
        speed: 0.3 + rng.nextDouble() * 0.7,
        size: 4 + rng.nextDouble() * 6,
        color: [
          AppColors.primary,
          AppColors.secondary,
          AppColors.tertiary,
          AppColors.primaryFixed,
        ][rng.nextInt(4)],
        angle: rng.nextDouble() * 2 * pi,
      ));
    }

    Future.delayed(400.ms, () {
      if (mounted) {
        _scoreCtrl.forward();
        if (_pct >= 0.7) _confettiCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dot grid
          Positioned.fill(
            child: CustomPaint(painter: const DotGridPainter()),
          ),
          // Confetti particles
          if (_pct >= 0.7)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiCtrl.value,
                  ),
                ),
              ),
            ),
          // Glow
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _gradeColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 40),
                  // Score ring
                  _buildScoreRing(),
                  const SizedBox(height: 32),
                  // Stats row
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  // XP earned
                  _buildXpCard(),
                  const Spacer(),
                  // Actions
                  _buildActions(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          _message,
          style: AppTextStyles.displayLgMobile(color: _gradeColor)
              .copyWith(fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 500.ms),
        const SizedBox(height: 6),
        Text(
          'Rust Ownership Quiz • Question 4 of 10',
          style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
              .copyWith(letterSpacing: 1),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildScoreRing() {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gradeColor.withValues(alpha: 0.15 * _scoreAnim.value),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Ring
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: _scoreAnim.value,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor:
                    AppColors.surfaceVariant.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation<Color>(_gradeColor),
              ),
            ),
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _grade,
                  style: AppTextStyles.displayLgMobile(color: _gradeColor)
                      .copyWith(fontSize: 52, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${widget.score}/${widget.total}',
                  style: AppTextStyles.headlineMd(color: AppColors.onSurface)
                      .copyWith(fontSize: 18),
                ),
                Text(
                  '${(_scoreAnim.value * 100).toInt()}%',
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 13),
                ),
              ],
            ),
          ],
        );
      },
    ).animate().scale(
          begin: const Offset(0.6, 0.6),
          delay: 300.ms,
          duration: 700.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.check_circle_rounded,
            value: '${widget.score}',
            label: 'Correct',
            color: AppColors.secondary,
          ).staggered(0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            icon: Icons.cancel_rounded,
            value: '${widget.total - widget.score}',
            label: 'Wrong',
            color: AppColors.error,
          ).staggered(1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            icon: Icons.timer_rounded,
            value: '2:34',
            label: 'Time',
            color: AppColors.primary,
          ).staggered(2),
        ),
      ],
    );
  }

  Widget _buildXpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: AppColors.secondary, size: 28),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                delay: 800.ms,
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('XP EARNED',
                    style: AppTextStyles.labelSm(color: AppColors.secondary)
                        .copyWith(letterSpacing: 2, fontSize: 11)),
                const SizedBox(height: 4),
                Text('+$_xpEarned XP',
                    style: AppTextStyles.displayLgMobile(
                            color: AppColors.secondary)
                        .copyWith(fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Level 42',
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11)),
              const SizedBox(height: 4),
              Text('8,700 / 10,000',
                  style: AppTextStyles.labelSm(color: AppColors.primary)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms)
        .slideY(begin: 0.15, end: 0, delay: 600.ms, duration: 500.ms);
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Primary: Continue
        _PressBtn(
          onTap: () => context.go(AppRoutes.modulePath(1)),
          color: AppColors.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continue Learning',
                  style: AppTextStyles.bodyMd(color: AppColors.onPrimary)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.onPrimary, size: 20),
            ],
          ),
        ).animate().fadeIn(delay: 900.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0, delay: 900.ms, duration: 400.ms),
        const SizedBox(height: 12),
        // Secondary: Retry
        _PressBtn(
          onTap: () => context.go('/app/quiz'),
          color: AppColors.surfaceContainerHigh,
          border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh_rounded,
                  color: AppColors.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Text('Retry Quiz',
                  style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
      ],
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.headlineMd(color: AppColors.onSurface)
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label,
              style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Press button ──────────────────────────────────────────────────────────────
class _PressBtn extends StatefulWidget {
  const _PressBtn({
    required this.child,
    required this.onTap,
    required this.color,
    this.border,
  });
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final BoxBorder? border;

  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 120.ms, lowerBound: 0.95);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapUp: (_) {
        _c.forward();
        widget.onTap();
      },
      onTapCancel: () => _c.forward(),
      child: ScaleTransition(
        scale: _c,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
            border: widget.border,
            boxShadow: widget.border == null
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    )
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Confetti painter ──────────────────────────────────────────────────────────
class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.angle,
  });
  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double angle;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.particles,
    required this.progress,
  });
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay * 0.3) * p.speed).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final x = p.x * size.width + sin(p.angle) * 60 * t;
      final y = -20 + t * (size.height + 40);
      final opacity = t < 0.8 ? 1.0 : (1.0 - t) / 0.2;
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0, 1))
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + t * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
