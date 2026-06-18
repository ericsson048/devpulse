import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_animations.dart';
import '../../core/widgets/widgets.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/toast.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedFilter = 0;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;
  final Set<int> _enrolling = {};

  static const _filters = ['All', 'Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getCoursesPaginated(limit: 100);
      if (mounted) setState(() {
        _courses = (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static IconData _iconData(String? icon) {
    switch (icon) {
      case 'storage': return Icons.storage_rounded;
      case 'memory': return Icons.memory_rounded;
      case 'cloud': return Icons.cloud_queue_rounded;
      case 'hub': return Icons.hub_rounded;
      case 'javascript': return Icons.javascript_rounded;
      case 'table': return Icons.table_chart_rounded;
      default: return Icons.code_rounded;
    }
  }

  static Color _colorFor(String? lvl) {
    switch (lvl?.toLowerCase()) {
      case 'beginner': return AppColors.secondary;
      case 'intermediate': return AppColors.primary;
      case 'advanced': return AppColors.tertiary;
      default: return AppColors.primary;
    }
  }

  double _progressFor(Map<String, dynamic> c) {
    final s = c['user_status'] as String? ?? 'not_started';
    if (s == 'not_started') return 0.0;
    return (c['progress_percent'] as num?)?.toDouble() ?? 0.0;
  }

  bool _isEnrolled(Map<String, dynamic> c) {
    final s = c['user_status'] as String? ?? 'not_started';
    return s == 'in_progress' || s == 'completed';
  }

  Future<void> _handleEnroll(int courseId) async {
    setState(() => _enrolling.add(courseId));
    try {
      await ApiService.enrollCourse(courseId);
      if (mounted) {
        showToast(context, message: 'Inscrit au cours !', type: ToastType.success);
        _load();
      }
    } catch (e) {
      if (mounted) {
        showToast(context, message: 'Erreur : $e', type: ToastType.error);
        setState(() => _enrolling.remove(courseId));
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final byLevel = _selectedFilter == 0
        ? _courses
        : _courses.where((c) {
            final lvl = (c['level'] as String? ?? '').toLowerCase();
            return lvl == _filters[_selectedFilter].toLowerCase();
          }).toList();
    if (_searchQuery.isEmpty) return byLevel;
    final q = _searchQuery.toLowerCase();
    return byLevel.where((c) {
      final title = (c['title'] as String? ?? '').toLowerCase();
      final tag = (c['tag'] as String? ?? '').toLowerCase();
      return title.contains(q) || tag.contains(q);
    }).toList();
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
          _buildSearchBar(),
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
              Text('Could not load courses',
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
    final filtered = _filtered;
    if (filtered.isEmpty) return _buildEmpty();
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final c = filtered[i];
        final id = c['id'] as int? ?? 1;
        final title = c['title'] as String? ?? '';
        final tag = c['tag'] as String? ?? '';
        final level = c['level'] as String? ?? 'Beginner';
        final modules = c['total_modules'] as int? ?? 0;
        final xp = c['total_xp'] as int? ?? 0;
        final icon = c['icon'] as String?;
        final subtitle = c['description'] as String? ?? '';
          final enrolled = _isEnrolled(c);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CourseCard(
              course: _CourseItem(
                title: title,
                subtitle: subtitle,
                tag: tag,
                level: level,
                modules: modules,
                xp: xp,
                icon: _iconData(icon),
                color: _colorFor(level),
                enrolled: enrolled,
                progress: _progressFor(c),
              ),
              index: i,
              enrolling: _enrolling.contains(id),
              onTap: () => context.go(AppRoutes.coursePath(id)),
              onEnroll: enrolled ? null : () => _handleEnroll(id),
            ),
          );
      },
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
            hintText: 'Search courses...',
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
    this.enrolling = false,
    this.onEnroll,
  });
  final _CourseItem course;
  final int index;
  final VoidCallback onTap;
  final bool enrolling;
  final VoidCallback? onEnroll;

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
                ? [BoxShadow(color: c.color.withValues(alpha: 0.05), blurRadius: 16)]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(c.icon, color: c.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.title,
                              style: AppTextStyles.bodyMd(color: AppColors.onSurface)
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (c.progress >= 1.0)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.secondary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(c.subtitle,
                        style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                            .copyWith(fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(label: c.tag, color: c.color),
                        const SizedBox(width: 6),
                        _Chip(label: c.level, color: _levelColor(c.level)),
                        const SizedBox(width: 6),
                        _Chip(label: '+${c.xp} XP', color: AppColors.secondary),
                      ],
                    ),
                    if (c.enrolled && c.progress > 0 && c.progress < 1.0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c.progress,
                          minHeight: 4,
                          backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(c.color),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.enrolling)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else if (widget.onEnroll != null)
                GestureDetector(
                  onTap: widget.onEnroll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("S'incrire",
                        style: AppTextStyles.labelSm(color: AppColors.onPrimary)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    ).staggered(widget.index, offsetY: 12);
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner': return AppColors.secondary;
      case 'Intermediate': return AppColors.primary;
      case 'Advanced': return AppColors.tertiary;
      default: return AppColors.outline;
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
