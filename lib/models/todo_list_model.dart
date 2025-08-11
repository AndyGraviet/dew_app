import 'package:equatable/equatable.dart';

class TodoList extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? color;
  final bool isPublic;
  final bool isArchived;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoList({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color,
    this.isPublic = false,
    this.isArchived = false,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id, userId, name, description, color, 
    isPublic, isArchived, position, createdAt, updatedAt
  ];

  TodoList copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? color,
    bool? isPublic,
    bool? isArchived,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isPublic: isPublic ?? this.isPublic,
      isArchived: isArchived ?? this.isArchived,
      position: position ?? this.position,
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
      'color': color,
      'is_public': isPublic,
      'is_archived': isArchived,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TodoList.fromJson(Map<String, dynamic> json) {
    return TodoList(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      isPublic: (json['is_public'] as bool?) ?? false,
      isArchived: (json['is_archived'] as bool?) ?? false,
      position: (json['position'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}