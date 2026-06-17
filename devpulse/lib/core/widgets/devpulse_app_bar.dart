import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Top app bar shared across all authenticated screens.
class DevPulseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DevPulseAppBar({
    super.key,
    this.actions,
    this.showLogo = true,
  });

  final List<Widget>? actions;
  final bool showLogo;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showLogo) ...[
                const Icon(Icons.terminal, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'DevPulse',
                  style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                      .copyWith(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
              const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
