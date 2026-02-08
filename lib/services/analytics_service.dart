import '../models/daily_entry.dart';

class AnalyticsService {
  /// Finds prayers that have been missed more than a certain threshold in the last 7 days.
  static List<String> getWeakPrayers(List<DailyEntry> history) {
    if (history.isEmpty) return [];

    Map<String, int> missedCounts = {};
    Map<String, int> totalCounts = {};

    for (var day in history) {
      for (var prayer in day.prayers) {
        totalCounts[prayer.prayerName] =
            (totalCounts[prayer.prayerName] ?? 0) + 1;
        if (!prayer.isCompleted) {
          missedCounts[prayer.prayerName] =
              (missedCounts[prayer.prayerName] ?? 0) + 1;
        }
      }
    }

    List<String> weakPoints = [];
    missedCounts.forEach((prayer, missed) {
      int total = totalCounts[prayer] ?? 1;
      if (missed / total > 0.4) {
        // Missed more than 40%
        weakPoints.add(prayer);
      }
    });

    return weakPoints;
  }

  /// Calculates the correlation between a specific activity (like Tahajjud) and daily assessment.
  static double calculateCorrelation(
    List<DailyEntry> history,
    String prayerName,
  ) {
    if (history.length < 3) return 0.0;

    List<DailyEntry> daysWithPrayer = history
        .where(
          (d) =>
              d.prayers.any((p) => p.prayerName == prayerName && p.isCompleted),
        )
        .toList();

    List<DailyEntry> daysWithoutPrayer = history
        .where(
          (d) => d.prayers.any(
            (p) => p.prayerName == prayerName && !p.isCompleted,
          ),
        )
        .toList();

    if (daysWithPrayer.isEmpty || daysWithoutPrayer.isEmpty) return 0.0;

    double avgWith =
        daysWithPrayer
            .map((d) => d.assessment?.rating ?? 0)
            .reduce((a, b) => a + b) /
        daysWithPrayer.length;
    double avgWithout =
        daysWithoutPrayer
            .map((d) => d.assessment?.rating ?? 0)
            .reduce((a, b) => a + b) /
        daysWithoutPrayer.length;

    if (avgWithout == 0) return 0.0;
    return (avgWith - avgWithout) / avgWithout; // Percentage increase/decrease
  }

  /// Finds Azkar that are rarely recited compared to others.
  static List<String> getNeglectedAzkar(List<DailyEntry> history) {
    // This requires a list of all possible Azkar to know what was neglected
    // For now, let's just return those with 0 count in the last week if we have a master list.
    return [];
  }
}
