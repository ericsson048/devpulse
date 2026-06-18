import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_animations.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getHomeDashboard();
      if (mounted) setState(() { _dashboard = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String get _displayName => _dashboard?['display_name'] as String? ?? 'Developer';
  int get _level => _dashboard?['level'] as int? ?? 1;
  int get _streak => _dashboard?['streak'] as int? ?? 0;
  int get _dailyGoal => _dashboard?['daily_goal_xp'] as int? ?? 1000;
  int get _dailyEarned => _dashboard?['daily_xp_earned'] as int? ?? 0;
  int get _achievementsCount => _dashboard?['achievements_count'] as int? ?? 0;
  int get _globalRank => _dashboard?['global_rank'] as int? ?? 1;
  List<dynamic> get _inProgressCourses => _dashboard?['in_progress_courses'] as List<dynamic>? ?? [];
  List<dynamic> get _recommendedCourses => _dashboard?['recommended_courses'] as List<dynamic>? ?? [];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Could not load dashboard', style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Text(_error!, style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const DotGridPainter())),
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.07), Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar(context)),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildGreeting(),
                )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _buildDailyXpCard(),
                )),
                if (_inProgressCourses.isNotEmpty) ...[
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                    child: _buildSectionHeader('Continue Learning', onSeeAll: () {}),
                  )),
                  SliverToBoxAdapter(child: _buildContinueLearning()),
                ],
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: _buildSectionHeader('Your Stats', onSeeAll: null),
                )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildStatsRow(),
                )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: _buildSectionHeader('Recommended for You',
                      onSeeAll: () => context.go('/app/library')),
                )),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: _RecommendedCard(
                        course: _recommendedCourses.length > i ? _CourseData(
                          title: _recommendedCourses[i]['title'] as String? ?? '',
                          subtitle: '${_recommendedCourses[i]['total_modules'] ?? 0} modules',
                          progress: 0,
                          icon: Icons.code_rounded,
                          color: AppColors.primary,
                          tag: _recommendedCourses[i]['tag'] as String? ?? '',
                        ) : _CourseData(title: '', subtitle: '', progress: 0, icon: Icons.code_rounded, color: AppColors.primary, tag: ''),
                        index: i,
                        onTap: () => context.go(AppRoutes.modulePath(1)),
                      ),
                    ),
                    childCount: _recommendedCourses.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.terminal, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text('DevPulse',
              style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
          const Spacer(),
          // Notification bell
          _IconBtn(
            icon: Icons.notifications_outlined,
            badge: true,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Avatar
          GestureDetector(
            onTap: () => context.go('/app/profile'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                color: AppColors.surfaceVariant,
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, duration: 400.ms);
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.displayLgMobile(color: AppColors.onSurface)
                .copyWith(fontSize: 26),
            children: [
              const TextSpan(text: 'Welcome back,\n'),
              TextSpan(
                text: '$_displayName 👋',
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 500.ms),
        const SizedBox(height: 10),
        // Streak badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.secondary, size: 16),
              const SizedBox(width: 6),
              Text('$_streak day streak — keep it up!',
                  style: AppTextStyles.labelSm(color: AppColors.secondary)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms).scaleIn(delay: 250.ms),
      ],
    );
  }

  Widget _buildDailyXpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.25),
            AppColors.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DAILY GOAL',
                      style: AppTextStyles.labelSm(color: AppColors.primary)
                          .copyWith(letterSpacing: 2, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('$_dailyEarned / $_dailyGoal XP',
                      style: AppTextStyles.headlineMd(color: AppColors.onSurface)
                          .copyWith(fontSize: 20)),
                ],
              ),
              // Circular progress
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _dailyGoal > 0 ? _dailyEarned / _dailyGoal : 0.0,
                      strokeWidth: 4,
                      backgroundColor:
                          AppColors.surfaceVariant.withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                    Text('${_dailyGoal > 0 ? (_dailyEarned * 100 ~/ _dailyGoal) : 0}%',
                        style: AppTextStyles.labelSm(color: AppColors.primary)
                            .copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    delay: 300.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
            ],
          ),
          const SizedBox(height: 14),
          // XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _AnimatedXpBar(value: _dailyGoal > 0 ? _dailyEarned / _dailyGoal : 0.0),
          ),
          const SizedBox(height: 10),
          Text('${(_dailyGoal - _dailyEarned).clamp(0, _dailyGoal)} XP to complete today\'s goal',
              style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 500.ms);
  }

  Widget _buildSectionHeader(String title, {required VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all',
                style: AppTextStyles.labelSm(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildContinueLearning() {
    final courses = _inProgressCourses;
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: courses.length,
        itemBuilder: (_, i) {
          final c = courses[i];
          final courseId = c['course_id'] as int? ?? 1;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _ContinueCard(
              course: _CourseData(
                title: c['title'] as String? ?? '',
                subtitle: 'Module ${c['current_module'] ?? 1} of ${c['total_modules'] ?? 1}',
                progress: (c['progress'] as num?)?.toDouble() ?? 0.0,
                icon: Icons.storage_rounded,
                color: AppColors.primary,
                tag: c['tag'] as String? ?? '',
              ),
              index: i,
              onTap: () => context.go(AppRoutes.modulePath(courseId)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.bolt_rounded,
            value: '$_level',
            label: 'Level',
            color: AppColors.primary,
          ).staggered(0),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.military_tech_rounded,
            value: '$_achievementsCount',
            label: 'Achievements',
            color: AppColors.secondary,
          ).staggered(1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.leaderboard_rounded,
            value: '#$_globalRank',
            label: 'Global Rank',
            color: AppColors.tertiary,
          ).staggered(2),
        ),
      ],
    );
  }
}

