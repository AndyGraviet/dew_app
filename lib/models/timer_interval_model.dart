import 'package:equatable/equatable.dart';
import 'timer_session_model.dart';

class TimerInterval extends Equatable {
  final String id;
  final String timerSessionId;
  final int intervalNumber;
  final IntervalType intervalType;
  final int plannedDurationMinutes;
  final int? actualDurationSeconds;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool wasCompleted;
  final bool wasSkipped;
  final int? productivityRating;
  final String? notes;
  final DateTime createdAt;

  const TimerInterval({
    required this.id,
    required this.timerSessionId,
    required this.intervalNumber,
    required this.intervalType,
    required this.plannedDurationMinutes,
    this.actualDurationSeconds,
    this.startedAt,
    this.completedAt,
    this.wasCompleted = false,
    this.wasSkipped = false,
    this.productivityRating,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, timerSessionId, intervalNumber, intervalType, plannedDurationMinutes,
    actualDurationSeconds, startedAt, completedAt, wasCompleted, wasSkipped,
    productivityRating, notes, createdAt
  ];

  bool get isRunning => startedAt != null && completedAt == null && !wasSkipped;
  bool get isFinished => wasCompleted || wasSkipped;
  
  Duration? get actualDuration => actualDurationSeconds != null 
      ? Duration(seconds: actualDurationSeconds!) 
      : null;
      
  Duration get plannedDuration => Duration(minutes: plannedDurationMinutes);

  double? get completionPercentage {
    if (actualDurationSeconds == null) return null;
    final plannedSeconds = plannedDurationMinutes * 60;
    return (actualDurationSeconds! / plannedSeconds).clamp(0.0, 1.0);
  }

  TimerInterval copyWith({
    String? id,
    String? timerSessionId,
    int? intervalNumber,
    IntervalType? intervalType,
    int? plannedDurationMinutes,
    int? actualDurationSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? wasCompleted,
    bool? wasSkipped,
    int? productivityRating,
    String? notes,
    DateTime? createdAt,
  }) {
    return TimerInterval(
      id: id ?? this.id,
      timerSessionId: timerSessionId ?? this.timerSessionId,
      intervalNumber: intervalNumber ?? this.intervalNumber,
      intervalType: intervalType ?? this.intervalType,
      plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      wasSkipped: wasSkipped ?? this.wasSkipped,
      productivityRating: productivityRating ?? this.productivityRating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timer_session_id': timerSessionId,
      'interval_number': intervalNumber,
      'interval_type': intervalType.value,
      'planned_duration_minutes': plannedDurationMinutes,
      'actual_duration_seconds': actualDurationSeconds,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'was_completed': wasCompleted,
      'was_skipped': wasSkipped,
      'productivity_rating': productivityRating,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimerInterval.fromJson(Map<String, dynamic> json) {
    return TimerInterval(
      id: json['id'] as String,
      timerSessionId: json['timer_session_id'] as String,
      intervalNumber: json['interval_number'] as int,
      intervalType: IntervalType.fromString(json['interval_type'] as String),
      plannedDurationMinutes: json['planned_duration_minutes'] as int,
      actualDurationSeconds: json['actual_duration_seconds'] as int?,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      wasCompleted: (json['was_completed'] as bool?) ?? false,
      wasSkipped: (json['was_skipped'] as bool?) ?? false,
      productivityRating: json['productivity_rating'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}