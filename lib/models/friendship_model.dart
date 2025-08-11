import 'package:equatable/equatable.dart';

enum FriendshipStatus {
  pending,
  accepted,
  declined,
  blocked;

  String get displayName {
    switch (this) {
      case FriendshipStatus.pending:
        return 'Pending';
      case FriendshipStatus.accepted:
        return 'Friends';
      case FriendshipStatus.declined:
        return 'Declined';
      case FriendshipStatus.blocked:
        return 'Blocked';
    }
  }

  static FriendshipStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return FriendshipStatus.pending;
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'declined':
        return FriendshipStatus.declined;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }
}

class Friendship extends Equatable {
  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id, requesterId, addresseeId, status, createdAt, updatedAt
  ];

  Friendship copyWith({
    String? id,
    String? requesterId,
    String? addresseeId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Friendship(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      addresseeId: addresseeId ?? this.addresseeId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'addressee_id': addresseeId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: FriendshipStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}