// ── Animated XP bar ───────────────────────────────────────────────────────────
class _AnimatedXpBar extends StatefulWidget {
  const _AnimatedXpBar({required this.value});
  final double value;

  @override
  State<_AnimatedXpBar> createState() => _AnimatedXpBarState();
}

class _AnimatedXpBarState extends State<_AnimatedXpBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 1200.ms);
  late final Animation<double> _anim =
      Tween<double>(begin: 0, end: widget.value).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(400.ms, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => LinearProgressIndicator(
          value: _anim.value,
          minHeight: 8,
          backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
}

// ── Continue card (horizontal scroll) ────────────────────────────────────────
class _ContinueCard extends StatefulWidget {
  const _ContinueCard({
    required this.course,
    required this.index,
    required this.onTap,
  });
  final _CourseData course;
  final int index;
  final VoidCallback onTap;

  @override
  State<_ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<_ContinueCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 150.ms, lowerBound: 0.95);

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
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.course.color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: widget.course.color.withValues(alpha: 0.06),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.course.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.course.icon,
                        color: widget.course.color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.course.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.course.tag,
                        style: AppTextStyles.labelSm(color: widget.course.color)
                            .copyWith(fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(widget.course.title,
                  style: AppTextStyles.bodyMd(color: AppColors.onSurface)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(widget.course.subtitle,
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11)),
              const Spacer(),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.course.progress,
                  minHeight: 4,
                  backgroundColor:
                      AppColors.surfaceVariant.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.course.color),
                ),
              ),
              const SizedBox(height: 4),
              Text('${(widget.course.progress * 100).toInt()}% complete',
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 10)),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * widget.index + 300),
            duration: 400.ms)
        .slideX(
            begin: 0.15,
            end: 0,
            delay: Duration(milliseconds: 100 * widget.index + 300),
            duration: 400.ms);
  }
}

// ── Recommended card ──────────────────────────────────────────────────────────
class _RecommendedCard extends StatefulWidget {
  const _RecommendedCard({
    required this.course,
    required this.index,
    required this.onTap,
  });
  final _CourseData course;
  final int index;
  final VoidCallback onTap;

  @override
  State<_RecommendedCard> createState() => _RecommendedCardState();
}

class _RecommendedCardState extends State<_RecommendedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 150.ms, lowerBound: 0.97);

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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.course.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.course.icon,
                    color: widget.course.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.course.title,
                        style: AppTextStyles.bodyMd(color: AppColors.onSurface)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(widget.course.subtitle,
                        style: AppTextStyles.labelSm(
                                color: AppColors.onSurfaceVariant)
                            .copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.course.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: widget.course.color.withValues(alpha: 0.2)),
                ),
                child: Text(widget.course.tag,
                    style: AppTextStyles.labelSm(color: widget.course.color)
                        .copyWith(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    ).staggered(widget.index);
  }
}

// ── Mini stat card ────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.headlineMd(color: AppColors.onSurface)
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label,
              style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Icon button with badge ────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.badge = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.background, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _CourseData {
  const _CourseData({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.icon,
    required this.color,
    required this.tag,
  });
  final String title;
  final String subtitle;
  final double progress;
  final IconData icon;
  final Color color;
  final String tag;
}
