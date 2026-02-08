class DailyAssessment {
  final int? id;
  final String date;
  final double rating; // 1 to 10
  final String dua;
  final String notes;

  DailyAssessment({
    this.id,
    required this.date,
    required this.rating,
    required this.dua,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'rating': rating,
      'dua': dua,
      'notes': notes,
    };
  }

  factory DailyAssessment.fromMap(Map<String, dynamic> map) {
    return DailyAssessment(
      id: map['id'],
      date: map['date'],
      rating: map['rating'].toDouble(),
      dua: map['dua'],
      notes: map['notes'],
    );
  }
}
