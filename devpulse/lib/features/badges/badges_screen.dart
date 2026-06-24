import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_service.dart';
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});
  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<Map<String, dynamic>> _allBadges = [];
  Set<int> _earnedIds = {};
  Map<int, DateTime> _earnedAt = {};
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
      final results = await Future.wait([
        ApiService.listAchievements(),
        ApiService.getUserAchievements(),
      ]);
      final List allRaw = results[0];
      final all = allRaw.cast<Map<String, dynamic>>();
      final List earned = results[1];

      final earnedIds = <int>{};
      final earnedAt = <int, DateTime>{};
      for (final e in earned) {
        final map = e as Map<String, dynamic>;
        final ach = map['achievement'] as Map<String, dynamic>? ?? map;
        final id = ach['id'] as int?;
        if (id != null) {
          earnedIds.add(id);
          final raw = map['earned_at'] as String?;
          if (raw != null) earnedAt[id] = DateTime.parse(raw);
        }
      }

      if (mounted) {
        setState(() {
          _allBadges = all;
          _earnedIds = earnedIds;
          _earnedAt = earnedAt;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static IconData _mapIcon(String? name) {
    switch (name) {
      case 'shield_rounded': return Icons.shield_rounded;
      case 'keyboard_rounded': return Icons.keyboard_rounded;
      case 'bug_report_rounded': return Icons.bug_report_rounded;
      case 'directions_walk': return Icons.directions_walk;
      case 'local_fire_department': return Icons.local_fire_department;
      default: return Icons.emoji_events_rounded;
    }
  }

  static Color _parseColor(String? hex) {
    if (hex == null) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
    } catch (_) {
      return AppColors.primary;
    }
  }

  static String _conditionLabel(String? type, int? value) {
    if (type == null || value == null) return '';
    switch (type) {
      case 'lessons_complete': return 'Complete $value lesson${value == 1 ? '' : 's'}';
      case 'course_complete': return 'Complete $value course${value == 1 ? '' : 's'}';
      case 'commands_run': return 'Run $value commands';
      case 'bugs_fixed': return 'Fix $value bugs';
      case 'streak_days': return 'Maintain a $value-day streak';
      default: return '$type: $value';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Badges',
            style: AppTextStyles.headlineMd(color: AppColors.onSurface)
                .copyWith(fontSize: 22)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Could not load badges',
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
      );
    }

    final earned = _allBadges.where((b) => _earnedIds.contains(b['id'])).toList();
    final locked = _allBadges.where((b) => !_earnedIds.contains(b['id'])).toList();
    final totalXp = _allBadges
        .where((b) => _earnedIds.contains(b['id']))
        .fold(0, (sum, b) => sum + (b['xp_reward'] as int? ?? 0));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        _buildSummary(earned.length, _allBadges.length, totalXp),
        const SizedBox(height: 24),
        if (earned.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('EARNED (${earned.length})',
                style: AppTextStyles.labelSm(color: AppColors.secondary)
                    .copyWith(letterSpacing: 1.5, fontSize: 12)),
          ),
          ...earned.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BadgeCard(
              badge: e.value,
              earned: true,
              earnedAt: _earnedAt[e.value['id']],
              index: e.key,
            ),
          )),
          const SizedBox(height: 20),
        ],
        if (locked.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('LOCKED (${locked.length})',
                style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                    .copyWith(letterSpacing: 1.5, fontSize: 12)),
          ),
          ...locked.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BadgeCard(
              badge: e.value,
              earned: false,
              index: e.key + earned.length,
            ),
          )),
        ],
        if (_allBadges.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No badges available yet',
                      style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummary(int earned, int total, int xp) {
    final pct = total > 0 ? earned / total : 0.0;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.7),
                  AppColors.secondary.withValues(alpha: 0.7),
                  AppColors.tertiary.withValues(alpha: 0.7),
                  AppColors.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainer,
                ),
                child: Icon(Icons.emoji_events_rounded,
                    color: AppColors.primary, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$earned / $total collected',
                    style: AppTextStyles.headlineMd(color: AppColors.onSurface)
                        .copyWith(fontSize: 18)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      earned == total ? AppColors.secondary : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          if (xp > 0) ...[
            const SizedBox(width: 12),
            Column(
              children: [
                Icon(Icons.stars_rounded, color: AppColors.secondary, size: 20),
                const SizedBox(height: 2),
                Text('+$xp',
                    style: AppTextStyles.labelSm(color: AppColors.secondary)
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;
  final bool earned;
  final DateTime? earnedAt;
  final int index;

  const _BadgeCard({
    required this.badge,
    required this.earned,
    this.earnedAt,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _BadgesScreenState._mapIcon(badge['icon'] as String?);
    final bg = _BadgesScreenState._parseColor(badge['icon_bg'] as String?);
    final fg = _BadgesScreenState._parseColor(badge['icon_color'] as String?);
    final title = badge['title'] as String? ?? 'Badge';
    final desc = badge['description'] as String? ?? '';
    final xp = badge['xp_reward'] as int? ?? 0;
    final cond = _BadgesScreenState._conditionLabel(
        badge['condition_type'] as String?, badge['condition_value'] as int?);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: earned
          ? AppColors.surfaceContainerLow.withValues(alpha: 0.8)
          : AppColors.surfaceContainerLow.withValues(alpha: 0.4),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: earned ? bg : bg.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: earned
                        ? fg.withValues(alpha: 0.5)
                        : AppColors.outlineVariant.withValues(alpha: 0.15),
                  ),
                  boxShadow: earned
                      ? [BoxShadow(
                          color: fg.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 0),
                        )]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: earned ? fg : fg.withValues(alpha: 0.2),
                  size: 26,
                ),
              ),
              if (!earned)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Icon(Icons.lock_rounded,
                        size: 10, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: AppTextStyles.bodyMd(color: earned
                              ? AppColors.onSurface
                              : AppColors.onSurface.withValues(alpha: 0.5))
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    if (earned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 11, color: AppColors.secondary),
                            const SizedBox(width: 3),
                            Text('Earned',
                                style: AppTextStyles.labelSm(color: AppColors.secondary)
                                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    if (!earned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Locked',
                            style: AppTextStyles.labelSm(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))
                                .copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(desc,
                      style: AppTextStyles.labelSm(
                          color: earned
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.35))
                              .copyWith(fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (cond.isNotEmpty && !earned)
                      Row(
                        children: [
                          Icon(Icons.flag_outlined,
                              size: 11,
                              color: AppColors.primary.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(cond,
                              style: AppTextStyles.labelSm(
                                  color: AppColors.primary.withValues(alpha: 0.6))
                                  .copyWith(fontSize: 11)),
                        ],
                      ),
                    if (earnedAt != null) ...[
                      if (cond.isNotEmpty && !earned) const SizedBox(width: 12),
                      Icon(Icons.schedule_rounded,
                          size: 11,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(_formatDate(earnedAt!),
                          style: AppTextStyles.labelSm(
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))
                              .copyWith(fontSize: 11)),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.stars_rounded,
                            size: 13,
                            color: earned
                                ? AppColors.secondary
                                : AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(width: 3),
                        Text('+$xp XP',
                            style: AppTextStyles.labelSm(
                                color: earned
                                    ? AppColors.secondary
                                    : AppColors.onSurfaceVariant.withValues(alpha: 0.3))
                                .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 60 * index),
      duration: 400.ms,
    ).slideX(
      begin: 0.12,
      delay: Duration(milliseconds: 60 * index),
      duration: 400.ms,
      curve: Curves.easeOut,
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
