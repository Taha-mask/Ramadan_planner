class TodoTask {
  final int? id;
  final String title;
  final bool isCompleted;
  final String date;

  TodoTask({
    this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'date': date,
    };
  }

  factory TodoTask.fromMap(Map<String, dynamic> map) {
    return TodoTask(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      date: map['date'],
    );
  }
}
