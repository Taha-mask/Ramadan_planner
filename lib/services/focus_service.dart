import '../providers/worship_provider.dart';

class FocusService {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  bool _isFocusEnabled = false;
  bool get isFocusEnabled => _isFocusEnabled;

  void toggleFocus(bool value) {
    _isFocusEnabled = value;
  }

  /// Checks if the user should be focusing right now (e.g., during prayer time)
  bool shouldBeFocusing(WorshipProvider worshipProvider) {
    if (!_isFocusEnabled) return false;

    // Check if there is a prayer that is currently due and not completed
    final now = DateTime.now();

    // Check Faraid
    for (var entry in worshipProvider.faraidEntries) {
      if (entry.isCompleted) continue;

      if (entry.time != null) {
        final diff = now.difference(entry.time!).inMinutes;
        // If it's after prayer time but less than 60 mins after, or 5 mins before
        if (diff >= -5 && diff <= 60) {
          return true;
        }
      }
    }

    return false;
  }
}
