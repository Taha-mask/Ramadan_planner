import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/daily_entry.dart';
import '../services/analytics_service.dart';

class HistoryProvider with ChangeNotifier {
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

  Future<void> refreshStats() async {
    final db = DatabaseHelper();

    _prayerStats = await db.getPrayerStatsLast7Days();
    _assessmentStats = await db.getAssessmentStatsLast7Days();

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _azkarStats = await db.getAzkarStatsByDate(today);

    await _loadHistory();
    _runAnalytics();

    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final db = DatabaseHelper();
    // Use local list to prevent race conditions causing duplicates
    List<DailyEntry> tempHistory = [];

    // Get last 30 days of data
    for (int i = 0; i < 30; i++) {
      String date = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(Duration(days: i)));

      final prayers = await db.getWorshipByDate(date);
      final quran = await db.getQuranByDate(date);
      final tasks = await db.getTodosByDate(date);
      final assessment = await db.getAssessmentByDate(date);
      final azkar = await db.getAzkarStatsListByDate(date);

      // Include the day if there is ANY type of data recorded
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

    // Calculate current streak (days with ANY data recorded starting from yesterday/today)
    _currentStreak = 0;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    // Find the starting point for streak (either today or yesterday)
    int startIndex = _history.indexWhere((e) => e.date == today);
    if (startIndex == -1) {
      startIndex = _history.indexWhere((e) => e.date == yesterday);
    }

    if (startIndex != -1) {
      for (int i = startIndex; i < _history.length; i++) {
        // Since history is ordered by date descending by default in the loop,
        // we need to ensure they are consecutive.
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

    // Calculate 30-day averages
    _totalPrayers30Days = 0;
    _totalTasks30Days = 0;
    double totalCompletionRatio = 0.0;

    for (var entry in _history) {
      int prayers = entry.prayers.where((p) => p.isCompleted).length;
      int tasks = entry.tasks.where((t) => t.isCompleted).length;

      _totalPrayers30Days += prayers;
      _totalTasks30Days += tasks;

      // Completion ratio = (Completed Prayers / 12) * 0.7 + (Completed Tasks / Total Tasks) * 0.3
      double prayerRatio = prayers / 12.0;
      double taskRatio = entry.tasks.isEmpty ? 1.0 : tasks / entry.tasks.length;
      totalCompletionRatio += (prayerRatio * 0.7 + taskRatio * 0.3);
    }

    _last30DaysAverage = _history.isEmpty
        ? 0.0
        : totalCompletionRatio / _history.length;
  }

  Future<void> logZikr(String text) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await DatabaseHelper().incrementAzkarCount(today, text);
    await refreshStats();
  }
}
