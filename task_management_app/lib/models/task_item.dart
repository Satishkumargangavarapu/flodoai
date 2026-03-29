class TaskItem {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final int? blockedBy;

  TaskItem({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedBy,
  });

  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    int? blockedBy,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedBy: blockedBy ?? this.blockedBy,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'blocked_by': blockedBy,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['due_date']),
      status: map['status'],
      blockedBy: map['blocked_by'],
    );
  }
}
