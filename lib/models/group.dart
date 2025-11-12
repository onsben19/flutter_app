class Group {
  final int? id;
  final String name;
  final String? description;
  final int ownerId;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  Group({
    this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      ownerId: map['owner_id'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      startDate: map['start_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'description': description,
      'owner_id': ownerId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'start_date': startDate?.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
    };
  }
}
