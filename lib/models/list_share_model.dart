import 'package:equatable/equatable.dart';

enum PermissionLevel {
  view('view'),
  comment('comment'),
  edit('edit');

  const PermissionLevel(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case PermissionLevel.view:
        return 'View Only';
      case PermissionLevel.comment:
        return 'Can Comment';
      case PermissionLevel.edit:
        return 'Can Edit';
    }
  }

  static PermissionLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'view':
        return PermissionLevel.view;
      case 'comment':
        return PermissionLevel.comment;
      case 'edit':
        return PermissionLevel.edit;
      default:
        return PermissionLevel.view;
    }
  }

  bool get canView => true;
  bool get canComment => this == PermissionLevel.comment || this == PermissionLevel.edit;
  bool get canEdit => this == PermissionLevel.edit;
}

class ListShare extends Equatable {
  final String id;
  final String todoListId;
  final String sharedWithUserId;
  final PermissionLevel permissionLevel;
  final DateTime createdAt;

  const ListShare({
    required this.id,
    required this.todoListId,
    required this.sharedWithUserId,
    this.permissionLevel = PermissionLevel.view,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, todoListId, sharedWithUserId, permissionLevel, createdAt
  ];

  ListShare copyWith({
    String? id,
    String? todoListId,
    String? sharedWithUserId,
    PermissionLevel? permissionLevel,
    DateTime? createdAt,
  }) {
    return ListShare(
      id: id ?? this.id,
      todoListId: todoListId ?? this.todoListId,
      sharedWithUserId: sharedWithUserId ?? this.sharedWithUserId,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo_list_id': todoListId,
      'shared_with_user_id': sharedWithUserId,
      'permission_level': permissionLevel.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ListShare.fromJson(Map<String, dynamic> json) {
    return ListShare(
      id: json['id'] as String,
      todoListId: json['todo_list_id'] as String,
      sharedWithUserId: json['shared_with_user_id'] as String,
      permissionLevel: PermissionLevel.fromString(json['permission_level'] as String? ?? 'view'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}