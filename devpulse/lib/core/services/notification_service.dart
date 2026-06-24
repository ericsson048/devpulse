import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) =>
      AppNotification(id: id, title: title, body: body, type: type, createdAt: createdAt, read: read ?? this.read);

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'body': body, 'type': type,
    'createdAt': createdAt.toIso8601String(), 'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    type: j['type'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    read: j['read'] as bool? ?? false,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final List<AppNotification> _history = [];
  bool _initialized = false;

  Stream<AppNotification> get onNotification => _onNotificationController.stream;
  final _onNotificationController = StreamController<AppNotification>.broadcast();

  List<AppNotification> get history => List.unmodifiable(_history);
  int get unreadCount => _history.where((n) => !n.read).length;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    await _loadHistory();
    await _loadReminderPref();
    _initialized = true;
    await scheduleDailyReminder();
    await scheduleStreakReminder();
  }

  void _onTap(NotificationResponse response) {
    final notif = _history.where((n) => n.id == response.payload).firstOrNull;
    if (notif != null) _onNotificationController.add(notif);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notification_history');
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _history.addAll(list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)));
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_history.map((n) => n.toJson()).toList());
    await prefs.setString('notification_history', raw);
  }

  Future<String> _nextId() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt('notif_counter') ?? 0) + 1;
    await prefs.setInt('notif_counter', next);
    return 'notif_$next';
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required String type,
    int? xpAmount,
  }) async {
    if (!_initialized) return;

    final id = await _nextId();

    final androidDetails = AndroidNotificationDetails(
      'devpulse_channel',
      'DevPulse',
      channelDescription: 'Learning progress notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      id: int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? 0,
      title: title,
      body: body,
      notificationDetails: details,
      payload: id,
    );

    final notif = AppNotification(
      id: id, title: title, body: body, type: type,
      createdAt: DateTime.now(),
    );
    _history.insert(0, notif);
    if (_history.length > 100) _history.removeLast();
    await _saveHistory();
  }

  Future<void> markAsRead(String id) async {
    final idx = _history.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _history[idx] = _history[idx].copyWith(read: true);
    await _saveHistory();
  }

  Future<void> markAllAsRead() async {
    for (var i = 0; i < _history.length; i++) {
      _history[i] = _history[i].copyWith(read: true);
    }
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_history');
  }

  void dispose() {
    _onNotificationController.close();
  }

  // ── Scheduled helpers ──────────────────────────────────────────

  tz.TZDateTime _nextAt(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  Future<void> _scheduleRepeating(int id, int hour, int minute, String title, String body) async {
    final androidDetails = AndroidNotificationDetails(
      'devpulse_${id}_channel',
      title,
      channelDescription: body,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final iosDetails = const DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextAt(hour, minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Daily Reminder (10:00) ─────────────────────────────────────

  static const _dailyReminderId = 9999;
  static const _reminderEnabledKey = 'daily_reminder_enabled';

  bool get dailyReminderEnabled => _dailyReminderEnabled;
  bool _dailyReminderEnabled = true;

  Future<void> _loadReminderPref() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyReminderEnabled = prefs.getBool(_reminderEnabledKey) ?? true;
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    _dailyReminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
    if (enabled) {
      await scheduleDailyReminder();
    } else {
      await _plugin.cancel(id: _dailyReminderId);
    }
  }

  Future<void> scheduleDailyReminder() async {
    if (!_initialized || !_dailyReminderEnabled) return;

    final messages = [
      'Ready to level up? Spend 5 minutes learning something new!',
      'Small steps lead to big achievements. Open DevPulse now!',
      "Don't break your streak! A quick lesson keeps your skills sharp.",
      'Consistency beats intensity. 5 minutes today goes a long way.',
      'Every expert was once a beginner. Keep going!',
      "Your future self will thank you for today's effort.",
      'Code a little, learn a lot. One lesson at a time.',
      "You're closer than yesterday. Keep the momentum!",
      'Daily practice compounds into mastery. Start now!',
      'The best time to learn was yesterday. The next best is now.',
    ];
    final msg = messages[DateTime.now().millisecondsSinceEpoch % messages.length];
    await _scheduleRepeating(_dailyReminderId, 10, 0, '☕ Time to learn!', msg);
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
  }

  // ── Streak Reminder (20:00) ────────────────────────────────────

  static const _streakReminderId = 9998;

  Future<void> scheduleStreakReminder() async {
    if (!_initialized) return;
    final messages = [
      'Your streak is at risk! Complete a quick lesson to keep it alive.',
      'One more lesson today — finish strong and protect your streak!',
      'The day is almost over. Lock in your streak with a 5-minute lesson.',
      "Don't let today slip! Open DevPulse and keep your streak going.",
      'Streaks are built one day at a time. Do your lesson before bed!',
      'Future you will thank you for not breaking the chain. Learn now!',
      'Consistency is key. A short session is all it takes to maintain your streak.',
      'Almost done for the day — end it with a lesson and protect your streak!',
    ];
    final msg = messages[DateTime.now().millisecondsSinceEpoch % messages.length];
    await _scheduleRepeating(_streakReminderId, 20, 0, '🔥 Streak Saver', msg);
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(id: _streakReminderId);
  }

  // ── Delayed one-shot notification ──────────────────────────────

  Future<void> scheduleDelayedNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    if (!_initialized) return;
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    final androidDetails = AndroidNotificationDetails(
      'devpulse_delayed_${id}_channel',
      'DevPulse Reminders',
      channelDescription: 'Follow-up reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final iosDetails = const DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
