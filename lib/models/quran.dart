class QuranProgress {
  final int? id;
  final String date;
  final int juz;
  final String surah;
  final int page;
  final int ayah;

  QuranProgress({
    this.id,
    required this.date,
    required this.juz,
    required this.surah,
    required this.page,
    required this.ayah,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'juz': juz,
      'surah': surah,
      'page': page,
      'ayah': ayah,
    };
  }

  factory QuranProgress.fromMap(Map<String, dynamic> map) {
    return QuranProgress(
      id: map['id'],
      date: map['date'],
      juz: map['juz'] ?? 0,
      surah: map['surah'] ?? '',
      page: map['page'] ?? 0,
      ayah: map['ayah'] ?? 0,
    );
  }
  QuranProgress copyWith({
    int? id,
    String? date,
    int? juz,
    String? surah,
    int? page,
    int? ayah,
  }) {
    return QuranProgress(
      id: id ?? this.id,
      date: date ?? this.date,
      juz: juz ?? this.juz,
      surah: surah ?? this.surah,
      page: page ?? this.page,
      ayah: ayah ?? this.ayah,
    );
  }
}
