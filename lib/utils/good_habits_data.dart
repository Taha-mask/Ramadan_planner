import 'package:flutter/material.dart';

class GoodHabit {
  final String id;
  final String title;
  final IconData icon;

  const GoodHabit({required this.id, required this.title, required this.icon});
}

class GoodHabitsData {
  static const List<GoodHabit> defaultHabits = [
    GoodHabit(id: 'water', title: 'شرب 2 لتر ماء', icon: Icons.water_drop),
    GoodHabit(
      id: 'early_rise',
      title: 'الاستيقاظ مبكراً',
      icon: Icons.wb_sunny,
    ),
    GoodHabit(
      id: 'reading',
      title: 'قراءة صفحتين من كتاب مفيد',
      icon: Icons.menu_book,
    ),
    GoodHabit(
      id: 'sport',
      title: 'ممارسة الرياضة (15 دقيقة)',
      icon: Icons.fitness_center,
    ),
    GoodHabit(
      id: 'smile',
      title: 'الابتسامة والكلمة الطيبة',
      icon: Icons.sentiment_satisfied_alt,
    ),
    GoodHabit(
      id: 'family',
      title: 'صلة الرحم (اتصال/زيارة)',
      icon: Icons.family_restroom,
    ),
  ];

  static GoodHabit? getById(String id) {
    try {
      return defaultHabits.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
