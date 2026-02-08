import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/worship.dart';
import '../services/database_helper.dart';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class WorshipProvider with ChangeNotifier {
  final PrayerService _prayerService = PrayerService();
  final NotificationService _notificationService = NotificationService();

  WorshipProvider() {
    _notificationService.init();
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
    await _notificationService.cancelAll();
    for (var entry in _entries) {
      if (!entry.isCompleted) {
        await scheduleNotification(entry);
      }
    }
  }

  Future<void> _updateWidget() async {
    final now = DateTime.now();
    WorshipEntry? next;
    for (var e in _entries) {
      if (e.time != null && e.time!.isAfter(now)) {
        next = e;
        break;
      }
    }

    if (next != null) {
      await WidgetService.updateWidget(
        nextPrayerName: next.prayerName,
        nextPrayerTime: DateFormat('hh:mm a').format(next.time!),
      );
    } else if (_entries.isNotEmpty && _entries.first.time != null) {
      await WidgetService.updateWidget(
        nextPrayerName: _entries.first.prayerName,
        nextPrayerTime: DateFormat('hh:mm a').format(_entries.first.time!),
      );
    }
  }

  Future<void> toggleWorship(int index) async {
    // Note: This matches original logic. Assuming index matches _entries.
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
    }
  }

  Future<void> scheduleNotification(WorshipEntry entry) async {
    if (entry.time == null) return;
    int id = entry.prayerName.hashCode;
    await _notificationService.schedulePrayerNotification(
      id: id,
      title: 'حان وقت صلاة ${entry.prayerName}',
      body: 'تذكير بأداء صلاة ${entry.prayerName} في وقتها',
      scheduledTime: entry.time!,
    );
  }
}
