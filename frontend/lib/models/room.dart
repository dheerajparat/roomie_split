import 'user.dart';

class RoomMembership {
  final int id;
  final int userId;
  final User user;
  final String status;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  RoomMembership({
    required this.id,
    required this.userId,
    required this.user,
    required this.status,
    this.createdAt,
    this.respondedAt,
  });

  factory RoomMembership.fromJson(Map<String, dynamic> json) {
    return RoomMembership(
      id: json['id'],
      userId: json['user_id'],
      user: User.fromJson(json['user']),
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at']) : null,
    );
  }
}

class Room {
  final int id;
  final String name;
  final String? description;
  final String? roomCode;
  final int createdById;
  final DateTime? createdAt;
  final int totalMembers;
  final String? myStatus;
  final List<RoomMembership> memberships;

  Room({
    required this.id,
    required this.name,
    this.description,
    this.roomCode,
    required this.createdById,
    this.createdAt,
    this.totalMembers = 0,
    this.myStatus,
    this.memberships = const [],
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    var rawMemberships = json['memberships'] as List? ?? [];
    List<RoomMembership> membersList =
        rawMemberships.map((m) => RoomMembership.fromJson(m)).toList();

    return Room(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      roomCode: json['room_code'],
      createdById: json['created_by_id'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      totalMembers: json['total_members'] ?? membersList.length,
      myStatus: json['my_status'],
      memberships: membersList,
    );
  }
}

class RoomInvitation {
  final int membershipId;
  final int roomId;
  final String roomName;
  final String? roomDescription;
  final User invitedBy;
  final DateTime? createdAt;

  RoomInvitation({
    required this.membershipId,
    required this.roomId,
    required this.roomName,
    this.roomDescription,
    required this.invitedBy,
    this.createdAt,
  });

  factory RoomInvitation.fromJson(Map<String, dynamic> json) {
    return RoomInvitation(
      membershipId: json['membership_id'],
      roomId: json['room_id'],
      roomName: json['room_name'] ?? '',
      roomDescription: json['room_description'],
      invitedBy: User.fromJson(json['invited_by']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
