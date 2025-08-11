import 'package:equatable/equatable.dart';

class Activity extends Equatable {
  final String id;
  final String userId;
  final String activityType;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? metadata;
  final bool isPublic;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.userId,
    required this.activityType,
    this.entityType,
    this.entityId,
    this.metadata,
    this.isPublic = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, userId, activityType, entityType, entityId, 
    metadata, isPublic, createdAt
  ];

  Activity copyWith({
    String? id,
    String? userId,
    String? activityType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityType: activityType ?? this.activityType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      metadata: metadata ?? this.metadata,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity_type': activityType,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityType: json['activity_type'] as String,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isPublic: (json['is_public'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Factory methods for common activity types
  factory Activity.taskCompleted({
    required String userId,
    required String taskId,
    required String taskTitle,
    required String todoListId,
    required String todoListName,
  }) {
    return Activity(
      id: '',
      userId: userId,
      activityType: 'task_completed',
      entityType: 'task',
      entityId: taskId,
      metadata: {
        'task_title': taskTitle,
        'todo_list_id': todoListId,
        'todo_list_name': todoListName,
      },
      createdAt: DateTime.now(),
    );
  }

  factory Activity.timerSessionCompleted({
    required String userId,
    required String sessionId,
    required int sessionsCompleted,
    required int totalMinutes,
  }) {
    return Activity(
      id: '',
      userId: userId,
      activityType: 'timer_session_completed',
      entityType: 'timer_session',
      entityId: sessionId,
      metadata: {
        'sessions_completed': sessionsCompleted,
        'total_minutes': totalMinutes,
      },
      createdAt: DateTime.now(),
    );
  }

  factory Activity.todoListCreated({
    required String userId,
    required String todoListId,
    required String todoListName,
  }) {
    return Activity(
      id: '',
      userId: userId,
      activityType: 'todo_list_created',
      entityType: 'todo_list',
      entityId: todoListId,
      metadata: {
        'todo_list_name': todoListName,
      },
      createdAt: DateTime.now(),
    );
  }
}