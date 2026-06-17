import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/app_animations.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int? _selected;
  bool _answered = false;
  int _timeLeft = 45;
  Timer? _timer;
  late final AnimationController _shakeCtrl;

  static const _options = [
    's1 is cloned and both are valid',
    's1 is moved to s2 and is no longer valid',
    's1 becomes a reference to s2',
    'A compile-time error occurs at the assignment',
  ];
  static const _correctIndex = 1;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: 400.ms);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _timerLabel {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _checkAnswer() {
    if (_selected == null) return;
    setState(() => _answered = true);
    _timer?.cancel();
    // Shake on wrong answer
    if (_selected != _correctIndex) {
      _shakeCtrl.forward(from: 0);
    }
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
            _buildHeader().fadeSlideUp(),
            const SizedBox(height: 20),
            _buildCodeBlock().fadeSlideUp(delay: 100.ms),
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
                child: Text('QUESTION 4 OF 10',
                    style: AppTextStyles.labelSm(color: AppColors.primary)
                        .copyWith(letterSpacing: 2, fontSize: 11)),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.headlineMd(color: AppColors.onSurface),
                  children: [
                    const TextSpan(text: 'What happens to '),
                    TextSpan(
                      text: 's1',
                      style: AppTextStyles.codeBlock(
                              color: AppColors.primaryFixedDim)
                          .copyWith(
                        backgroundColor:
                            AppColors.surfaceVariant.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    const TextSpan(text: ' after assignment to '),
                    TextSpan(
                      text: 's2',
                      style: AppTextStyles.codeBlock(
                              color: AppColors.primaryFixedDim)
                          .copyWith(
                        backgroundColor:
                            AppColors.surfaceVariant.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Animated timer
        _TimerBadge(label: _timerLabel, urgent: _timeLeft < 10),
      ],
    );
  }

  Widget _buildCodeBlock() {
    const kw = Color(0xFFFF79C6);
    const fn = Color(0xFF50FA7B);
    const str = Color(0xFFF1FA8C);
    const comment = Color(0xFF6272A4);
    const type = Color(0xFF8BE9FD);

    TextStyle s(Color c) =>
        AppTextStyles.codeBlock(color: c).copyWith(fontSize: 13);

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
            child: RichText(
              text: TextSpan(
                style: s(AppColors.onSurface),
                children: [
                  TextSpan(text: 'fn ', style: s(kw)),
                  TextSpan(text: 'main', style: s(fn)),
                  const TextSpan(text: '() {\n  '),
                  TextSpan(text: 'let ', style: s(kw)),
                  const TextSpan(text: 's1 = '),
                  TextSpan(text: 'String', style: s(type)),
                  TextSpan(text: '::', style: s(kw)),
                  TextSpan(text: 'from', style: s(kw)),
                  TextSpan(text: '("hello");\n  ', style: s(str)),
                  TextSpan(text: 'let ', style: s(kw)),
                  const TextSpan(text: 's2 = s1;\n  '),
                  TextSpan(text: '// What is the state of s1?\n  ',
                      style: s(comment)),
                  TextSpan(text: 'println!', style: s(fn)),
                  TextSpan(text: '("{}", s1);\n', style: s(str)),
                  const TextSpan(text: '}'),
                ],
              ),
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

  List<Widget> _buildOptions() {
    return List.generate(_options.length, (i) {
      final selected = _selected == i;
      final correct = _answered && i == _correctIndex;
      final wrong = _answered && selected && i != _correctIndex;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _OptionCard(
          text: _options[i],
          selected: selected,
          correct: correct,
          wrong: wrong,
          answered: _answered,
          onTap: _answered ? null : () => setState(() => _selected = i),
          shakeCtrl: wrong ? _shakeCtrl : null,
        ).staggered(i, offsetY: 12),
      );
    });
  }

  Widget _buildCheckButton() {
    return _PressableButton(
      onTap: _answered ? () => context.go('/app/quiz-result?score=7&total=10') : _checkAnswer,
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
    return Column(
      children: [
        // Hint card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
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
                    Text('HINT LEFT: 2/3',
                        style: AppTextStyles.labelSm(color: AppColors.secondary)
                            .copyWith(letterSpacing: 1.5, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      'Rust uses an ownership model. Think "shallow copy" vs "move".',
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
                  Text('750 / 1000 XP',
                      style: AppTextStyles.codeBlock(
                              color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              XpProgressBar(current: 750, total: 1000, showLabel: false),
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
