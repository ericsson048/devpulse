import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/app_animations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  double _progress = 0;
  int _logIndex = 0;
  String _statusText = 'INIT_LOADER...';
  final List<String> _logs = [];

  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  static const _statusLogs = [
    'KERNEL_INIT_SUCCESS',
    'CONNECTING_TO_PEERS...',
    'HANDSHAKE_ESTABLISHED',
    'SECURE_SHELL_ACTIVE',
    'SYNC_CLOUD_DATA',
    'CACHE_INVALIDATION_COMPLETE',
    'COMPILING_ASSETS_V8',
    'OPTIMIZING_RENDER_PIPELINE',
    'DEV_PULSE_READY',
  ];

  @override
  void initState() {
    super.initState();
    // Scanline sweep
    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _scanAnim = Tween<double>(begin: -0.15, end: 1.15).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.linear),
    );
    // Neon glow pulse
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 600), _tick);
  }

  void _tick() {
    if (!mounted) return;
    final rng = Random();
    final inc = rng.nextInt(5) + 1;
    setState(() {
      _progress = (_progress + inc).clamp(0, 100);
      if (_progress % 20 < inc && _logIndex < _statusLogs.length) {
        _statusText = _statusLogs[_logIndex];
        _logs.insert(0, _statusLogs[_logIndex]);
        if (_logs.length > 5) _logs.removeLast();
        _logIndex++;
      }
    });
    if (_progress < 100) {
      Future.delayed(Duration(milliseconds: rng.nextInt(180) + 40), _tick);
    } else {
      setState(() => _statusText = 'SYSTEM_READY');
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) context.go(AppRoutes.onboarding);
      });
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _glowCtrl.dispose();
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
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    AppColors.surfaceContainerLowest,
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
          // Scanline sweep
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, __) {
              final h = MediaQuery.of(context).size.height;
              return Positioned(
                top: _scanAnim.value * h,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Scanlines overlay
          Positioned.fill(
            child: CustomPaint(painter: const ScanlinePainter(opacity: 0.025)),
          ),
          // Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 52),
                    _buildStatusBox(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Glow halo + icon
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, child) => Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.18 * _glowAnim.value),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              child!,
            ],
          ),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Icon(Icons.terminal,
                color: AppColors.primary, size: 40),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 700.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 500.ms),
        const SizedBox(height: 20),
        Text('DevPulse',
                style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w900, letterSpacing: -1))
            .animate()
            .fadeIn(delay: 300.ms, duration: 500.ms)
            .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 6),
        Text(
          'UNIFIED DEVELOPMENT ENGINE',
          style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
              .copyWith(letterSpacing: 3.5, fontSize: 10),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildStatusBox() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 40,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYSTEM BOOT SEQUENCE',
                      style: AppTextStyles.labelSm(color: AppColors.primary)
                          .copyWith(letterSpacing: 2.5, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _statusText,
                          style: AppTextStyles.codeBlock(
                              color: AppColors.onSurfaceVariant),
                        ),
                        if (_progress < 100) const _BlinkingCursor(),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${_progress.toInt()}%',
                  key: ValueKey(_progress.toInt()),
                  style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                      .copyWith(fontSize: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Progress bar with neon glow
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 6,
                  backgroundColor:
                      AppColors.surfaceVariant.withValues(alpha: 0.4),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary),
                ),
              ),
              // Glow on bar
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Positioned(
                  left: 0,
                  right: (1 - _progress / 100) *
                      (MediaQuery.of(context).size.width - 104),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                              alpha: 0.4 * _glowAnim.value),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Terminal log — staggered entries
          SizedBox(
            height: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _logs.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 1.0 - e.key * 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        e.value,
                        style: AppTextStyles.codeBlock(
                                color: AppColors.onSurfaceVariant
                                    .withValues(alpha: 1.0 - e.key * 0.15))
                            .copyWith(fontSize: 11),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1, end: 0, duration: 300.ms),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Footer meta
          Opacity(
            opacity: 0.35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.dns, color: AppColors.onSurface, size: 13),
                  const SizedBox(width: 6),
                  Text('Core_Node_v4.2',
                      style: AppTextStyles.codeBlock(color: AppColors.onSurface)
                          .copyWith(fontSize: 10, letterSpacing: 1.5)),
                ]),
                Row(children: [
                  Text('Secure_Protocol',
                      style: AppTextStyles.codeBlock(color: AppColors.onSurface)
                          .copyWith(fontSize: 10, letterSpacing: 1.5)),
                  const SizedBox(width: 6),
                  const Icon(Icons.shield, color: AppColors.secondary, size: 13),
                ]),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 600.ms);
  }
}

// ── Blinking cursor ──────────────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 500.ms)
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: Text('_',
            style: AppTextStyles.codeBlock(color: AppColors.onSurfaceVariant)),
      );
}
