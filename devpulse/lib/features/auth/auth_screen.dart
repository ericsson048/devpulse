import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  bool _obscure = true;
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _loading = false);
      context.go('/app/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Atmospheric glows
          Positioned(
            top: -80,
            right: -80,
            child: _Glow(color: AppColors.primary.withValues(alpha: 0.1), size: 400),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _Glow(color: AppColors.secondary.withValues(alpha: 0.06), size: 320),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      // Brand
                      _buildBrand(),
                      const SizedBox(height: 32),
                      // Auth card
                      _buildCard(),
                      const SizedBox(height: 16),
                      // Security footer
                      _buildSecurityFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.terminal, color: AppColors.primary, size: 36),
            const SizedBox(width: 10),
            Text('DevPulse',
                style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'LEVEL UP YOUR SYNTAX',
          style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
              .copyWith(letterSpacing: 3, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 32),
        ],
      ),
      child: Column(
        children: [
          // Tabs
          _buildTabs(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: Column(
              children: [
                // Email
                _buildField(
                  label: 'WORK EMAIL',
                  hint: 'dev@pulse.io',
                  controller: _emailCtrl,
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                // Password
                _buildPasswordField(),
                const SizedBox(height: 24),
                // Submit
                _buildSubmitButton(),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: AppColors.outlineVariant.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OAUTH 2.0 PROTOCOL',
                        style: AppTextStyles.labelSm(
                                color: AppColors.onSurfaceVariant)
                            .copyWith(fontSize: 10, letterSpacing: 1.5),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: AppColors.outlineVariant.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 20),
                // Social buttons
                Row(
                  children: [
                    Expanded(child: _SocialButton(label: 'GitHub', icon: Icons.code)),
                    const SizedBox(width: 12),
                    Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata)),
                  ],
                ),
              ],
            ),
          ),
          // XP momentum bar
          if (_loading)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'SIGN IN',
            active: _mode == _AuthMode.signIn,
            onTap: () => setState(() => _mode = _AuthMode.signIn),
          ),
          _Tab(
            label: 'SIGN UP',
            active: _mode == _AuthMode.signUp,
            onTap: () => setState(() => _mode = _AuthMode.signUp),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                .copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.codeBlock(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.codeBlock(color: AppColors.onSurfaceVariant)
                .copyWith(fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PASSWORD',
                style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                    .copyWith(letterSpacing: 1.5)),
            if (_mode == _AuthMode.signIn)
              TextButton(
                onPressed: () => context.go(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text('FORGOT?',
                    style: AppTextStyles.labelSm(color: AppColors.primaryFixedDim)
                        .copyWith(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: AppTextStyles.codeBlock(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: AppTextStyles.codeBlock(color: AppColors.onSurfaceVariant),
            prefixIcon:
                const Icon(Icons.lock_outline, color: AppColors.onSurfaceVariant, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final label = _mode == _AuthMode.signIn
        ? 'INITIALIZE SESSION'
        : 'CREATE DEVELOPER ACCOUNT';
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.labelSm(color: AppColors.onPrimary)
                    .copyWith(letterSpacing: 2, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.shield, color: AppColors.secondary, size: 14),
            const SizedBox(width: 6),
            Text('SECURED END-TO-END',
                style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                    .copyWith(fontSize: 10, letterSpacing: 1)),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text('TERMS',
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 10)),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text('PRIVACY',
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 10)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm(
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ).copyWith(letterSpacing: 2, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
      label: Text(label,
          style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceContainer,
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
