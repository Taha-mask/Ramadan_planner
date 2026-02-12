class TodoTask {
  final int? id;
  final String title;
  final bool isCompleted;
  final String date;
  final String type; // 'todo', 'habit_quit', 'habit_acquire'

  TodoTask({
    this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.type = 'todo',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'date': date,
      'type': type,
    };
  }

  factory TodoTask.fromMap(Map<String, dynamic> map) {
    return TodoTask(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      date: map['date'],
      type: map['type'] ?? 'todo',
    );
  }
}
