class GroupMember {
  final int? id;
  final int groupId;
  final int userId;
  final String role; // 'owner' | 'member'
  final DateTime addedAt;

  GroupMember({
    this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.addedAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      userId: map['user_id'] as int,
      role: map['role'] as String,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }
}
