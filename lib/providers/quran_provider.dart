import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/quran.dart';
import '../services/database_helper.dart';

class QuranProvider with ChangeNotifier {
  QuranProgress? _current;
  QuranProgress? get current => _current;

  Future<void> loadProgress(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final list = await DatabaseHelper().getQuranByDate(formattedDate);
    if (list.isNotEmpty) {
      _current = list.first;
    } else {
      _current = null;
    }
    notifyListeners();
  }

  Future<void> saveProgress({
    required int juz,
    required String surah,
    required int page,
    required int ayah,
  }) async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final newProgress = QuranProgress(
      id: _current?.id,
      date: date,
      juz: juz,
      surah: surah,
      page: page,
      ayah: ayah,
    );

    int id = await DatabaseHelper().insertQuranProgress(newProgress);
    _current = newProgress.copyWith(id: id);
    notifyListeners();
  }
}
