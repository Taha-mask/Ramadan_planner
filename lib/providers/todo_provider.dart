import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/database_helper.dart';
import '../services/widget_service.dart';

class TodoProvider with ChangeNotifier {
  List<TodoTask> _tasks = [];
  List<TodoTask> get tasks => _tasks;

  Future<void> loadTasks(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    _tasks = await DatabaseHelper().getTodosByDate(formattedDate);
    notifyListeners();
    _updateWidget();
  }

  Future<void> addTask(String title, DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    TodoTask newTask = TodoTask(title: title, date: formattedDate);
    await DatabaseHelper().insertTodo(newTask);
    await loadTasks(date);
  }

  Future<void> toggleTask(int index) async {
    TodoTask task = _tasks[index];
    TodoTask updated = TodoTask(
      id: task.id,
      title: task.title,
      isCompleted: !task.isCompleted,
      date: task.date,
    );
    await DatabaseHelper().updateTodo(updated);
    _tasks[index] = updated;
    notifyListeners();
    _updateWidget();
  }

  Future<void> deleteTask(int id, DateTime date) async {
    await DatabaseHelper().deleteTodo(id);
    await loadTasks(date);
  }

  Future<void> _updateWidget() async {
    int total = _tasks.length;
    int done = _tasks.where((t) => t.isCompleted).length;
    int pending = total - done;

    final tasksData = _tasks
        .map(
          (t) => {'id': t.id, 'title': t.title, 'isCompleted': t.isCompleted},
        )
        .toList();

    await WidgetService.updateWidget(
      tasksSummary: '$pending مهام متبقية',
      tasksList: jsonEncode(tasksData),
      doneCount: done,
      totalCount: total,
    );
  }
}
