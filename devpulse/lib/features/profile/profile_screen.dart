import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/app_animations.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  List<dynamic> _achievements = [];
  List<dynamic> _progress = [];
  bool _loading = true;
  String? _error;
  bool _editingName = false;
  final _nameCtrl = TextEditingController();

  late final AnimationController _xpCtrl;
  late final Animation<double> _xpAnim;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getUserProfile(),
        ApiService.getUserAchievements(),
        ApiService.getUserProgress(),
      ]);
      if (mounted) {
        setState(() {
          _user = results[0] as Map<String, dynamic>;
          _achievements = results[1] as List<dynamic>;
          _progress = results[2] as List<dynamic>;
          _loading = false;
        });
        _initXpAnim();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _initXpAnim() {
    _xpCtrl = AnimationController(vsync: this, duration: 1500.ms);
    final xp = (_user?['xp'] as int? ?? 0).toDouble();
    final next = (_user?['xp_next_level'] as int? ?? 10000).toDouble();
    final ratio = next > 0 ? (xp / next).clamp(0.0, 1.0) : 0.0;
    _xpAnim = Tween<double>(begin: 0, end: ratio).animate(
      CurvedAnimation(parent: _xpCtrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(400.ms, () {
      if (mounted) _xpCtrl.forward();
    });
  }

  String get _displayName => _user?['display_name'] as String? ?? 'Developer';
  int get _level => _user?['level'] as int? ?? 1;
  int get _xp => _user?['xp'] as int? ?? 0;
  int get _xpNext => (_user?['xp_next_level'] as int? ?? 10000);
  int get _streak => _user?['streak'] as int? ?? 0;
  String get _role => _user?['role'] as String? ?? 'Learner';

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty || newName == _displayName) {
      setState(() => _editingName = false);
      return;
    }
    try {
      final updated = await ApiService.updateProfile(displayName: newName);
      if (mounted) setState(() { _user = updated; _editingName = false; });
    } catch (e) {
      if (mounted) {
        showToast(context, message: 'Failed to update: $e', type: ToastType.error);
        setState(() => _editingName = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const DevPulseAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const DevPulseAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Could not load profile',
                    style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center),
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
          Positioned(top: -30, right: -30,
            child: Container(
              width: 180, height: 180,
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80, height: 80,
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
                      ).animate().scale(
                        begin: const Offset(0.7, 0.7),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                      Positioned(
                        bottom: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text('LVL $_level',
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
                            GestureDetector(
                              onTap: () {
                                _nameCtrl.text = _displayName;
                                setState(() => _editingName = true);
                              },
                              child: _editingName
                                  ? SizedBox(
                                      width: 160,
                                      height: 36,
                                      child: TextField(
                                        controller: _nameCtrl,
                                        autofocus: true,
                                        style: AppTextStyles.displayLgMobile(
                                                color: AppColors.onSurface)
                                            .copyWith(fontSize: 18),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onSubmitted: (_) => _saveName(),
                                      ),
                                    )
                                  : Text(_displayName,
                                          style: AppTextStyles.displayLgMobile(
                                                  color: AppColors.onSurface)
                                              .copyWith(fontSize: 26))
                                      .fadeSlideLeft(delay: 200.ms),
                            ),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.verified_user_outlined,
                              size: 13, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(_role,
                              style: AppTextStyles.labelSm(
                                  color: AppColors.onSurfaceVariant)),
                        ]).fadeSlideLeft(delay: 280.ms),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('XP PROGRESS',
                          style: AppTextStyles.labelSm(color: AppColors.primary)
                              .copyWith(letterSpacing: 2, fontSize: 11)),
                      Text('$_xp / $_xpNext XP',
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
    final challengesCount = _progress.length;
    final rank = _user?['global_rank'] as int? ?? 1;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.secondary,
            value: '$_streak',
            label: 'Streak',
          ).staggered(0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.terminal,
            iconColor: AppColors.primary,
            value: '$challengesCount',
            label: 'Challenges',
          ).staggered(1),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _RankCard(rank: rank).staggered(2),
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
              for (int i = 0; i < _achievements.length && i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildAchievementItem(_achievements[i], i),
              ],
              if (_achievements.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No achievements yet — keep learning!',
                        style: AppTextStyles.bodyMd(
                            color: AppColors.onSurfaceVariant)),
                  ),
                ),
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
                  child: Text('View All ${_achievements.length} Badges',
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

  Widget _buildAchievementItem(dynamic ach, int index) {
    final a = ach is Map<String, dynamic>
        ? (ach['achievement'] as Map<String, dynamic>? ?? ach)
        : <String, dynamic>{};
    final title = a['title'] as String? ?? 'Achievement';
    final desc = a['description'] as String? ?? '';
    return _AchievementItem(
      icon: _achievementIcon(title),
      iconBg: _achievementBg(title),
      iconColor: _achievementColor(title),
      title: title,
      subtitle: desc,
    ).staggered(index);
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
              for (int i = 0; i < _progress.length && i < 5; i++) ...[
                if (i > 0)
                  Divider(height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                _buildProgressItem(_progress[i], i),
              ],
              if (_progress.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No courses started yet',
                        style: AppTextStyles.bodyMd(
                            color: AppColors.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem(dynamic p, int index) {
    final pm = p as Map<String, dynamic>;
    final status = pm['status'] as String? ?? 'not_started';
    final pct = (pm['progress_percent'] as num?)?.toDouble() ?? 0.0;
    final completed = status == 'completed';
    return _CourseItem(
      icon: Icons.circle_rounded,
      iconColor: completed ? AppColors.secondary : AppColors.primary,
      title: 'Course #${pm['course_id'] ?? 0}',
      subtitle: completed
          ? 'Completed'
          : 'In Progress • ${(pct * 100).toInt()}%',
      trailing: completed
          ? _BadgeTrailing(label: 'Done', color: AppColors.secondary)
          : _ProgressTrailing(percent: pct, label: '${(pct * 100).toInt()}%'),
    ).staggered(index);
  }

  static IconData _achievementIcon(String title) {
    if (title.contains('Bug') || title.contains('bug')) return Icons.bug_report_rounded;
    if (title.contains('Terminal') || title.contains('CLI')) return Icons.keyboard_rounded;
    return Icons.shield_rounded;
  }

  static Color _achievementBg(String title) {
    if (title.contains('Bug') || title.contains('bug')) return const Color(0xFF4C1D1D);
    if (title.contains('Terminal') || title.contains('CLI')) return const Color(0xFF2D1B69);
    return const Color(0xFF1E3A5F);
  }

  static Color _achievementColor(String title) {
    if (title.contains('Bug') || title.contains('bug')) return const Color(0xFFF87171);
    if (title.contains('Terminal') || title.contains('CLI')) return const Color(0xFFA78BFA);
    return const Color(0xFF60A5FA);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label});
  final IconData icon;
  final Color iconColor;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
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
          Text(value, style: AppTextStyles.headlineMd(color: AppColors.onSurface).copyWith(fontSize: 15)),
          Text(label, style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant).copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
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
              Text('#$rank',
                  style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                      .copyWith(fontSize: 22)),
            ],
          ),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [0.3, 0.5, 0.75, 1.0, 0.65].asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 8, height: 44 * e.value,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3 + 0.7 * e.value),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ).animate().slideY(
                    begin: 1, end: 0,
                    delay: Duration(milliseconds: 100 * e.key),
                    duration: 400.ms, curve: Curves.easeOut,
                  ).fadeIn(delay: Duration(milliseconds: 100 * e.key), duration: 300.ms),
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
  const _AchievementItem({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.subtitle});
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
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
  const _CourseItem({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.trailing});
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
            width: 46, height: 46,
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
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
