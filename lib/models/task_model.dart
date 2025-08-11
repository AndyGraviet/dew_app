import 'package:equatable/equatable.dart';

enum PriorityLevel {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case PriorityLevel.low:
        return 'Low';
      case PriorityLevel.medium:
        return 'Medium';
      case PriorityLevel.high:
        return 'High';
      case PriorityLevel.urgent:
        return 'Urgent';
    }
  }

  static PriorityLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return PriorityLevel.low;
      case 'medium':
        return PriorityLevel.medium;
      case 'high':
        return PriorityLevel.high;
      case 'urgent':
        return PriorityLevel.urgent;
      default:
        return PriorityLevel.medium;
    }
  }
}

class Task extends Equatable {
  final String id;
  final String todoListId;
  final String title;
  final String? description;
  final PriorityLevel priority;
  final bool isCompleted;
  final DateTime? dueDate;
  final int position;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Task({
    required this.id,
    required this.todoListId,
    required this.title,
    this.description,
    this.priority = PriorityLevel.medium,
    this.isCompleted = false,
    this.dueDate,
    this.position = 0,
    required this.createdAt,
    this.completedAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
    id, todoListId, title, description, priority, isCompleted,
    dueDate, position, createdAt, completedAt, updatedAt, deletedAt
  ];

  bool get isDeleted => deletedAt != null;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  Task copyWith({
    String? id,
    String? todoListId,
    String? title,
    String? description,
    PriorityLevel? priority,
    bool? isCompleted,
    DateTime? dueDate,
    int? position,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      todoListId: todoListId ?? this.todoListId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo_list_id': todoListId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'is_completed': isCompleted,
      'due_date': dueDate?.toIso8601String(),
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      todoListId: json['todo_list_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: PriorityLevel.fromString(json['priority'] as String? ?? 'medium'),
      isCompleted: (json['is_completed'] as bool?) ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      position: (json['position'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }
}