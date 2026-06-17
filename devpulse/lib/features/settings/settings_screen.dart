import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_animations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _dailyReminder = true;
  bool _soundEffects = false;
  bool _haptics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.onSurface, size: 22),
        ),
        title: Text('Settings',
            style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // Account section
          _buildSectionLabel('Account'),
          _buildAccountCard(context),
          const SizedBox(height: 24),

          // Notifications
          _buildSectionLabel('Notifications'),
          _buildSettingsCard([
            _ToggleTile(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              subtitle: 'Receive app notifications',
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            _Divider(),
            _ToggleTile(
              icon: Icons.alarm_rounded,
              label: 'Daily Reminder',
              subtitle: 'Remind me to practice daily',
              value: _dailyReminder,
              onChanged: (v) => setState(() => _dailyReminder = v),
            ),
          ]).staggered(0),
          const SizedBox(height: 24),

          // Preferences
          _buildSectionLabel('Preferences'),
          _buildSettingsCard([
            _ToggleTile(
              icon: Icons.volume_up_rounded,
              label: 'Sound Effects',
              subtitle: 'Play sounds on interactions',
              value: _soundEffects,
              onChanged: (v) => setState(() => _soundEffects = v),
            ),
            _Divider(),
            _ToggleTile(
              icon: Icons.vibration_rounded,
              label: 'Haptic Feedback',
              subtitle: 'Vibrate on actions',
              value: _haptics,
              onChanged: (v) => setState(() => _haptics = v),
            ),
          ]).staggered(1),
          const SizedBox(height: 24),

          // App info
          _buildSectionLabel('About'),
          _buildSettingsCard([
            _NavTile(
              icon: Icons.info_outline_rounded,
              label: 'App Version',
              trailing: Text('1.0.0',
                  style: AppTextStyles.labelSm(
                      color: AppColors.onSurfaceVariant)),
              onTap: () {},
            ),
            _Divider(),
            _NavTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {},
            ),
            _Divider(),
            _NavTile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () {},
            ),
            _Divider(),
            _NavTile(
              icon: Icons.star_outline_rounded,
              label: 'Rate the App',
              onTap: () {},
            ),
          ]).staggered(2),
          const SizedBox(height: 24),

          // Danger zone
          _buildSectionLabel('Account Actions'),
          _buildSettingsCard([
            _NavTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              iconColor: AppColors.error,
              labelColor: AppColors.error,
              onTap: () => _showSignOutDialog(context),
            ),
            _Divider(),
            _NavTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Account',
              iconColor: AppColors.error,
              labelColor: AppColors.error,
              onTap: () => _showDeleteDialog(context),
            ),
          ]).staggered(3),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSm(color: AppColors.primary)
            .copyWith(letterSpacing: 2, fontSize: 11),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              color: AppColors.surfaceVariant,
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Developer',
                    style: AppTextStyles.bodyMd(color: AppColors.onSurface)
                        .copyWith(fontWeight: FontWeight.w700)),
                Text('dev@pulse.io',
                    style: AppTextStyles.labelSm(
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/app/profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text('Edit',
                  style: AppTextStyles.labelSm(color: AppColors.primary)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms);
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(children: children),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Sign Out',
        message: 'Are you sure you want to sign out?',
        confirmLabel: 'Sign Out',
        confirmColor: AppColors.error,
        onConfirm: () {
          Navigator.pop(context);
          context.go('/auth');
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Delete Account',
        message:
            'This will permanently delete your account and all progress. This cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.error,
        onConfirm: () {
          Navigator.pop(context);
          context.go('/auth');
        },
      ),
    );
  }
}

// ── Tiles ─────────────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.onSurfaceVariant, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodyMd(color: AppColors.onSurface)
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(subtitle,
                    style: AppTextStyles.labelSm(
                            color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.onSurfaceVariant,
            inactiveTrackColor:
                AppColors.surfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.onSurfaceVariant)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: iconColor ?? AppColors.onSurfaceVariant, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMd(
                          color: labelColor ?? AppColors.onSurface)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 66,
        color: AppColors.outlineVariant.withValues(alpha: 0.2),
      );
}

// ── Confirm dialog ────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
            const SizedBox(height: 12),
            Text(message,
                style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel',
                        style: AppTextStyles.labelSm(
                            color: AppColors.onSurfaceVariant)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: AppColors.onError,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(confirmLabel,
                        style: AppTextStyles.labelSm(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.85, 0.85),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}
