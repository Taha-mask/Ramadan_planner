import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/database_helper.dart';
import '../models/daily_entry.dart';
import '../services/analytics_service.dart';
import '../services/daily_zikr_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class HistoryProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _prayerStats = [];
  List<Map<String, dynamic>> _assessmentStats = [];
  List<Map<String, dynamic>> _azkarStats = [];
  List<DailyEntry> _history = [];
  List<String> _weakPoints = [];
  double _tahajjudCorrelation = 0.0;
  int _currentStreak = 0;
  double _last30DaysAverage = 0.0;
  int _totalPrayers30Days = 0;
  int _totalTasks30Days = 0;

  List<Map<String, dynamic>> get prayerStats => _prayerStats;
  List<Map<String, dynamic>> get assessmentStats => _assessmentStats;
  List<Map<String, dynamic>> get azkarStats => _azkarStats;
  List<DailyEntry> get history => _history;
  List<String> get weakPoints => _weakPoints;
  double get tahajjudCorrelation => _tahajjudCorrelation;
  int get currentStreak => _currentStreak;
  double get last30DaysAverage => _last30DaysAverage;
  int get totalPrayers30Days => _totalPrayers30Days;
  int get totalTasks30Days => _totalTasks30Days;

  String get dailyZikr => DailyZikrService.getDailyZikr();

  double _dailyScore = 0.0;
  double get dailyScore => _dailyScore;

  Future<void> refreshStats() async {
    final db = DatabaseHelper();

    _prayerStats = await db.getPrayerStatsLast7Days();
    _assessmentStats = await db.getAssessmentStatsLast7Days();

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _azkarStats = await db.getAzkarStatsByDate(today);

    await _loadHistory();
    _runAnalytics();
    _calculateDailyScore();

    await _scheduleDailyZikrReminder();
    await _syncWidgetData();

    notifyListeners();
  }

  Future<void> _syncWidgetData() async {
    await WidgetService.updateZikrWidget();
  }

  Future<void> _scheduleDailyZikrReminder() async {
    // For simplicity, every hour.
    await _notificationService.schedulePeriodicZikr(
      id: 999,
      title: 'ذكر اليوم',
      body: dailyZikr,
      interval: RepeatInterval.hourly,
    );
  }

  Future<void> _loadHistory() async {
    final db = DatabaseHelper();
    List<DailyEntry> tempHistory = [];

    for (int i = 0; i < 30; i++) {
      String date = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(Duration(days: i)));

      final prayers = await db.getWorshipByDate(date);
      final quran = await db.getQuranByDate(date);
      final tasks = await db.getTodosByDate(date);
      final assessment = await db.getAssessmentByDate(date);
      final azkar = await db.getAzkarStatsListByDate(date);

      if (prayers.isEmpty &&
          quran.isEmpty &&
          tasks.isEmpty &&
          assessment == null &&
          azkar.isEmpty) {
        continue;
      }

      tempHistory.add(
        DailyEntry(
          date: date,
          prayers: prayers,
          quran: quran,
          tasks: tasks,
          assessment: assessment,
          azkar: azkar,
        ),
      );
    }
    _history = tempHistory;
  }

  void _runAnalytics() {
    if (_history.isEmpty) return;
    _weakPoints = AnalyticsService.getWeakPrayers(_history);
    _tahajjudCorrelation = AnalyticsService.calculateCorrelation(
      _history,
      'تهجد',
    );

    _currentStreak = 0;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    int startIndex = _history.indexWhere((e) => e.date == today);
    if (startIndex == -1) {
      startIndex = _history.indexWhere((e) => e.date == yesterday);
    }

    if (startIndex != -1) {
      for (int i = startIndex; i < _history.length; i++) {
        if (i == startIndex) {
          _currentStreak++;
          continue;
        }

        DateTime d1 = DateFormat('yyyy-MM-dd').parse(_history[i - 1].date);
        DateTime d2 = DateFormat('yyyy-MM-dd').parse(_history[i].date);

        if (d1.difference(d2).inDays == 1) {
          _currentStreak++;
        } else {
          break;
        }
      }
    }

    _totalPrayers30Days = 0;
    _totalTasks30Days = 0;
    double totalCompletionRatio = 0.0;

    for (var entry in _history) {
      int prayers = entry.prayers.where((p) => p.isCompleted).length;
      int tasks = entry.tasks.where((t) => t.isCompleted).length;

      _totalPrayers30Days += prayers;
      _totalTasks30Days += tasks;

      double prayerRatio = prayers / 12.0;
      double taskRatio = entry.tasks.isEmpty ? 1.0 : tasks / entry.tasks.length;
      totalCompletionRatio += (prayerRatio * 0.7 + taskRatio * 0.3);
    }

    _last30DaysAverage = _history.isEmpty
        ? 0.0
        : totalCompletionRatio / _history.length;
  }

  Future<void> logZikr(String text, {int count = 1}) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await DatabaseHelper().incrementAzkarCount(today, text, count: count);
    await refreshStats();
  }

  void _calculateDailyScore() {
    // Look for today's entry in history
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final index = _history.indexWhere((e) => e.date == today);
    if (index == -1) {
      _dailyScore = 0.0;
      return;
    }

    final entry = _history[index];

    // 50% Faraid (5 prayers)
    double faraidScore =
        entry.prayers
            .where(
              (p) =>
                  p.isCompleted &&
                  !p.prayerName.contains('سنة') &&
                  p.prayerName != 'تهجد' &&
                  p.prayerName != 'صبح' &&
                  p.prayerName != 'ضحى',
            )
            .length /
        5.0;

    // 20% Sunnah (approx 7 common sunnahs)
    double sunnahScore =
        entry.prayers
            .where(
              (p) =>
                  p.isCompleted &&
                  (p.prayerName.contains('سنة') ||
                      ['تهجد', 'صبح', 'ضحى'].contains(p.prayerName)),
            )
            .length /
        7.0;

    // 20% Quran & Tasks
    double taskScore = entry.tasks.isEmpty
        ? 1.0
        : entry.tasks.where((t) => t.isCompleted).length /
              entry.tasks.length.toDouble();

    // 10% Azkar (Threshold of 100 total counts)
    int totalAzkarCount = entry.azkar.fold(0, (sum, item) => sum + item.count);
    double azkarScore = (totalAzkarCount / 100.0).clamp(0.0, 1.0);

    _dailyScore =
        (faraidScore * 0.5 +
                sunnahScore * 0.2 +
                taskScore * 0.2 +
                azkarScore * 0.1)
            .clamp(0.0, 1.0);
  }
}
