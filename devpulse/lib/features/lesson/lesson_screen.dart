import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/dp_markdown.dart';
import '../../core/utils/app_animations.dart';
import '../../core/utils/app_config.dart';
import '../../core/services/api_service.dart';
import '../../core/router/app_router.dart';

// ── Data model (matches LessonOut from backend) ───────────────────
class LessonData {
  final int id;
  final int moduleId;
  final String title;
  final String lessonType;
  final String? content;
  final String? videoUrl;
  final List<LessonResource> resources;
  final String? codeTemplate;
  final String? codeLanguage;
  final bool hasEditor;
  final int xpReward;

  const LessonData({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.lessonType,
    this.content,
    this.videoUrl,
    this.resources = const [],
    this.codeTemplate,
    this.codeLanguage,
    this.hasEditor = false,
    required this.xpReward,
  });

  factory LessonData.fromJson(Map<String, dynamic> j) {
    List<LessonResource> res = [];
    if (j['resources'] != null) {
      try {
        final raw = jsonDecode(j['resources'] as String) as List;
        res = raw.map((e) => LessonResource.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return LessonData(
      id: j['id'] as int,
      moduleId: j['module_id'] as int? ?? 0,
      title: j['title'] as String,
      lessonType: j['lesson_type'] as String? ?? 'theory',
      content: j['content'] as String?,
      videoUrl: j['video_url'] as String?,
      resources: res,
      codeTemplate: j['code_template'] as String?,
      codeLanguage: j['code_language'] as String?,
      hasEditor: j['has_editor'] as bool? ?? false,
      xpReward: j['xp_reward'] as int? ?? 25,
    );
  }
}

class LessonResource {
  final String title;
  final String url;
  final String type; // link | pdf | github | video

  const LessonResource({
    required this.title,
    required this.url,
    required this.type,
  });

  factory LessonResource.fromJson(Map<String, dynamic> j) => LessonResource(
        title: j['title'] as String? ?? '',
        url: j['url'] as String? ?? '',
        type: j['type'] as String? ?? 'link',
      );
}

// ── Screen ────────────────────────────────────────────────────────
class LessonScreen extends StatefulWidget {
  final int? lessonId;

  const LessonScreen({super.key, this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  bool _completed = false;
  LessonData? _lesson;
  bool _loading = true;
  String? _error;

  // Code editor state
  late final TextEditingController _codeCtrl;
  bool _running = false;
  bool _hasOutput = false;
  late final AnimationController _runCtrl =
      AnimationController(vsync: this, duration: 1500.ms);

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController();
    _load();
  }

  @override
  void didUpdateWidget(covariant LessonScreen old) {
    super.didUpdateWidget(old);
    if (old.lessonId != widget.lessonId) _load();
  }

  Future<void> _load() async {
    if (widget.lessonId == null) {
      setState(() { _loading = false; _error = 'No lesson selected'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getLesson(widget.lessonId!);
      if (!mounted) return;
      final lesson = LessonData.fromJson(data);
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
      _codeCtrl.text = lesson.codeTemplate ?? '';
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _runCtrl.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    setState(() { _running = true; _hasOutput = false; });
    _runCtrl.forward(from: 0);
    await Future.delayed(1600.ms);
    if (mounted) setState(() { _running = false; _hasOutput = true; });
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
              : _lesson == null
                  ? const Center(child: Text('Lesson not found'))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                      child: _buildLessonContent(),
                    ),
    );
  }

  Widget _buildLessonContent() {
    final l = _lesson!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBreadcrumbs(),
        const SizedBox(height: 16),
        _buildHeader(l).fadeSlideUp(),
        const SizedBox(height: 24),

        // ── Video (if present) ─────────────────────────────
        if (l.videoUrl != null) ...[
          _buildVideoPlayer(AppConfig.mediaUrl(l.videoUrl!)).fadeSlideUp(delay: 100.ms),
          const SizedBox(height: 32),
        ],

        // ── Markdown content ───────────────────────────────
        if (l.content != null && l.content!.isNotEmpty) ...[
          _buildMarkdownContent(l.content!),
          const SizedBox(height: 32),
        ],

        // ── Resources ─────────────────────────────────────
        if (l.resources.isNotEmpty) ...[
          _buildResources(l).fadeSlideUp(delay: 200.ms),
          const SizedBox(height: 32),
        ],

        // ── Inline Code Editor ─────────────────────────────
        if (l.hasEditor) ...[
          _buildEditorSection(l).fadeSlideUp(delay: 300.ms),
          const SizedBox(height: 32),
        ],

        // ── Completion ─────────────────────────────────────
        _buildCompletion(context).fadeSlideUp(delay: 400.ms),
      ],
    );
  }

  // ── Breadcrumbs ───────────────────────────────────────────────
  Widget _buildBreadcrumbs() {
    final l = _lesson!;
    return Row(
      children: [
        _Crumb(label: 'Library', onTap: () => context.go('/app/library')),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.onSurfaceVariant),
        _Crumb(label: 'Module', onTap: () => context.go(AppRoutes.modulePath(l.moduleId))),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.onSurfaceVariant),
        Flexible(
          child: Text(
            l.title,
            style: AppTextStyles.labelSm(color: AppColors.primary)
                .copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(LessonData lesson) {
    final typeColor = lesson.lessonType == 'code'
        ? AppColors.secondary
        : lesson.lessonType == 'quiz'
            ? AppColors.tertiary
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lesson.title,
            style: AppTextStyles.displayLgMobile(color: AppColors.onSurface)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _MetaBadge(
              icon: lesson.lessonType == 'code'
                  ? Icons.code
                  : lesson.lessonType == 'quiz'
                      ? Icons.quiz_outlined
                      : Icons.article_outlined,
              label: lesson.lessonType.toUpperCase(),
              color: typeColor,
            ),
            _MetaBadge(
              icon: Icons.workspace_premium_outlined,
              label: '+${lesson.xpReward} XP',
              color: AppColors.tertiary,
            ),
            if (lesson.hasEditor)
              _MetaBadge(
                icon: Icons.terminal,
                label: lesson.codeLanguage?.toUpperCase() ?? 'CODE',
                color: AppColors.secondary,
              ),
          ],
        ),
      ],
    );
  }

  // ── Video Player ──────────────────────────────────────────────
  Widget _buildVideoPlayer(String url) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 32,
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.2),
                  AppColors.surfaceContainerHighest,
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow, color: AppColors.onPrimary, size: 32),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ondemand_video, color: Colors.white70, size: 13),
                  const SizedBox(width: 6),
                  Text('Watch video',
                      style: AppTextStyles.labelSm(color: Colors.white70)
                          .copyWith(fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Markdown Content ──────────────────────────────────────────
  Widget _buildMarkdownContent(String content) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: DpMarkdown(data: content),
    ).fadeSlideUp(delay: 100.ms);
  }

  // ── Resources ─────────────────────────────────────────────────
  Widget _buildResources(LessonData lesson) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.attach_file_rounded,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Resources',
                style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 12),
        ...lesson.resources.asMap().entries.map((e) =>
            _ResourceCard(resource: e.value).staggered(e.key)),
      ],
    );
  }

  // ── Inline Code Editor ─────────────────────────────────────────
  Widget _buildEditorSection(LessonData lesson) {
    final langColor = _langColor(lesson.codeLanguage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: langColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.terminal, color: langColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Code Editor',
                style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
            const Spacer(),
            if (lesson.codeLanguage != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: langColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(lesson.codeLanguage!,
                    style: AppTextStyles.labelSm(color: langColor)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Editor container
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              // Toolbar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border(
                      bottom: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    _trafficDot(const Color(0xFFFF5F57)),
                    const SizedBox(width: 6),
                    _trafficDot(const Color(0xFFFFBD2E)),
                    const SizedBox(width: 6),
                    _trafficDot(const Color(0xFF28C840)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _codeCtrl.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.content_copy,
                              size: 14,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 5),
                          Text('Copy',
                              style: AppTextStyles.labelSm(
                                      color: AppColors.onSurfaceVariant)
                                  .copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Code input
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 160, maxHeight: 320),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line numbers
                      Container(
                        width: 40,
                        color: const Color(0xFF0A0F16),
                        padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
                        child: Column(
                          children: List.generate(
                            (_codeCtrl.text.split('\n').length + 1)
                                .clamp(8, 30),
                            (i) => Text(
                              '${i + 1}',
                              style: AppTextStyles.codeBlock(
                                color: AppColors.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                              ).copyWith(fontSize: 12, height: 1.65),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _codeCtrl,
                          maxLines: null,
                          expands: true,
                          onChanged: (_) => setState(() {}),
                          style: AppTextStyles.codeBlock(
                                  color: AppColors.onSurface)
                              .copyWith(fontSize: 13, height: 1.65),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Run bar
              _buildRunBar(langColor),

              // Output panel
              if (_hasOutput || _running) _buildOutput(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trafficDot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6), shape: BoxShape.circle),
      );

  Widget _buildRunBar(Color langColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          NeonPulse(
            color: _running ? AppColors.secondary : AppColors.primary,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _running ? AppColors.secondary : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _running ? 'Running…' : _hasOutput ? 'Completed' : 'Ready',
            style: AppTextStyles.labelSm(
              color: _running
                  ? AppColors.secondary
                  : _hasOutput
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
            ).copyWith(fontSize: 12),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _running ? null : _runCode,
            child: AnimatedContainer(
              duration: 200.ms,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _running ? langColor.withValues(alpha: 0.3) : langColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _running
                    ? null
                    : [
                        BoxShadow(
                          color: langColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                        )
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_running)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary),
                    )
                  else
                    const Icon(Icons.play_arrow_rounded,
                        color: AppColors.onPrimary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _running ? 'Running' : 'Run',
                    style: AppTextStyles.labelSm(color: AppColors.onPrimary)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F16),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(
          top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Output header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal,
                    color: AppColors.onSurfaceVariant, size: 13),
                const SizedBox(width: 8),
                Text('OUTPUT',
                    style: AppTextStyles.labelSm(
                            color: AppColors.onSurfaceVariant)
                        .copyWith(letterSpacing: 1.5, fontSize: 11)),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      setState(() { _hasOutput = false; _running = false; }),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.onSurfaceVariant, size: 16),
                ),
              ],
            ),
          ),
          // Output content
          Padding(
            padding: const EdgeInsets.all(14),
            child: _running
                ? Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: AnimatedBuilder(
                          animation: _runCtrl,
                          builder: (_, __) => CircularProgressIndicator(
                            value: _runCtrl.value,
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Compiling…',
                          style: AppTextStyles.codeBlock(
                                  color: AppColors.onSurfaceVariant)
                              .copyWith(fontSize: 12)),
                    ],
                  )
                : Text(
                    'Hello, DevPulse!\nProcess finished with exit code 0',
                    style: AppTextStyles.codeBlock(
                            color: AppColors.secondary)
                        .copyWith(fontSize: 13, height: 1.7),
                  ).animate().fadeIn(duration: 400.ms),
          ),
        ],
      ),
    ).animate().slideY(
          begin: 0.3,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOut,
        ).fadeIn(duration: 300.ms);
  }

  // ── Completion ────────────────────────────────────────────────
  Widget _buildCompletion(BuildContext context) {
    final l = _lesson!;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: CircularProgressIndicator(
                value: 0.75,
                strokeWidth: 4,
                backgroundColor: AppColors.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            Icon(
              _completed ? Icons.check_circle : Icons.check_circle_outline,
              size: 36,
              color: _completed
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('+${l.xpReward} XP',
                    style: AppTextStyles.labelSm(
                            color: AppColors.onTertiary)
                        .copyWith(
                            fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Lesson Complete?',
            style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
        const SizedBox(height: 8),
        const Text(
          'Mark this lesson as complete to earn your XP and unlock the next one.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() => _completed = true);
              Future.delayed(600.ms, () {
                if (mounted) context.go('/app/quiz');
              });
            },
            icon: Text(
              _completed ? 'Completed!' : 'Mark as Complete',
              style: AppTextStyles.bodyMd(
                color: _completed
                    ? AppColors.onSecondary
                    : AppColors.onPrimary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            label: Icon(
              _completed ? Icons.check : Icons.auto_awesome,
              color: _completed
                  ? AppColors.onSecondary
                  : AppColors.onPrimary,
              size: 20,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _completed ? AppColors.secondary : AppColors.primary,
              foregroundColor:
                  _completed ? AppColors.onSecondary : AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        XpProgressBar(current: 8450, total: 10000, label: 'Level 42 Progress'),
      ],
    );
  }

  Color _langColor(String? lang) {
    switch (lang?.toLowerCase()) {
      case 'python': return AppColors.secondary;
      case 'javascript':
      case 'typescript': return AppColors.tertiary;
      case 'dart': return AppColors.primary;
      case 'rust': return const Color(0xFFE07B39);
      case 'go': return const Color(0xFF00ADD8);
      default: return AppColors.primary;
    }
  }
}

// ── Resource Card ─────────────────────────────────────────────────
class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});
  final LessonResource resource;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(resource.type);
    // Resolve local media paths to full URLs
    final resolvedUrl = AppConfig.mediaUrl(resource.url);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.title,
                    style: AppTextStyles.bodyMd(color: AppColors.onSurface)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(resolvedUrl,
                    style: AppTextStyles.labelSm(
                            color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.open_in_new_rounded,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              size: 18),
        ],
      ),
    );
  }

  (IconData, Color) _iconAndColor(String type) {
    switch (type) {
      case 'pdf': return (Icons.picture_as_pdf_outlined, AppColors.tertiary);
      case 'github': return (Icons.code_rounded, AppColors.onSurface);
      case 'video': return (Icons.ondemand_video_outlined, AppColors.secondary);
      default: return (Icons.link_rounded, AppColors.primary);
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────
class _Crumb extends StatelessWidget {
  const _Crumb({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
              .copyWith(fontSize: 12)),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.labelSm(
                      color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}


