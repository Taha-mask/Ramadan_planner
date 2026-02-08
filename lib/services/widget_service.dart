import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _ramadanWidgetProvider = 'RamadanWidgetProvider';
  static const String _tasksWidgetProvider = 'TasksWidgetProvider';

  static Future<void> updateWidget({
    String? nextPrayerName,
    String? nextPrayerTime,
    String? tasksSummary,
    String? tasksList,
    int? doneCount,
    int? totalCount,
  }) async {
    try {
      if (nextPrayerName != null) {
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_name',
          nextPrayerName,
        );
      }
      if (nextPrayerTime != null) {
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_time',
          nextPrayerTime,
        );
      }
      if (tasksSummary != null) {
        await HomeWidget.saveWidgetData<String>('tasks_summary', tasksSummary);
      }
      if (tasksList != null) {
        await HomeWidget.saveWidgetData<String>('tasks_list', tasksList);
      }
      if (doneCount != null) {
        await HomeWidget.saveWidgetData<int>('tasks_done_count', doneCount);
      }
      if (totalCount != null) {
        await HomeWidget.saveWidgetData<int>('tasks_total_count', totalCount);
      }

      // Update both widgets
      await HomeWidget.updateWidget(androidName: _ramadanWidgetProvider);
      await HomeWidget.updateWidget(androidName: _tasksWidgetProvider);
    } catch (e) {
      // Handle or log error
      print('Error updating widget: $e');
    }
  }
}
