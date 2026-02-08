class WorshipEntry {
  final int? id;
  final String date; // YYYY-MM-DD
  final String prayerName;
  final bool isCompleted;
  final DateTime? time; // Transient, not stored in DB

  WorshipEntry({
    this.id,
    required this.date,
    required this.prayerName,
    this.isCompleted = false,
    this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'prayerName': prayerName,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory WorshipEntry.fromMap(Map<String, dynamic> map) {
    return WorshipEntry(
      id: map['id'],
      date: map['date'],
      prayerName: map['prayerName'],
      isCompleted: map['isCompleted'] == 1,
    );
  }

  WorshipEntry copyWith({
    int? id,
    String? date,
    String? prayerName,
    bool? isCompleted,
    DateTime? time,
  }) {
    return WorshipEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      prayerName: prayerName ?? this.prayerName,
      isCompleted: isCompleted ?? this.isCompleted,
      time: time ?? this.time,
    );
  }
}
