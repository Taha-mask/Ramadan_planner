import 'worship.dart';
import 'quran.dart';
import 'todo.dart';
import 'assessment.dart';
import 'azkar_stat.dart';

class DailyEntry {
  final String date;
  final List<WorshipEntry> prayers;
  final List<QuranProgress> quran;
  final List<TodoTask> tasks;
  final DailyAssessment? assessment;
  final List<AzkarStat> azkar;

  DailyEntry({
    required this.date,
    required this.prayers,
    required this.quran,
    required this.tasks,
    this.assessment,
    required this.azkar,
  });

  // Calculate completion percentage for the day
  double get totalCompletion {
    int total = prayers.length + tasks.length;
    if (total == 0) return 0.0;

    int completed =
        prayers.where((e) => e.isCompleted).length +
        tasks.where((e) => e.isCompleted).length;

    return completed / total;
  }
}
