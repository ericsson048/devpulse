import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/app_animations.dart';
import '../../core/services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final int lessonId;
  const QuizScreen({super.key, required this.lessonId});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _quiz;
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int? _selected;
  bool _answered = false;
  int _timeLeft = 45;
  Timer? _timer;
  late final AnimationController _shakeCtrl;
  int _score = 0;
  bool _loading = true;
  String? _error;
  int _correctCount = 0;
  final List<int> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: 400.ms);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fetch lesson to get quiz_id
      final lesson = await ApiService.getLesson(widget.lessonId);
      final quizId = lesson['quiz_id'] as int?;
      if (quizId == null) {
        if (mounted) setState(() { _error = 'No quiz associated with this lesson'; _loading = false; });
        return;
      }
      final quizData = await ApiService.getQuiz(quizId);
      if (mounted) {
        setState(() {
          _quiz = quizData;
          _questions = quizData['questions'] as List<dynamic>? ?? [];
          _userAnswers.clear();
          _userAnswers.addAll(List.filled(_questions.length, -1));
          _timeLeft = quizData['time_limit_seconds'] as int? ?? 45;
          _loading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        if (!_answered) _checkAnswer();
      }
    });
  }

  dynamic get _currentQuestion =>
      _currentIndex < _questions.length ? _questions[_currentIndex] : null;

  String get _timerLabel {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  List<String> get _options {
    final q = _currentQuestion;
    if (q == null) return [];
    final opts = <String>[];
    if (q['option_a'] != null) opts.add(q['option_a'] as String);
    if (q['option_b'] != null) opts.add(q['option_b'] as String);
    if (q['option_c'] != null) opts.add(q['option_c'] as String);
    if (q['option_d'] != null) opts.add(q['option_d'] as String);
    return opts;
  }

  int get _correctIndex {
    final q = _currentQuestion;
    return (q?['correct_answer'] as int?) ?? 0;
  }

  void _checkAnswer() {
    if (_selected == null) return;
    final correct = _selected == _correctIndex;
    setState(() => _answered = true);
    _timer?.cancel();
    if (!correct) {
      _shakeCtrl.forward(from: 0);
    } else {
      _correctCount++;
    }
  }

  void _next() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _selected = null;
        _answered = false;
        _timeLeft = _quiz?['time_limit_seconds'] as int? ?? 45;
      });
      _startTimer();
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    final quizId = _quiz?['id'] as int?;
    if (quizId == null) {
      _navigateToResult();
      return;
    }
    final answers = <Map<String, dynamic>>[];
    for (int i = 0; i < _questions.length; i++) {
      answers.add({
        'question_id': _questions[i]['id'],
        'selected': _userAnswers[i],
      });
    }
    try {
      final result = await ApiService.submitQuiz(quizId, answers);
      final score = result['score'] as int? ?? _correctCount;
      final total = result['total'] as int? ?? _questions.length;
      final xpEarned = result['xp_earned'] as int? ?? 0;
      final quizTitle = _quiz?['title'] as String? ?? 'Quiz';
      final timeLimit = _quiz?['time_limit_seconds'] as int? ?? 0;
      final timeTaken = timeLimit - _timeLeft;
      if (mounted) {
        context.go(
          '/app/quiz-result?score=$score&total=$total&xp_earned=$xpEarned&quiz_title=${Uri.encodeComponent(quizTitle)}&time_taken=$timeTaken',
        );
      }
    } catch (_) {
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    final total = _questions.length;
    final quizTitle = _quiz?['title'] as String? ?? 'Quiz';
    if (mounted) {
      context.go(
        '/app/quiz-result?score=$_correctCount&total=$total&quiz_title=${Uri.encodeComponent(quizTitle)}',
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
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
                Text('Could not load quiz',
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
    final q = _currentQuestion;
    if (q == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DevPulseAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader().fadeSlideUp(),
            if (q['code_snippet'] != null) ...[
              const SizedBox(height: 20),
              _buildCodeBlock(q['code_snippet'] as String).fadeSlideUp(delay: 100.ms),
            ],
            const SizedBox(height: 20),
            ..._buildOptions(),
            const SizedBox(height: 20),
            _buildCheckButton().fadeSlideUp(delay: 500.ms),
            const SizedBox(height: 28),
            _buildBottomCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final q = _currentQuestion;
    final questionText = q?['question_text'] as String? ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text('QUESTION ${_currentIndex + 1} OF ${_questions.length}',
                    style: AppTextStyles.labelSm(color: AppColors.primary)
                        .copyWith(letterSpacing: 2, fontSize: 11)),
              ),
              const SizedBox(height: 10),
              Text(questionText,
                  style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _TimerBadge(label: _timerLabel, urgent: _timeLeft < 10),
      ],
    );
  }

  Widget _buildCodeBlock(String snippet) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                  bottom: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F57)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF28C840)),
                const Spacer(),
                Text('main.rs',
                    style: AppTextStyles.labelSm(
                            color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(snippet,
                  style: AppTextStyles.codeBlock(color: AppColors.onSurface)
                      .copyWith(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6), shape: BoxShape.circle),
      );

  void _selectAnswer(int idx) {
    if (_answered) return;
    setState(() => _selected = idx);
    _userAnswers[_currentIndex] = idx;
  }

  List<Widget> _buildOptions() {
    final opts = _options;
    return List.generate(opts.length, (i) {
      final selected = _selected == i;
      final correct = _answered && i == _correctIndex;
      final wrong = _answered && selected && i != _correctIndex;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _OptionCard(
          text: opts[i],
          selected: selected,
          correct: correct,
          wrong: wrong,
          answered: _answered,
          onTap: _answered ? null : () => _selectAnswer(i),
          shakeCtrl: wrong ? _shakeCtrl : null,
        ).staggered(i, offsetY: 12),
      );
    });
  }

  Widget _buildCheckButton() {
    return _PressableButton(
      onTap: _answered ? _next : _checkAnswer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: _answered ? AppColors.secondary : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (_answered ? AppColors.secondary : AppColors.primary)
                  .withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _answered ? 'Next Question →' : 'Check Answer',
              key: ValueKey(_answered),
              style: AppTextStyles.bodyLg(
                color: _answered ? AppColors.onSecondary : AppColors.onPrimary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCards() {
    final q = _currentQuestion;
    return Column(
      children: [
        // Explanation (shown after answering)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _answered ? AppColors.secondary.withValues(alpha: 0.3)
                    : AppColors.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.lightbulb,
                    color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EXPLANATION',
                        style: AppTextStyles.labelSm(color: AppColors.secondary)
                            .copyWith(letterSpacing: 1.5, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      _answered
                          ? (q?['explanation'] as String? ?? 'No explanation available')
                          : 'Submit your answer to see the explanation.',
                      style: AppTextStyles.bodyMd(
                              color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).fadeSlideUp(delay: 600.ms),
        const SizedBox(height: 12),
        // Daily XP card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.bolt, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text('DAILY XP GOAL',
                        style: AppTextStyles.labelSm(color: AppColors.onSurface)
                            .copyWith(letterSpacing: 1.5, fontSize: 11)),
                  ]),
                  Text('${_quiz?['xp_reward'] ?? 0} XP',
                      style: AppTextStyles.codeBlock(
                              color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              XpProgressBar(
                current: (_score * 100) ~/ (_questions.length > 0 ? _questions.length : 1),
                total: 100,
                showLabel: false,
              ),
              const SizedBox(height: 8),
              Text("You're 250 XP away from a new streak record!",
                  style: AppTextStyles.labelSm(
                          color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ).fadeSlideUp(delay: 700.ms),
      ],
    );
  }
}

// ── Option card with shake animation ─────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.text,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.answered,
    required this.onTap,
    this.shakeCtrl,
  });
  final String text;
  final bool selected, correct, wrong, answered;
  final VoidCallback? onTap;
  final AnimationController? shakeCtrl;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.outlineVariant.withValues(alpha: 0.3);
    Color bgColor = AppColors.surfaceContainerLow;
    if (correct) {
      borderColor = AppColors.secondary;
      bgColor = AppColors.secondary.withValues(alpha: 0.08);
    } else if (wrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.08);
    } else if (selected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.05);
    }

    Widget card = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: selected || correct
              ? [
                  BoxShadow(
                    color: (correct ? AppColors.secondary : AppColors.primary)
                        .withValues(alpha: 0.15),
                    blurRadius: 14,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: correct
                      ? AppColors.secondary
                      : wrong
                          ? AppColors.error
                          : selected
                              ? AppColors.primary
                              : AppColors.outline,
                  width: 2,
                ),
                color: (correct || wrong || selected)
                    ? (correct
                        ? AppColors.secondary
                        : wrong
                            ? AppColors.error
                            : AppColors.primary)
                    : Colors.transparent,
              ),
              child: (correct || wrong || selected)
                  ? const Icon(Icons.check, size: 12, color: AppColors.onPrimary)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMd(
                  color: (correct || wrong || selected)
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (correct)
              const Icon(Icons.check_circle,
                  color: AppColors.secondary, size: 18)
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 300.ms,
                      curve: Curves.easeOutBack),
            if (wrong)
              const Icon(Icons.cancel, color: AppColors.error, size: 18)
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 300.ms,
                      curve: Curves.easeOutBack),
          ],
        ),
      ),
    );

    // Shake on wrong
    if (shakeCtrl != null) {
      card = card
          .animate(controller: shakeCtrl)
          .shake(hz: 6, offset: const Offset(6, 0), duration: 400.ms);
    }

    return card;
  }
}

// ── Timer badge ───────────────────────────────────────────────────────────────
class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.label, required this.urgent});
  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: urgent
            ? AppColors.errorContainer.withValues(alpha: 0.3)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: urgent
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined,
              color: urgent ? AppColors.error : AppColors.secondary, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.codeBlock(
                  color: urgent ? AppColors.error : AppColors.onSurface)),
        ],
      ),
    )
        .animate(target: urgent ? 1 : 0)
        .shake(hz: 2, offset: const Offset(2, 0), duration: 300.ms);
  }
}

// ── Pressable button ──────────────────────────────────────────────────────────
class _PressableButton extends StatefulWidget {
  const _PressableButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 120.ms, lowerBound: 0.94);

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
