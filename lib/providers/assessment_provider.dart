import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assessment.dart';
import '../services/database_helper.dart';

class AssessmentProvider with ChangeNotifier {
  DailyAssessment? _current;
  DailyAssessment? get current => _current;

  Future<void> loadAssessment(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    _current = await DatabaseHelper().getAssessmentByDate(formattedDate);
    notifyListeners();
  }

  Future<void> saveAssessment({
    double? rating,
    String? dua,
    String? notes,
  }) async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Merge with current if exists
    DailyAssessment temp = DailyAssessment(
      id: _current?.id,
      date: date,
      rating: rating ?? _current?.rating ?? 5.0,
      dua: dua ?? _current?.dua ?? '',
      notes: notes ?? _current?.notes ?? '',
    );

    int id = await DatabaseHelper().insertAssessment(temp);

    _current = DailyAssessment(
      id: id,
      date: temp.date,
      rating: temp.rating,
      dua: temp.dua,
      notes: temp.notes,
    );
    notifyListeners();
  }
}
