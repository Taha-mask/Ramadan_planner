class DailyZikrService {
  static const List<String> _zikrs = [
    'سبحان الله وبحمده',
    'سبحان الله العظيم',
    'لا إله إلا الله',
    'الله أكبر',
    'الحمد لله',
    'أستغفر الله وأتوب إليه',
    'لا حول ولا قوة إلا بالله',
    'اللهم صل وسلم على نبينا محمد',
    'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر',
    'حسبي الله ونعم الوكيل',
  ];

  static String getDailyZikr() {
    final now = DateTime.now();
    // Use day of year or similar to pick a zikr consistently for the whole day
    final dayIndex =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        (1000 * 60 * 60 * 24);
    return _zikrs[dayIndex % _zikrs.length];
  }

  static List<String> getAllZikrs() => _zikrs;
}
