import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _prophetReminderEnabled = true;
  String _prophetReminderInterval = 'everyMinute';
  bool _sunnahReminderEnabled = true;
  bool _quranReminderEnabled = true;
  TimeOfDay _quranReminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _tasksReminderEnabled = true;
  int _tasksReminderFrequency = 1;

  bool get prophetReminderEnabled => _prophetReminderEnabled;
  String get prophetReminderInterval => _prophetReminderInterval;
  bool get sunnahReminderEnabled => _sunnahReminderEnabled;
  bool get quranReminderEnabled => _quranReminderEnabled;
  TimeOfDay get quranReminderTime => _quranReminderTime;
  bool get tasksReminderEnabled => _tasksReminderEnabled;
  int get tasksReminderFrequency => _tasksReminderFrequency;

  NotificationProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _prophetReminderEnabled = prefs.getBool('notify_prophet') ?? true;
    _prophetReminderInterval =
        prefs.getString('notify_prophet_interval') ?? 'everyMinute';
    _sunnahReminderEnabled = prefs.getBool('notify_sunnah') ?? true;
    _quranReminderEnabled = prefs.getBool('notify_quran') ?? true;

    final qHours = prefs.getInt('notify_quran_hour') ?? 21;
    final qMinutes = prefs.getInt('notify_quran_minute') ?? 0;
    _quranReminderTime = TimeOfDay(hour: qHours, minute: qMinutes);

    _tasksReminderEnabled = prefs.getBool('notify_tasks') ?? true;
    _tasksReminderFrequency = prefs.getInt('notify_tasks_frequency') ?? 1;

    // Refresh all schedules to ensure they are active
    await refreshAll();

    notifyListeners();
  }

  Future<void> toggleProphetReminder(bool enabled) async {
    _prophetReminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_prophet', enabled);
    await _updateProphetReminder();
    notifyListeners();
  }

  Future<void> setProphetInterval(String interval) async {
    _prophetReminderInterval = interval;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notify_prophet_interval', interval);
    await _updateProphetReminder();
    notifyListeners();
  }

  Future<void> _updateProphetReminder() async {
    if (_prophetReminderEnabled) {
      RepeatInterval interval = RepeatInterval.everyMinute;
      if (_prophetReminderInterval == 'hourly') {
        interval = RepeatInterval.hourly;
      }
      if (_prophetReminderInterval == 'daily') interval = RepeatInterval.daily;
      if (_prophetReminderInterval == 'weekly') {
        interval = RepeatInterval.weekly;
      }

      await _notificationService.scheduleProphetPrayerReminder(
        interval: interval,
      );
    } else {
      await _notificationService.cancelNotification(777);
    }
  }

  Future<void> toggleSunnahReminder(bool enabled) async {
    _sunnahReminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_sunnah', enabled);
    notifyListeners();
  }

  Future<void> toggleQuranReminder(bool enabled) async {
    _quranReminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_quran', enabled);
    await _updateQuranReminder();
    notifyListeners();
  }

  Future<void> setQuranTime(TimeOfDay time) async {
    _quranReminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notify_quran_hour', time.hour);
    await prefs.setInt('notify_quran_minute', time.minute);
    await _updateQuranReminder();
    notifyListeners();
  }

  Future<void> _updateQuranReminder() async {
    if (_quranReminderEnabled) {
      await _notificationService.scheduleQuranReminder(
        time: _quranReminderTime,
      );
    } else {
      await _notificationService.cancelNotification(8888);
    }
  }

  Future<void> toggleTasksReminder(bool enabled) async {
    _tasksReminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_tasks', enabled);
    await _updateTasksReminder();
    notifyListeners();
  }

  Future<void> setTasksFrequency(int frequency) async {
    _tasksReminderFrequency = frequency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notify_tasks_frequency', frequency);
    await _updateTasksReminder();
    notifyListeners();
  }

  Future<void> _updateTasksReminder() async {
    if (_tasksReminderEnabled) {
      await _notificationService.scheduleRandomTaskReminders(
        frequency: _tasksReminderFrequency,
      );
    } else {
      await _notificationService.scheduleRandomTaskReminders(frequency: 0);
    }
  }

  // Call this when user records progress for today
  Future<void> markQuranAsRead() async {
    if (_quranReminderEnabled) {
      // Logic: If already read today, we want ensures the next reminder is TOMORROW
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        _quranReminderTime.hour,
        _quranReminderTime.minute,
      );

      // Always add one day because we just read it today
      scheduledDate = scheduledDate.add(const Duration(days: 1));

      await _notificationService.scheduleQuranReminder(
        time: _quranReminderTime,
        forceTomorrow: true,
      );
    }
  }

  // Helper to trigger all on app start or settings refresh
  Future<void> refreshAll() async {
    await _updateProphetReminder();
    await _updateQuranReminder();
    await _updateTasksReminder();
  }
}
