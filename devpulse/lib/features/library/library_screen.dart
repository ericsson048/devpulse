import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_animations.dart';
import '../../core/widgets/widgets.dart';
import '../../core/router/app_router.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedFilter = 0;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _filters = ['All', 'Beginner', 'Intermediate', 'Advanced'];

  static const _courses = [
    _CourseItem(
      title: 'Python Fundamentals',
      subtitle: 'Start your coding journey',
      tag: 'Python',
      level: 'Beginner',
      modules: 10,
      xp: 500,
      icon: Icons.code_rounded,
      color: AppColors.secondary,
      enrolled: true,
      progress: 0.6,
    ),
    _CourseItem(
      title: 'Node.js & Express',
      subtitle: 'Build scalable backends',
      tag: 'Node.js',
      level: 'Intermediate',
      modules: 12,
      xp: 750,
      icon: Icons.storage_rounded,
      color: AppColors.primary,
      enrolled: true,
      progress: 0.35,
    ),
    _CourseItem(
      title: 'Rust Systems Programming',
      subtitle: 'Memory-safe performance',
      tag: 'Rust',
      level: 'Advanced',
      modules: 15,
      xp: 1200,
      icon: Icons.memory_rounded,
      color: AppColors.tertiary,
      enrolled: false,
      progress: 0,
    ),
    _CourseItem(
      title: 'Go Microservices',
      subtitle: 'Cloud-native development',
      tag: 'Go',
      level: 'Intermediate',
      modules: 8,
      xp: 600,
      icon: Icons.hub_rounded,
      color: AppColors.primary,
      enrolled: false,
      progress: 0,
    ),
    _CourseItem(
      title: 'TypeScript Design Patterns',
      subtitle: 'Enterprise-grade TypeScript',
      tag: 'TypeScript',
      level: 'Advanced',
      modules: 10,
      xp: 900,
      icon: Icons.javascript_rounded,
      color: AppColors.secondary,
      enrolled: true,
      progress: 1.0,
    ),
    _CourseItem(
      title: 'Docker & Kubernetes',
      subtitle: 'Container orchestration',
      tag: 'DevOps',
      level: 'Intermediate',
      modules: 12,
      xp: 800,
      icon: Icons.cloud_queue_rounded,
      color: AppColors.tertiary,
      enrolled: false,
      progress: 0,
    ),
    _CourseItem(
      title: 'GraphQL API Design',
      subtitle: 'Modern API architecture',
      tag: 'API',
      level: 'Intermediate',
      modules: 6,
      xp: 450,
      icon: Icons.account_tree_rounded,
      color: AppColors.primary,
      enrolled: false,
      progress: 0,
    ),
    _CourseItem(
      title: 'SQL & PostgreSQL',
      subtitle: 'Master relational databases',
      tag: 'Database',
      level: 'Beginner',
      modules: 9,
      xp: 550,
      icon: Icons.table_chart_rounded,
      color: AppColors.secondary,
      enrolled: false,
      progress: 0,
    ),
  ];

  List<_CourseItem> get _filtered {
    final byLevel = _selectedFilter == 0
        ? _courses
        : _courses
            .where((c) => c.level == _filters[_selectedFilter])
            .toList();
    if (_searchQuery.isEmpty) return byLevel;
    return byLevel
        .where((c) =>
            c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.tag.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DevPulseAppBar(),
      body: Column(
        children: [
          // Search + filters (sticky)
          _buildSearchBar(),
          _buildFilters(),
          // Course grid
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CourseCard(
                        course: _filtered[i],
                        index: i,
                        onTap: () => context.go(AppRoutes.modulePath(1)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: AppTextStyles.bodyMd(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Search courses, languages...',
            hintStyle: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)
                .copyWith(fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.onSurfaceVariant, size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final active = i == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                          )
                        ]
                      : null,
                ),
                child: Text(
                  _filters[i],
                  style: AppTextStyles.labelSm(
                    color: active
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No courses found',
              style: AppTextStyles.headlineMd(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text('Try a different search or filter',
              style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 14)),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ── Course card ───────────────────────────────────────────────────────────────
class _CourseCard extends StatefulWidget {
  const _CourseCard({
    required this.course,
    required this.index,
    required this.onTap,
  });
  final _CourseItem course;
  final int index;
  final VoidCallback onTap;

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard>
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
    final c = widget.course;
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
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: c.enrolled
                  ? c.color.withValues(alpha: 0.2)
                  : AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
            boxShadow: c.enrolled
                ? [
                    BoxShadow(
                      color: c.color.withValues(alpha: 0.05),
                      blurRadius: 16,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(c.icon, color: c.color, size: 26),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.title,
                              style: AppTextStyles.bodyMd(
                                      color: AppColors.onSurface)
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (c.progress >= 1.0)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.secondary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(c.subtitle,
                        style: AppTextStyles.labelSm(
                                color: AppColors.onSurfaceVariant)
                            .copyWith(fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(label: c.tag, color: c.color),
                        const SizedBox(width: 6),
                        _Chip(
                          label: c.level,
                          color: _levelColor(c.level),
                        ),
                        const SizedBox(width: 6),
                        _Chip(
                          label: '+${c.xp} XP',
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                    if (c.enrolled && c.progress > 0 && c.progress < 1.0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c.progress,
                          minHeight: 4,
                          backgroundColor:
                              AppColors.surfaceVariant.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(c.color),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ).staggered(widget.index, offsetY: 12);
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner':
        return AppColors.secondary;
      case 'Intermediate':
        return AppColors.primary;
      case 'Advanced':
        return AppColors.tertiary;
      default:
        return AppColors.outline;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm(color: color)
              .copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _CourseItem {
  const _CourseItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.level,
    required this.modules,
    required this.xp,
    required this.icon,
    required this.color,
    required this.enrolled,
    required this.progress,
  });
  final String title;
  final String subtitle;
  final String tag;
  final String level;
  final int modules;
  final int xp;
  final IconData icon;
  final Color color;
  final bool enrolled;
  final double progress;
}
