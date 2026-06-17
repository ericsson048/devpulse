import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/app_animations.dart';
import '../../core/services/api_service.dart';
import '../../core/router/app_router.dart';

class ModuleScreen extends StatefulWidget {
  final int? moduleId;
  const ModuleScreen({super.key, this.moduleId});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  Map<String, dynamic>? _module;
  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ModuleScreen old) {
    super.didUpdateWidget(old);
    if (old.moduleId != widget.moduleId) _load();
  }

  Future<void> _load() async {
    if (widget.moduleId == null) {
      setState(() { _loading = false; _error = 'No module selected'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getModule(widget.moduleId!),
        ApiService.getModuleLessons(widget.moduleId!),
      ]);
      if (!mounted) return;
      setState(() {
        _module = results[0] as Map<String, dynamic>;
        _lessons = (results[1] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _lessonTypeIcon(String type) {
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
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(context).fadeSlideUp(),
                      const SizedBox(height: 32),
                      _buildCurriculum(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final title = _module?['title'] as String? ?? 'Module';
    final description = _module?['description'] as String? ?? '';
    final totalLessons = (_module?['total_lessons'] as int? ?? 0);
    final totalXp = (_module?['total_xp'] as int? ?? 0);

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
                      child: Icon(Icons.functions, size: 64, color: AppColors.primary.withValues(alpha: 0.35))
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
                child: Text('${_lessons.where((l) => l['is_published'] == true).length} LESSONS',
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
                Row(
                  children: [
                    _StatChip(icon: Icons.menu_book, label: 'Lessons', value: '$totalLessons', color: AppColors.primary).staggered(0),
                    const SizedBox(width: 20),
                    _StatChip(icon: Icons.workspace_premium, label: 'XP', value: '$totalXp XP', color: AppColors.tertiary).staggered(1),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculum(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Curriculum', style: AppTextStyles.headlineMd(color: AppColors.onSurface)).fadeSlideLeft(delay: 100.ms),
            Row(
              children: [
                NeonPulse(
                  child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                ),
                const SizedBox(width: 6),
                Text('${_lessons.length} Lessons', style: AppTextStyles.labelSm(color: AppColors.primary)),
              ],
            ).fadeSlideLeft(delay: 150.ms),
          ],
        ),
        const SizedBox(height: 16),
        ..._lessons.asMap().entries.map((e) {
          final i = e.key;
          final l = e.value;
          final isPublished = l['is_published'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LessonCard(
              number: '${(i + 1).toString().padLeft(2, '0')}',
              title: l['title'] as String? ?? '',
              subtitle: l['lesson_type'] as String? ?? 'theory',
              locked: !isPublished,
              onTap: isPublished ? () => context.go(AppRoutes.lessonPath(l['id'] as int)) : null,
            ).staggered(i, offsetY: 16),
          );
        }),
      ],
    );
  }
}

// ── Lesson card ───────────────────────────────────────────────────────────────
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.lerp(AppColors.outlineVariant.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.5), _glow.value)!,
              ),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08 * _glow.value), blurRadius: 16)],
            ),
            child: child,
          ),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _glow,
              builder: (_, __) => Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color.lerp(AppColors.outlineVariant, AppColors.primary, _glow.value)!, width: 2),
                ),
                child: Center(child: Text(widget.number, style: AppTextStyles.codeBlock(color: Color.lerp(AppColors.outline, AppColors.primary, _glow.value)!).copyWith(fontSize: 16))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.bodyLg(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle, style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant).copyWith(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(widget.locked ? Icons.lock_outline : Icons.lock_open_outlined,
                color: widget.locked ? AppColors.onSurfaceVariant.withValues(alpha: 0.2) : AppColors.onSurfaceVariant.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
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
