import 'package:equatable/equatable.dart';

class TimerTemplate extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final int workDurationMinutes;
  final int breakDurationMinutes;
  final int? longBreakDurationMinutes;
  final int? longBreakInterval;
  final int totalSessions;
  final bool isDefault;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimerTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.workDurationMinutes,
    required this.breakDurationMinutes,
    this.longBreakDurationMinutes,
    this.longBreakInterval,
    required this.totalSessions,
    this.isDefault = false,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id, userId, name, description, workDurationMinutes, breakDurationMinutes,
    longBreakDurationMinutes, longBreakInterval, totalSessions, isDefault,
    color, createdAt, updatedAt
  ];

  TimerTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    int? workDurationMinutes,
    int? breakDurationMinutes,
    int? longBreakDurationMinutes,
    int? longBreakInterval,
    int? totalSessions,
    bool? isDefault,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimerTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      workDurationMinutes: workDurationMinutes ?? this.workDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      longBreakDurationMinutes: longBreakDurationMinutes ?? this.longBreakDurationMinutes,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      totalSessions: totalSessions ?? this.totalSessions,
      isDefault: isDefault ?? this.isDefault,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'work_duration_minutes': workDurationMinutes,
      'break_duration_minutes': breakDurationMinutes,
      'long_break_duration_minutes': longBreakDurationMinutes,
      'long_break_interval': longBreakInterval,
      'total_sessions': totalSessions,
      'is_default': isDefault,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TimerTemplate.fromJson(Map<String, dynamic> json) {
    return TimerTemplate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      workDurationMinutes: json['work_duration_minutes'] as int,
      breakDurationMinutes: json['break_duration_minutes'] as int,
      longBreakDurationMinutes: json['long_break_duration_minutes'] as int?,
      longBreakInterval: json['long_break_interval'] as int?,
      totalSessions: json['total_sessions'] as int,
      isDefault: (json['is_default'] as bool?) ?? false,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Create a default Pomodoro template
  factory TimerTemplate.defaultPomodoro({
    required String userId,
  }) {
    final now = DateTime.now();
    return TimerTemplate(
      id: '',
      userId: userId,
      name: 'Default Pomodoro',
      description: 'Classic 25-minute work sessions with 5-minute breaks',
      workDurationMinutes: 25,
      breakDurationMinutes: 5,
      longBreakDurationMinutes: 15,
      longBreakInterval: 4,
      totalSessions: 4,
      isDefault: true,
      color: '#FF6B6B',
      createdAt: now,
      updatedAt: now,
    );
  }
}