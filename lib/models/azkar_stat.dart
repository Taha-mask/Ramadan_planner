class AzkarStat {
  final int? id;
  final String date;
  final String zikrText;
  final int count;

  AzkarStat({
    this.id,
    required this.date,
    required this.zikrText,
    required this.count,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'date': date, 'zikrText': zikrText, 'count': count};
  }

  factory AzkarStat.fromMap(Map<String, dynamic> map) {
    return AzkarStat(
      id: map['id'],
      date: map['date'],
      zikrText: map['zikrText'],
      count: map['count'],
    );
  }
}
