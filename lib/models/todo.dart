class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.content,
    required this.reminderTime,
    required this.deadline,
    required this.remindDaysBeforeDDL,
    required this.notes,
    required this.isMuted,
    required this.isCompleted,
    required this.isStarred,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String content;
  final DateTime reminderTime;
  final DateTime deadline;
  final int remindDaysBeforeDDL;
  final String notes;
  final bool isMuted;
  final bool isCompleted;
  final bool isStarred;
  final int sortOrder;

  bool get hasTitle => title.trim().isNotEmpty;
  String get presentationTitle => hasTitle ? title.trim() : 'Untitled todo';

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      reminderTime: DateTime.fromMillisecondsSinceEpoch(
        json['reminderTime'] as int,
      ),
      deadline: DateTime.fromMillisecondsSinceEpoch(json['deadline'] as int),
      remindDaysBeforeDDL: json['remindDaysBeforeDDL'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      isMuted: json['isMuted'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isStarred: json['isStarred'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Todo copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? reminderTime,
    DateTime? deadline,
    int? remindDaysBeforeDDL,
    String? notes,
    bool? isMuted,
    bool? isCompleted,
    bool? isStarred,
    int? sortOrder,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      reminderTime: reminderTime ?? this.reminderTime,
      deadline: deadline ?? this.deadline,
      remindDaysBeforeDDL: remindDaysBeforeDDL ?? this.remindDaysBeforeDDL,
      notes: notes ?? this.notes,
      isMuted: isMuted ?? this.isMuted,
      isCompleted: isCompleted ?? this.isCompleted,
      isStarred: isStarred ?? this.isStarred,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'content': content,
      'reminderTime': reminderTime.millisecondsSinceEpoch,
      'deadline': deadline.millisecondsSinceEpoch,
      'remindDaysBeforeDDL': remindDaysBeforeDDL,
      'notes': notes,
      'isMuted': isMuted,
      'isCompleted': isCompleted,
      'isStarred': isStarred,
      'sortOrder': sortOrder,
    };
  }
}
