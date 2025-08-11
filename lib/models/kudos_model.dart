import 'package:equatable/equatable.dart';

class Kudos extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? taskId;
  final String? todoListId;
  final String? message;
  final String emoji;
  final DateTime createdAt;

  const Kudos({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.taskId,
    this.todoListId,
    this.message,
    this.emoji = '👏',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, fromUserId, toUserId, taskId, todoListId, 
    message, emoji, createdAt
  ];

  bool get isForTask => taskId != null;
  bool get isForTodoList => todoListId != null;

  Kudos copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? taskId,
    String? todoListId,
    String? message,
    String? emoji,
    DateTime? createdAt,
  }) {
    return Kudos(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      taskId: taskId ?? this.taskId,
      todoListId: todoListId ?? this.todoListId,
      message: message ?? this.message,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'task_id': taskId,
      'todo_list_id': todoListId,
      'message': message,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Kudos.fromJson(Map<String, dynamic> json) {
    return Kudos(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      taskId: json['task_id'] as String?,
      todoListId: json['todo_list_id'] as String?,
      message: json['message'] as String?,
      emoji: (json['emoji'] as String?) ?? '👏',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Factory methods for different types of kudos
  factory Kudos.forTask({
    required String fromUserId,
    required String toUserId,
    required String taskId,
    String? message,
    String emoji = '🎉',
  }) {
    return Kudos(
      id: '',
      fromUserId: fromUserId,
      toUserId: toUserId,
      taskId: taskId,
      message: message,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
  }

  factory Kudos.forTodoList({
    required String fromUserId,
    required String toUserId,
    required String todoListId,
    String? message,
    String emoji = '✨',
  }) {
    return Kudos(
      id: '',
      fromUserId: fromUserId,
      toUserId: toUserId,
      todoListId: todoListId,
      message: message,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
  }

  factory Kudos.general({
    required String fromUserId,
    required String toUserId,
    String? message,
    String emoji = '👏',
  }) {
    return Kudos(
      id: '',
      fromUserId: fromUserId,
      toUserId: toUserId,
      message: message,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
  }
}