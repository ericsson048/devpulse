import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/app_animations.dart';
import '../../core/services/api_service.dart';
import '../../core/router/app_router.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Map<String, dynamic>? _course;
  List<Map<String, dynamic>> _modules = [];
  Map<int, List<Map<String, dynamic>>> _lessons = {};
  bool _loading = true;
  String? _error;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CourseDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.courseId != widget.courseId) _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getCourse(widget.courseId),
        ApiService.getModules(widget.courseId),
      ]);
      if (!mounted) return;
      final course = results[0] as Map<String, dynamic>;
      final modules = (results[1] as List).cast<Map<String, dynamic>>();
      final lessons = <int, List<Map<String, dynamic>>>{};
      await Future.wait(modules.map((m) async {
        final id = m['id'] as int;
        try {
          final data = await ApiService.getModuleLessons(id);
          lessons[id] = data.cast<Map<String, dynamic>>();
        } catch (_) {
          lessons[id] = [];
        }
      }));
      if (!mounted) return;
      setState(() {
        _course = course;
        _modules = modules;
        _lessons = lessons;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String lessonTypeIcon(String type) {
    switch (type) {
      case 'code': return 'code';
      case 'quiz': return 'quiz';
      default: return 'theory';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DevPulseAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(opacity: 0.6, child: const Icon(Icons.error_outline, size: 48, color: AppColors.error)),
                        const SizedBox(height: 16),
                        Text(_error!, style: AppTextStyles.bodyMd(color: AppColors.error), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard().fadeSlideUp(),
                        const SizedBox(height: 32),
                        _buildCurriculum(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeroCard() {
    final title = _course?['title'] as String? ?? 'Course';
    final description = _course?['description'] as String? ?? '';
    final totalModules = _modules.length;
    final totalXp = _course?['total_xp'] as int? ?? 0;
    final level = _course?['level'] as String? ?? '';
    final language = _course?['language'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 40, spreadRadius: -4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.25),
                      AppColors.surfaceContainerHighest,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: CustomPaint(painter: const DotGridPainter(opacity: 0.06)),
                      ),
                    ),
                    Center(
                      child: Icon(_iconForLevel(level), size: 64, color: AppColors.primary.withValues(alpha: 0.35))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2500.ms, curve: Curves.easeInOut),
                    ),
                  ],
                ),
              ),
              Positioned(top: 16, left: 16, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12)],
                ),
                child: Text('$totalModules MODULES',
                    style: AppTextStyles.labelSm(color: AppColors.onPrimary).copyWith(fontSize: 11, letterSpacing: 1.5)),
              ).scaleIn(delay: 200.ms)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.displayLgMobile(color: AppColors.primary)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description, style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20, runSpacing: 12,
                  children: [
                    _StatChip(icon: Icons.menu_book, label: 'Modules', value: '$totalModules', color: AppColors.primary).staggered(0),
                    _StatChip(icon: Icons.workspace_premium, label: 'XP', value: '$totalXp XP', color: AppColors.tertiary).staggered(1),
                    if (level.isNotEmpty)
                      _StatChip(icon: Icons.trending_up, label: 'Level', value: level[0].toUpperCase() + level.substring(1), color: AppColors.secondary).staggered(2),
                    if (language.isNotEmpty)
                      _StatChip(icon: Icons.code, label: 'Language', value: language, color: AppColors.neonBlue).staggered(3),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculum() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Modules', style: AppTextStyles.headlineMd(color: AppColors.onSurface)).fadeSlideLeft(delay: 100.ms),
            Row(
              children: [
                NeonPulse(
                  child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                ),
                const SizedBox(width: 6),
                Text('${_modules.length} Modules', style: AppTextStyles.labelSm(color: AppColors.primary)),
              ],
            ).fadeSlideLeft(delay: 150.ms),
          ],
        ),
        const SizedBox(height: 16),
        if (_modules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No modules yet', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant))),
          )
        else
          ..._modules.asMap().entries.map((e) {
            final i = e.key;
            final mod = e.value;
            final modId = mod['id'] as int;
            final modTitle = mod['title'] as String? ?? '';
            final modLessons = _lessons[modId] ?? [];
            final isExpanded = _expanded.contains(modId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) { _expanded.remove(modId); }
                          else { _expanded.add(modId); }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.folder_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(modTitle, style: AppTextStyles.bodyLg(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${modLessons.length} lesson${modLessons.length != 1 ? 's' : ''} · ${mod['total_xp'] ?? 0} XP',
                                    style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant).copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded) ...[
                      const Divider(height: 1, thickness: 0.5, color: AppColors.outlineVariant),
                      ...modLessons.asMap().entries.map((l) {
                        final li = l.key;
                        final lesson = l.value;
                        final isPublished = lesson['is_published'] == true;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: _LessonCard(
                            number: '${(li + 1).toString().padLeft(2, '0')}',
                            title: lesson['title'] as String? ?? '',
                            subtitle: lesson['lesson_type'] as String? ?? 'theory',
                            locked: !isPublished,
                            onTap: isPublished ? () => context.go(AppRoutes.lessonPath(lesson['id'] as int)) : null,
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ).staggered(i, offsetY: 16),
            );
          }),
      ],
    );
  }

  IconData _iconForLevel(String level) {
    switch (level) {
      case 'advanced': return Icons.auto_awesome;
      case 'intermediate': return Icons.trending_up;
      default: return Icons.storage_rounded;
    }
  }
}

// ── Lesson card (same style as module_screen) ────────────────────────────
class _LessonCard extends StatefulWidget {
  const _LessonCard({required this.number, required this.title, required this.subtitle, required this.locked, this.onTap});
  final String number;
  final String title;
  final String subtitle;
  final bool locked;
  final VoidCallback? onTap;

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: 200.ms);
  late final Animation<double> _slide = Tween<double>(begin: 0, end: 8).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late final Animation<double> _glow = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(
          offset: Offset(_slide.value, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color.lerp(AppColors.outlineVariant.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.4), _glow.value)!,
              ),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06 * _glow.value), blurRadius: 12)],
            ),
            child: child,
          ),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _glow,
              builder: (_, __) => Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color.lerp(AppColors.outlineVariant, AppColors.primary, _glow.value)!, width: 2),
                ),
                child: Center(child: Text(widget.number, style: AppTextStyles.codeBlock(color: Color.lerp(AppColors.outline, AppColors.primary, _glow.value)!).copyWith(fontSize: 14))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.bodyMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle, style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant).copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(widget.locked ? Icons.lock_outline : Icons.lock_open_outlined,
                color: widget.locked ? AppColors.onSurfaceVariant.withValues(alpha: 0.2) : AppColors.onSurfaceVariant.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant).copyWith(fontSize: 11)),
            Text(value, style: AppTextStyles.bodyMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
