import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/worship.dart';
import '../services/database_helper.dart';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorshipProvider with ChangeNotifier {
  final PrayerService _prayerService = PrayerService();
  final NotificationService _notificationService = NotificationService();

  WorshipProvider() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
    await _notificationService.requestPermissions();
    await loadEntries(DateTime.now());
  }

  final List<String> _faraidNames = ['فجر', 'ظهر (فرض)', 'عصر', 'مغرب', 'عشاء'];

  final List<String> _sunnahNames = [
    'تهجد',
    'صبح',
    'ضحى',
    'ظهر (سنة قبلية)',
    'ظهر (سنة بعدية)',
    'مغرب (سنة)',
    'عشاء (سنة)',
  ];

  final List<String> _allNamesOrdered = [
    'تهجد',
    'فجر',
    'صبح',
    'ضحى',
    'ظهر (سنة قبلية)',
    'ظهر (فرض)',
    'ظهر (سنة بعدية)',
    'عصر',
    'مغرب',
    'مغرب (سنة)',
    'عشاء',
    'عشاء (سنة)',
  ];

  List<WorshipEntry> _entries = [];
  List<WorshipEntry> get entries => _entries;

  List<WorshipEntry> get faraidEntries =>
      _entries.where((e) => _faraidNames.contains(e.prayerName)).toList();

  List<WorshipEntry> get sunnahEntries =>
      _entries.where((e) => _sunnahNames.contains(e.prayerName)).toList();

  List<String> get prayerNames => _allNamesOrdered;

  double get completionPercentage {
    if (_entries.isEmpty) return 0.0;
    int completed = _entries.where((e) => e.isCompleted).length;
    return completed / _entries.length;
  }

  WorshipEntry? get nextPrayer {
    final now = DateTime.now();
    final allowed = [..._faraidNames, 'تهجد'];
    for (var e in _entries) {
      if (allowed.contains(e.prayerName) &&
          e.time != null &&
          e.time!.isAfter(now)) {
        return e;
      }
    }
    return null;
  }

  WorshipEntry? get currentPrayer {
    final now = DateTime.now();
    WorshipEntry? last;
    for (var e in _entries) {
      if (e.time != null && e.time!.isBefore(now)) {
        last = e;
      } else if (e.time != null && e.time!.isAfter(now)) {
        break;
      }
    }
    return last;
  }

  Duration? get timeToNextPrayer {
    final next = nextPrayer;
    if (next?.time == null) return null;
    return next!.time!.difference(DateTime.now());
  }

  Future<void> loadEntries(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    _entries = await DatabaseHelper().getWorshipByDate(formattedDate);

    if (_entries.length < _allNamesOrdered.length) {
      for (String name in _allNamesOrdered) {
        if (!_entries.any((e) => e.prayerName == name)) {
          WorshipEntry newEntry = WorshipEntry(
            date: formattedDate,
            prayerName: name,
          );
          await DatabaseHelper().insertWorship(newEntry);
        }
      }
      _entries = await DatabaseHelper().getWorshipByDate(formattedDate);
    }

    final faraidTimes = _prayerService.getFaraidTimes(date);
    final sunnahTimes = _prayerService.getSunnahTimes(date);
    final allTimes = {...faraidTimes, ...sunnahTimes};

    _entries = _entries.map((e) {
      return e.copyWith(time: allTimes[e.prayerName]);
    }).toList();

    _entries.sort(
      (a, b) => _allNamesOrdered
          .indexOf(a.prayerName)
          .compareTo(_allNamesOrdered.indexOf(b.prayerName)),
    );

    notifyListeners();
    _updateWidget();
    _scheduleAllNotifications();
  }

  Future<void> _scheduleAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final bool sunnahEnabled = prefs.getBool('notify_sunnah') ?? true;

    for (String name in _allNamesOrdered) {
      await _notificationService.cancelNotification(name.hashCode);
    }

    for (var entry in _entries) {
      if (!entry.isCompleted) {
        // Only schedule if it's a Fard prayer OR if Sunnah reminders are enabled
        bool isFaraid = _faraidNames.contains(entry.prayerName);
        if (isFaraid || sunnahEnabled) {
          await scheduleNotification(entry);
        }
      }
    }
  }

  Future<void> _updateWidget() async {
    // Generate schedule for Today to ensure widget is always current
    final now = DateTime.now();
    final faraid = _prayerService.getFaraidTimes(now);
    final sunnah = _prayerService.getSunnahTimes(now);
    final allTimes = {...faraid, ...sunnah};

    await WidgetService.updatePrayerWidget(prayerTimes: allTimes);
  }

  Future<void> toggleWorship(int index) async {
    if (index < 0 || index >= _entries.length) return;
    WorshipEntry entry = _entries[index];
    await _toggleEntry(entry);
  }

  Future<void> toggleWorshipEntry(WorshipEntry entry) async {
    await _toggleEntry(entry);
  }

  Future<void> _toggleEntry(WorshipEntry entry) async {
    WorshipEntry updated = entry.copyWith(isCompleted: !entry.isCompleted);

    await DatabaseHelper().insertWorship(updated);

    int index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = updated;
      notifyListeners();
      await _updateWidget();
    }
  }

  Future<void> scheduleNotification(WorshipEntry entry) async {
    if (entry.time == null) return;

    DateTime scheduledTime = entry.time!;
    final now = DateTime.now();

    // If the time has passed for today, schedule it for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    int id = entry.prayerName.hashCode;
    await _notificationService.schedulePrayerNotification(
      id: id,
      title: 'حان وقت صلاة ${entry.prayerName}',
      body: 'تذكير بأداء صلاة ${entry.prayerName} في وقتها',
      scheduledTime: scheduledTime,
    );
  }
}
