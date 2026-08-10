class Todo {
  static const int _deadlineLeadMinutesMarker = 100000;
  const Todo({
    required this.id,
    required this.listId,
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
  final String listId;
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

  /// Older records stored this value as days. New records use a marked minute
  /// value so existing deadline reminders keep their original meaning.
  int get deadlineHeadsUpMinutes => remindDaysBeforeDDL == 0
      ? 0
      : remindDaysBeforeDDL >= _deadlineLeadMinutesMarker
      ? remindDaysBeforeDDL - _deadlineLeadMinutesMarker
      : remindDaysBeforeDDL * Duration.minutesPerDay;

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      listId: json['listId'] as String? ?? 'inbox',
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
    String? listId,
    String? title,
    String? content,
    DateTime? reminderTime,
    DateTime? deadline,
    int? remindDaysBeforeDDL,
    int? deadlineHeadsUpMinutes,
    String? notes,
    bool? isMuted,
    bool? isCompleted,
    bool? isStarred,
    int? sortOrder,
  }) {
    return Todo(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      content: content ?? this.content,
      reminderTime: reminderTime ?? this.reminderTime,
      deadline: deadline ?? this.deadline,
      remindDaysBeforeDDL: deadlineHeadsUpMinutes == null
          ? remindDaysBeforeDDL ?? this.remindDaysBeforeDDL
          : deadlineHeadsUpMinutes == 0
          ? 0
          : _deadlineLeadMinutesMarker + deadlineHeadsUpMinutes,
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
      'listId': listId,
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
