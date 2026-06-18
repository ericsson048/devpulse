import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_animations.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.forgotPassword(_emailCtrl.text.trim());
      if (mounted) setState(() { _loading = false; _sent = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showToast(context, message: 'Failed: ${e.toString().replaceAll("HttpException: ", "")}', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const DotGridPainter())),
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Back button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.onSurface, size: 20),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 32),
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: AppColors.primary, size: 34),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        delay: 100.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),
                  Text('Reset Password',
                      style: AppTextStyles.displayLgMobile(
                              color: AppColors.onSurface)
                          .copyWith(fontSize: 28))
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your work email and we\'ll send you a link to reset your password.',
                    style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: 40),
                  // Form or success state
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _sent ? _buildSuccess() : _buildForm(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WORK EMAIL',
            style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                .copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.codeBlock(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'dev@pulse.io',
            hintStyle: AppTextStyles.codeBlock(
                    color: AppColors.onSurfaceVariant)
                .copyWith(fontSize: 14),
            prefixIcon: const Icon(Icons.alternate_email_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        const SizedBox(height: 24),
        _SubmitButton(loading: _loading, onTap: _submit)
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0, delay: 500.ms),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Text('Back to Sign In',
                style: AppTextStyles.labelSm(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              const Icon(Icons.mark_email_read_rounded,
                  color: AppColors.secondary, size: 48)
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 16),
              Text('Check your inbox!',
                  style: AppTextStyles.headlineMd(color: AppColors.secondary)),
              const SizedBox(height: 8),
              Text(
                'We sent a reset link to ${_emailCtrl.text}',
                style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.9, 0.9),
              duration: 500.ms,
              curve: Curves.easeOut,
            ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go('/auth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text('Back to Sign In',
                style: AppTextStyles.labelSm(color: AppColors.onPrimary)
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: 120.ms, lowerBound: 0.95);

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
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Text('SEND RESET LINK',
                    style: AppTextStyles.labelSm(color: AppColors.onPrimary)
                        .copyWith(
                            letterSpacing: 2, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
