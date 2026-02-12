import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hijri/hijri_calendar.dart';
import '../models/todo.dart';
import 'daily_zikr_service.dart';
import 'location_service.dart';

class WidgetService {
  static const String _tasksWidgetProvider = 'TasksWidgetProvider';
  static const String _sebhaWidgetProvider = 'SebhaWidgetProvider';
  static const String _prayerWidgetProvider = 'PrayerWidgetProvider';
  static const String _zikrWidgetProvider = 'ZikrWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(
      'group.com.antigravity.ramadan.ramadan_planner',
    );
  }

  /// Update Tasks Widget
  static Future<void> updateTasksWidget(List<TodoTask> tasks) async {
    try {
      final tasksJson = tasks.map((t) {
        return {
          'id': t.id,
          'title': t.title,
          'isCompleted': t.isCompleted,
          'date': t.date,
          'type': t.type,
        };
      }).toList();

      await HomeWidget.saveWidgetData<String>(
        'tasks_list',
        jsonEncode(tasksJson),
      );

      final doneCount = tasks.where((t) => t.isCompleted).length;
      final totalCount = tasks.length;

      await HomeWidget.saveWidgetData<int>('tasks_done_count', doneCount);
      await HomeWidget.saveWidgetData<int>('tasks_total_count', totalCount);

      await HomeWidget.updateWidget(androidName: _tasksWidgetProvider);
    } catch (e) {
      debugPrint('Error updating tasks widget: $e');
    }
  }

  /// Update Sebha Widget
  static Future<void> updateSebhaWidget(int count) async {
    try {
      await HomeWidget.saveWidgetData<int>('sebha_count', count);
      await HomeWidget.updateWidget(androidName: _sebhaWidgetProvider);
    } catch (e) {
      debugPrint('Error updating sebha widget: $e');
    }
  }

  /// Update Prayer Widget (Smart Native)
  static Future<void> updatePrayerWidget({
    required Map<String, DateTime> prayerTimes,
  }) async {
    try {
      // 1. Calculate Next Prayer for Immediate Display
      String nextPrayerName = "--";
      String nextPrayerTimeStr = "--:--";
      int nextPrayerMillis = 0;

      final now = DateTime.now();
      final prayers = prayerTimes.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final allowedNextPrayers = [
        'تهجد',
        'فجر',
        'ظهر (فرض)',
        'عصر',
        'مغرب',
        'عشاء',
      ];

      for (var entry in prayers) {
        if (allowedNextPrayers.contains(entry.key) &&
            entry.value.isAfter(now)) {
          nextPrayerName = entry.key;
          // Simplify name for Dhuhr if needed, or keep as is
          if (nextPrayerName == 'ظهر (فرض)') nextPrayerName = 'ظهر';

          nextPrayerTimeStr =
              "${entry.value.hour}:${entry.value.minute.toString().padLeft(2, '0')}";
          nextPrayerMillis = entry.value.millisecondsSinceEpoch;
          break;
        }
      }

      // If all passed, show Fajr next day (simplified, or just show --)
      // Ideally we should pass tomorrow's Fajr too.

      await HomeWidget.saveWidgetData<String>(
        'next_prayer_name',
        nextPrayerName,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_prayer_time',
        nextPrayerTimeStr,
      );
      await HomeWidget.saveWidgetData<int>(
        'next_prayer_millis',
        nextPrayerMillis,
      );

      // Save Hijri Date & Location
      final hijri = HijriCalendar.now();
      final hijriDateStr =
          "${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}";
      await HomeWidget.saveWidgetData<String>('hijri_date', hijriDateStr);

      // Get dynamic address
      await LocationService().determinePosition(); // Ensure fresh
      final address = LocationService().currentAddress;

      await HomeWidget.saveWidgetData<String>('location', address);

      // 2. Pass Full Day Schedule for Native Logic
      final todayPrayersJson = prayers.map((e) {
        String name = e.key;
        if (name == 'ظهر (فرض)') name = 'ظهر';

        return {
          'name': name,
          'time':
              "${e.value.hour}:${e.value.minute.toString().padLeft(2, '0')}",
          'millis': e.value.millisecondsSinceEpoch,
        };
      }).toList();

      await HomeWidget.saveWidgetData<String>(
        'today_prayers',
        jsonEncode(todayPrayersJson),
      );

      await HomeWidget.updateWidget(androidName: _prayerWidgetProvider);
    } catch (e) {
      debugPrint('Error updating prayer widget: $e');
    }
  }

  /// Update Zikr Widget (Smart Native)
  static Future<void> updateZikrWidget() async {
    try {
      // Pass the full list to the widget
      final allZikrs = DailyZikrService.getAllZikrs();
      await HomeWidget.saveWidgetData<String>(
        'zikr_list',
        jsonEncode(allZikrs),
      );

      // Also update current one
      final current = DailyZikrService.getDailyZikr();
      await HomeWidget.saveWidgetData<String>('zikr_text', current);

      await HomeWidget.updateWidget(androidName: _zikrWidgetProvider);
    } catch (e) {
      debugPrint('Error updating zikr widget: $e');
    }
  }
}
