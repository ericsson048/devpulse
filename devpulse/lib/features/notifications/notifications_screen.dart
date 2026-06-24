import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService.instance;
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _notifications = List.from(_service.history);
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await _service.markAllAsRead();
    setState(() => _notifications = List.from(_service.history));
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Clear all notifications?',
            style: AppTextStyles.bodyMd(color: AppColors.onSurface)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true),
              child: Text('Clear', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      await _service.clearHistory();
      setState(() => _notifications = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Notifications',
            style: AppTextStyles.headlineMd(color: AppColors.onSurface)),
        actions: [
          if (_notifications.any((n) => !n.read))
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: AppTextStyles.labelSm(color: AppColors.primary)),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.onSurfaceVariant),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: () async => setState(() => _notifications = List.from(_service.history)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildNotificationCard(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.onSurfaceVariant, size: 36),
          ),
          const SizedBox(height: 20),
          Text('No notifications yet',
              style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Complete lessons and earn achievements\nto see notifications here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification n) {
    final (icon, color) = _iconForType(n.type);
    return GestureDetector(
      onTap: () => _service.markAsRead(n.id).then((_) {
        if (mounted) setState(() => _notifications = List.from(_service.history));
      }),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read ? AppColors.surfaceContainerHigh : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.read
                ? AppColors.outlineVariant.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: AppTextStyles.labelSm(color: AppColors.onSurface)
                                .copyWith(
                                  fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                                  fontSize: 13,
                                )),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n.body,
                      style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(_timeAgo(n.createdAt),
                      style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  (IconData, Color) _iconForType(String type) {
    switch (type) {
      case 'xp':
        return (Icons.auto_awesome_rounded, AppColors.primary);
      case 'achievement':
        return (Icons.workspace_premium_rounded, AppColors.tertiary);
      case 'streak':
        return (Icons.local_fire_department_rounded, AppColors.error);
      case 'lesson':
        return (Icons.check_circle_rounded, AppColors.secondary);
      case 'milestone':
        return (Icons.flag_rounded, AppColors.tertiary);
      default:
        return (Icons.notifications_rounded, AppColors.onSurfaceVariant);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
