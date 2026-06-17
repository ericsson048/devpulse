import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/app_animations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _page = 0;
  late final PageController _pageCtrl = PageController();

  static const _pages = [
    _OnboardingData(
      title: 'Learn any ',
      highlight: 'language',
      body: 'Master Python, Go, Rust, and more through interactive, hands-on modules designed by industry experts.',
      icon1: Icons.terminal,
      icon1Label: 'Interactive Sandbox',
      icon2: Icons.military_tech,
      icon2Label: 'Industry Badges',
      codeSnippet: 'fn main() { }',
      codeSnippet2: 'import "fmt"',
    ),
    _OnboardingData(
      title: 'Build real ',
      highlight: 'projects',
      body: 'Apply your skills on real-world challenges. Ship code, earn XP, and climb the global leaderboard.',
      icon1: Icons.code,
      icon1Label: 'Live Sandbox',
      icon2: Icons.bolt,
      icon2Label: 'XP System',
      codeSnippet: 'git push origin',
      codeSnippet2: 'npm run build',
    ),
    _OnboardingData(
      title: 'Track your ',
      highlight: 'progress',
      body: 'Detailed analytics, streaks, and achievement badges keep you motivated every single day.',
      icon1: Icons.local_fire_department,
      icon1Label: 'Daily Streaks',
      icon2: Icons.query_stats,
      icon2Label: 'Analytics',
      codeSnippet: '🔥 7 day streak',
      codeSnippet2: '+250 XP earned',
    ),
    _OnboardingData(
      title: 'Join the ',
      highlight: 'community',
      body: 'Connect with thousands of developers, share solutions, and grow together in a thriving ecosystem.',
      icon1: Icons.group,
      icon1Label: 'Peer Reviews',
      icon2: Icons.leaderboard,
      icon2Label: 'Leaderboard',
      codeSnippet: '#1,402 global',
      codeSnippet2: '12k+ devs',
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(AppRoutes.auth);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated background glows that shift per page
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            top: -80 + _page * 20.0,
            right: -80 + _page * 10.0,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            bottom: -80 - _page * 15.0,
            left: -60 + _page * 8.0,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.secondary.withValues(alpha: 0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),
                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _PageContent(data: _pages[i]),
                  ),
                ),
                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.terminal, color: AppColors.primary, size: 22)
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),
          const SizedBox(width: 8),
          Text('DevPulse',
                  style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w900))
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms),
          const Spacer(),
          TextButton(
            onPressed: () => context.go(AppRoutes.auth),
            child: Text('Skip',
                style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isLast = _page == _pages.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Animated dots
          Row(
            children: List.generate(_pages.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                margin: const EdgeInsets.only(right: 8),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              );
            }),
          ),
          // CTA button with press animation
          _AnimatedButton(
            onTap: _next,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast ? 'Get Started' : 'Next Step',
                    style: AppTextStyles.labelSm(color: AppColors.onPrimary)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward,
                      color: AppColors.onPrimary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page content ─────────────────────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  const _PageContent({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero illustration
          Expanded(
            flex: 5,
            child: Center(
              child: _HeroIllustration(data: data),
            ),
          ),
          const SizedBox(height: 28),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeonPulse(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('NEW LEARNING PATH',
                    style: AppTextStyles.labelSm(color: AppColors.primary)
                        .copyWith(fontSize: 11, letterSpacing: 2)),
              ],
            ),
          ).fadeSlideUp(delay: 100.ms),
          const SizedBox(height: 14),
          // Title
          RichText(
            text: TextSpan(
              style: AppTextStyles.displayLgMobile(color: AppColors.onSurface),
              children: [
                TextSpan(text: data.title),
                TextSpan(
                  text: data.highlight,
                  style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ).fadeSlideUp(delay: 180.ms),
          const SizedBox(height: 10),
          Text(data.body,
                  style: AppTextStyles.bodyLg(color: AppColors.onSurfaceVariant))
              .fadeSlideUp(delay: 260.ms),
          const SizedBox(height: 20),
          // Feature chips
          Row(
            children: [
              Expanded(
                child: _FeatureChip(
                  icon: data.icon1,
                  label: data.icon1Label,
                ).staggered(0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureChip(
                  icon: data.icon2,
                  label: data.icon2Label,
                  color: AppColors.secondary,
                ).staggered(1),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Hero illustration ─────────────────────────────────────────────────────────
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  width: 1,
                ),
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  Colors.transparent,
                ]),
              ),
            ),
            // Center icon
            Icon(data.icon1, size: 72,
                color: AppColors.primary.withValues(alpha: 0.25))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 3000.ms,
                  curve: Curves.easeInOut,
                ),
            // Floating code chip 1
            Positioned(
              top: 30,
              right: 20,
              child: FloatingWidget(
                amplitude: 10,
                duration: const Duration(seconds: 3),
                child: _CodeChip(
                  text: data.codeSnippet,
                  color: AppColors.primary,
                ),
              ),
            ),
            // Floating code chip 2
            Positioned(
              bottom: 50,
              left: 10,
              child: FloatingWidget(
                amplitude: 8,
                duration: const Duration(seconds: 4),
                delay: const Duration(milliseconds: 800),
                child: _CodeChip(
                  text: data.codeSnippet2,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 400.ms);
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTextStyles.codeBlock(color: color).copyWith(fontSize: 12),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.labelSm(color: AppColors.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Animated press button ─────────────────────────────────────────────────────
class _AnimatedButton extends StatefulWidget {
  const _AnimatedButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 120.ms, lowerBound: 0.92);

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
      child: ScaleTransition(scale: _c, child: widget.child),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.highlight,
    required this.body,
    required this.icon1,
    required this.icon1Label,
    required this.icon2,
    required this.icon2Label,
    required this.codeSnippet,
    required this.codeSnippet2,
  });
  final String title, highlight, body;
  final IconData icon1, icon2;
  final String icon1Label, icon2Label;
  final String codeSnippet, codeSnippet2;
}
