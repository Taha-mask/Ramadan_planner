import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _prophetReminderEnabled = true;
  String _prophetReminderInterval = 'everyMinute';
  bool _sunnahReminderEnabled = true;
  bool _quranReminderEnabled = false;
  TimeOfDay _quranReminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _goodHabitsReminderEnabled = false;
  int _goodHabitsFrequency = 1;
  bool _tasksReminderEnabled = false;
  int _tasksFrequency = 3;

  bool get prophetReminderEnabled => _prophetReminderEnabled;
  String get prophetReminderInterval => _prophetReminderInterval;
  bool get sunnahReminderEnabled => _sunnahReminderEnabled;
  bool get quranReminderEnabled => _quranReminderEnabled;
  TimeOfDay get quranReminderTime => _quranReminderTime;
  bool get goodHabitsReminderEnabled => _goodHabitsReminderEnabled;
  int get goodHabitsFrequency => _goodHabitsFrequency;
  bool get tasksReminderEnabled => _tasksReminderEnabled;
  int get tasksFrequency => _tasksFrequency;

  NotificationProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _prophetReminderEnabled = prefs.getBool('notify_prophet') ?? true;
    _prophetReminderInterval =
        prefs.getString('notify_prophet_interval') ?? 'everyMinute';
    _sunnahReminderEnabled = prefs.getBool('notify_sunnah') ?? true;
    _quranReminderEnabled = prefs.getBool('notify_quran') ?? false;

    final qHours = prefs.getInt('notify_quran_hour') ?? 21;
    final qMinutes = prefs.getInt('notify_quran_minute') ?? 0;
    _quranReminderTime = TimeOfDay(hour: qHours, minute: qMinutes);

    _goodHabitsReminderEnabled = prefs.getBool('notify_good_habits') ?? false;
    _goodHabitsFrequency = prefs.getInt('notify_good_habits_frequency') ?? 1;

    _tasksReminderEnabled = prefs.getBool('notify_tasks') ?? false;
    _tasksFrequency = prefs.getInt('notify_tasks_frequency') ?? 3;

    notifyListeners();
    // Refresh all notifications to ensure they are scheduled on app start
    await refreshAll();
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
    await prefs.commit(); // Ensure data is saved immediately
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

  Future<void> toggleGoodHabitsReminder(bool enabled) async {
    _goodHabitsReminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_good_habits', enabled);
    await _updateGoodHabitsReminder();
    notifyListeners();
  }

  Future<void> setGoodHabitsFrequency(int frequency) async {
    _goodHabitsFrequency = frequency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notify_good_habits_frequency', frequency);
    await _updateGoodHabitsReminder();
    notifyListeners();
  }

  Future<void> _updateGoodHabitsReminder() async {
    if (_goodHabitsReminderEnabled) {
      await _notificationService.scheduleRandomHabitReminders(
        frequency: _goodHabitsFrequency,
      );
    } else {
      await _notificationService.scheduleRandomHabitReminders(frequency: 0);
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

  Future<void> toggleTasksReminder(bool enabled) async {
    _tasksReminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_tasks', enabled);
    await _updateTasksReminder();
    notifyListeners();
  }

  Future<void> setTasksFrequency(int frequency) async {
    _tasksFrequency = frequency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notify_tasks_frequency', frequency);
    await _updateTasksReminder();
    notifyListeners();
  }

  Future<void> _updateTasksReminder() async {
    if (_tasksReminderEnabled) {
      await _notificationService.scheduleRandomTaskReminders(
        frequency: _tasksFrequency,
      );
    } else {
      await _notificationService.scheduleRandomTaskReminders(frequency: 0);
    }
  }

  // Helper to trigger all on app start or settings refresh
  Future<void> refreshAll() async {
    await _updateProphetReminder();
    await _updateQuranReminder();
    await _updateGoodHabitsReminder();
    await _updateTasksReminder();
  }
}
