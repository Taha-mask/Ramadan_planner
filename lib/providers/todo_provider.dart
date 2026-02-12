import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/database_helper.dart';
import '../services/widget_service.dart';

class TodoProvider with ChangeNotifier {
  List<TodoTask> _tasks = [];
  // Getters for specific types
  // Main tasks list (Daily Todos)
  List<TodoTask> get tasks => _tasks.where((t) => t.type == 'todo').toList();

  List<TodoTask> get habitsToQuit =>
      _tasks.where((t) => t.type == 'habit_quit').toList();
  List<TodoTask> get habitsToAcquire =>
      _tasks.where((t) => t.type == 'habit_acquire').toList();

  Future<void> loadTasks(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    _tasks = await DatabaseHelper().getTodosByDate(formattedDate);
    notifyListeners();
    _updateWidget();
  }

  Future<void> addTask(
    String title,
    DateTime date, {
    String type = 'todo',
  }) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    TodoTask newTask = TodoTask(title: title, date: formattedDate, type: type);
    await DatabaseHelper().insertTodo(newTask);
    await loadTasks(date);
  }

  Future<void> toggleTask(int index) async {
    // Keep for backward compatibility if needed, using the main list
    if (index >= 0 && index < _tasks.length) {
      await toggleTaskById(_tasks[index].id!);
    }
  }

  Future<void> toggleTaskById(int id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    TodoTask task = _tasks[index];
    TodoTask updated = TodoTask(
      id: task.id,
      title: task.title,
      isCompleted: !task.isCompleted,
      date: task.date,
      type: task.type,
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
    // int total = _tasks.length; // Unused
    // int done = _tasks.where((t) => t.isCompleted).length; // Unused

    // We pass the full list to the widget service which handles serialization and counting
    await WidgetService.updateTasksWidget(_tasks);
  }
}
