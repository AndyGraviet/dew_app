import 'package:equatable/equatable.dart';

enum TimerSessionStatus {
  notStarted('not_started'),
  running('running'),
  paused('paused'),
  completed('completed'),
  cancelled('cancelled');

  const TimerSessionStatus(this.value);
  final String value;

  static TimerSessionStatus fromString(String value) {
    switch (value) {
      case 'not_started':
        return TimerSessionStatus.notStarted;
      case 'running':
        return TimerSessionStatus.running;
      case 'paused':
        return TimerSessionStatus.paused;
      case 'completed':
        return TimerSessionStatus.completed;
      case 'cancelled':
        return TimerSessionStatus.cancelled;
      default:
        return TimerSessionStatus.notStarted;
    }
  }
}

enum IntervalType {
  work('work'),
  break_('break'),
  longBreak('long_break');

  const IntervalType(this.value);
  final String value;

  static IntervalType fromString(String value) {
    switch (value) {
      case 'work':
        return IntervalType.work;
      case 'break':
        return IntervalType.break_;
      case 'long_break':
        return IntervalType.longBreak;
      default:
        return IntervalType.work;
    }
  }
}

class TimerSession extends Equatable {
  final String id;
  final String userId;
  final String? timerTemplateId;
  final String? taskId;
  final String? todoListId;
  final String? sessionName;
  final int workDurationMinutes;
  final int breakDurationMinutes;
  final int? longBreakDurationMinutes;
  final int? longBreakInterval;
  final int totalSessions;
  final int currentSession;
  final TimerSessionStatus status;
  final IntervalType currentIntervalType;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final DateTime? currentIntervalStartedAt;
  final int totalPauseDuration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimerSession({
    required this.id,
    required this.userId,
    this.timerTemplateId,
    this.taskId,
    this.todoListId,
    this.sessionName,
    required this.workDurationMinutes,
    required this.breakDurationMinutes,
    this.longBreakDurationMinutes,
    this.longBreakInterval,
    required this.totalSessions,
    this.currentSession = 1,
    this.status = TimerSessionStatus.notStarted,
    this.currentIntervalType = IntervalType.work,
    this.startedAt,
    this.pausedAt,
    this.completedAt,
    this.currentIntervalStartedAt,
    this.totalPauseDuration = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id, userId, timerTemplateId, taskId, todoListId, sessionName,
    workDurationMinutes, breakDurationMinutes, longBreakDurationMinutes,
    longBreakInterval, totalSessions, currentSession, status,
    currentIntervalType, startedAt, pausedAt, completedAt,
    currentIntervalStartedAt, totalPauseDuration, createdAt, updatedAt
  ];

  bool get isRunning => status == TimerSessionStatus.running;
  bool get isPaused => status == TimerSessionStatus.paused;
  bool get isCompleted => status == TimerSessionStatus.completed;
  bool get isNotStarted => status == TimerSessionStatus.notStarted;

  int get currentIntervalDurationMinutes {
    switch (currentIntervalType) {
      case IntervalType.work:
        return workDurationMinutes;
      case IntervalType.break_:
        return breakDurationMinutes;
      case IntervalType.longBreak:
        return longBreakDurationMinutes ?? breakDurationMinutes;
    }
  }

  TimerSession copyWith({
    String? id,
    String? userId,
    String? timerTemplateId,
    String? taskId,
    String? todoListId,
    String? sessionName,
    int? workDurationMinutes,
    int? breakDurationMinutes,
    int? longBreakDurationMinutes,
    int? longBreakInterval,
    int? totalSessions,
    int? currentSession,
    TimerSessionStatus? status,
    IntervalType? currentIntervalType,
    DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    DateTime? currentIntervalStartedAt,
    int? totalPauseDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimerSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timerTemplateId: timerTemplateId ?? this.timerTemplateId,
      taskId: taskId ?? this.taskId,
      todoListId: todoListId ?? this.todoListId,
      sessionName: sessionName ?? this.sessionName,
      workDurationMinutes: workDurationMinutes ?? this.workDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      longBreakDurationMinutes: longBreakDurationMinutes ?? this.longBreakDurationMinutes,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      totalSessions: totalSessions ?? this.totalSessions,
      currentSession: currentSession ?? this.currentSession,
      status: status ?? this.status,
      currentIntervalType: currentIntervalType ?? this.currentIntervalType,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      completedAt: completedAt ?? this.completedAt,
      currentIntervalStartedAt: currentIntervalStartedAt ?? this.currentIntervalStartedAt,
      totalPauseDuration: totalPauseDuration ?? this.totalPauseDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'timer_template_id': timerTemplateId,
      'task_id': taskId,
      'todo_list_id': todoListId,
      'session_name': sessionName,
      'work_duration_minutes': workDurationMinutes,
      'break_duration_minutes': breakDurationMinutes,
      'long_break_duration_minutes': longBreakDurationMinutes,
      'long_break_interval': longBreakInterval,
      'total_sessions': totalSessions,
      'current_session': currentSession,
      'status': status.value,
      'current_interval_type': currentIntervalType.value,
      'started_at': startedAt?.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'current_interval_started_at': currentIntervalStartedAt?.toIso8601String(),
      'total_pause_duration': totalPauseDuration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TimerSession.fromJson(Map<String, dynamic> json) {
    return TimerSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      timerTemplateId: json['timer_template_id'] as String?,
      taskId: json['task_id'] as String?,
      todoListId: json['todo_list_id'] as String?,
      sessionName: json['session_name'] as String?,
      workDurationMinutes: json['work_duration_minutes'] as int,
      breakDurationMinutes: json['break_duration_minutes'] as int,
      longBreakDurationMinutes: json['long_break_duration_minutes'] as int?,
      longBreakInterval: json['long_break_interval'] as int?,
      totalSessions: json['total_sessions'] as int,
      currentSession: (json['current_session'] as int?) ?? 1,
      status: TimerSessionStatus.fromString(json['status'] as String? ?? 'not_started'),
      currentIntervalType: IntervalType.fromString(json['current_interval_type'] as String? ?? 'work'),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      pausedAt: json['paused_at'] != null ? DateTime.parse(json['paused_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      currentIntervalStartedAt: json['current_interval_started_at'] != null 
          ? DateTime.parse(json['current_interval_started_at'] as String) : null,
      totalPauseDuration: (json['total_pause_duration'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}