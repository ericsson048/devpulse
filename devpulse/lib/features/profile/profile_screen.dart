import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/app_animations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _xpCtrl;
  late final Animation<double> _xpAnim;

  @override
  void initState() {
    super.initState();
    _xpCtrl = AnimationController(vsync: this, duration: 1500.ms);
    _xpAnim = Tween<double>(begin: 0, end: 0.845).animate(
      CurvedAnimation(parent: _xpCtrl, curve: Curves.easeOutCubic),
    );
    // Trigger after mount
    Future.delayed(400.ms, () {
      if (mounted) _xpCtrl.forward();
    });
  }

  @override
  void dispose() {
    _xpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DevPulseAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero().fadeSlideUp(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildAchievements(),
            const SizedBox(height: 24),
            _buildCourseHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 32,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glow
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  // Avatar with ring
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary, width: 2.5),
                          color: AppColors.surfaceVariant,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 40, color: AppColors.primary),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text('LVL 42',
                              style: AppTextStyles.labelSm(
                                      color: AppColors.onSecondary)
                                  .copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900)),
                        ).scaleIn(delay: 400.ms),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code Master',
                                style: AppTextStyles.displayLgMobile(
                                        color: AppColors.onSurface)
                                    .copyWith(fontSize: 26))
                            .fadeSlideLeft(delay: 200.ms),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.verified_user_outlined,
                              size: 13,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('System Architect',
                              style: AppTextStyles.labelSm(
                                  color: AppColors.onSurfaceVariant)),
                        ]).fadeSlideLeft(delay: 280.ms),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('Silicon Valley',
                              style: AppTextStyles.labelSm(
                                  color: AppColors.onSurfaceVariant)),
                        ]).fadeSlideLeft(delay: 320.ms),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Animated XP bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('XP PROGRESS',
                          style: AppTextStyles.labelSm(color: AppColors.primary)
                              .copyWith(letterSpacing: 2, fontSize: 11)),
                      Text('8,450 / 10,000 XP',
                          style: AppTextStyles.labelSm(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedBuilder(
                      animation: _xpAnim,
                      builder: (_, __) => LinearProgressIndicator(
                        value: _xpAnim.value,
                        minHeight: 10,
                        backgroundColor:
                            AppColors.surfaceVariant.withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.secondary,
            value: '7 Day',
            label: 'Streak',
          ).staggered(0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.terminal,
            iconColor: AppColors.primary,
            value: '128',
            label: 'Challenges',
          ).staggered(1),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _RankCard().staggered(2),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievement Gallery',
                style: AppTextStyles.headlineMd(color: AppColors.onSurface))
            .fadeSlideLeft(delay: 100.ms),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _AchievementItem(
                icon: Icons.shield_rounded,
                iconBg: const Color(0xFF1E3A5F),
                iconColor: const Color(0xFF60A5FA),
                title: 'C++ Sentinel',
                subtitle: 'Master of Memory Management',
              ).staggered(0),
              const SizedBox(height: 12),
              _AchievementItem(
                icon: Icons.keyboard_rounded,
                iconBg: const Color(0xFF2D1B69),
                iconColor: const Color(0xFFA78BFA),
                title: 'Terminal Wiz',
                subtitle: 'CLI Mastery Level 10',
              ).staggered(1),
              const SizedBox(height: 12),
              _AchievementItem(
                icon: Icons.bug_report_rounded,
                iconBg: const Color(0xFF4C1D1D),
                iconColor: const Color(0xFFF87171),
                title: 'Bug Hunter',
                subtitle: '100 Production Issues Resolved',
              ).staggered(2),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('View All 42 Badges',
                      style: AppTextStyles.labelSm(
                          color: AppColors.onSurfaceVariant)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Course History',
                style: AppTextStyles.headlineMd(color: AppColors.onSurface))
            .fadeSlideLeft(delay: 100.ms),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _CourseItem(
                icon: Icons.storage_rounded,
                iconColor: AppColors.primary,
                title: 'Backend Engineering Architecture',
                subtitle: 'In Progress • Module 4 of 12',
                trailing: _ProgressTrailing(percent: 0.35, label: '35%'),
              ).staggered(0),
              Divider(height: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              _CourseItem(
                icon: Icons.javascript_rounded,
                iconColor: AppColors.tertiary,
                title: 'Advanced TypeScript Design Patterns',
                subtitle: 'Completed • 24 Dec 2023',
                trailing: _BadgeTrailing(
                    label: 'Perfect Score', color: AppColors.primary),
              ).staggered(1),
              Divider(height: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              _CourseItem(
                icon: Icons.cloud_queue_rounded,
                iconColor: AppColors.secondary,
                title: 'Kubernetes for Chaos Engineers',
                subtitle: 'Completed • 12 Nov 2023',
                trailing: _BadgeTrailing(
                    label: 'Standard Pass',
                    color: AppColors.onSurfaceVariant),
              ).staggered(2),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.headlineMd(color: AppColors.onSurface)
                  .copyWith(fontSize: 15)),
          Text(label,
              style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GLOBAL RANK',
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 10, letterSpacing: 1.5)),
              Text('#1,402',
                  style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                      .copyWith(fontSize: 22)),
            ],
          ),
          // Mini bar chart
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [0.3, 0.5, 0.75, 1.0, 0.65].asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 8,
                    height: 44 * e.value,
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: 0.3 + 0.7 * e.value),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  )
                      .animate()
                      .slideY(
                        begin: 1,
                        end: 0,
                        delay: Duration(milliseconds: 100 * e.key),
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(
                        delay: Duration(milliseconds: 100 * e.key),
                        duration: 300.ms,
                      ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  const _AchievementItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.bodyMd(color: AppColors.onSurface)
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourseItem extends StatelessWidget {
  const _CourseItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMd(color: AppColors.onSurface)
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: AppTextStyles.labelSm(
                            color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _ProgressTrailing extends StatelessWidget {
  const _ProgressTrailing({required this.percent, required this.label});
  final double percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                .copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: AppColors.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeTrailing extends StatelessWidget {
  const _BadgeTrailing({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm(color: color).copyWith(fontSize: 11)),
    );
  }
}
