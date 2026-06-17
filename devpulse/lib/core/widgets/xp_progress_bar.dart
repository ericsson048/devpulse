import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.label = 'XP Progress',
    this.showLabel = true,
  });

  final int current;
  final int total;
  final String label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final pct = (current / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(),
                  style: AppTextStyles.labelSm(color: AppColors.primary)
                      .copyWith(letterSpacing: 2, fontSize: 11)),
              Text('$current / $total XP',
                  style: AppTextStyles.labelSm(
                      color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor:
                    AppColors.surfaceVariant.withValues(alpha: 0.5),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            // Neon glow overlay
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
