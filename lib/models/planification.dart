class Planification {
  final int? id;
  final String title;
  final String description;
  final String category;
  final String duration; // e.g., "2h", "1h30"
  final double cost;
  final int votes;
  final int totalMembers;
  final String suggestedBy;
  final List<String> imageUrls;
  final bool isVoted; // whether current user voted (local flag)
  final int tripDay; // day number in trip (1-based)
  final String tripTime; // HH:mm
  final DateTime createdAt;

  Planification({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.cost,
    this.votes = 0,
    this.totalMembers = 0,
    required this.suggestedBy,
    this.imageUrls = const [],
    this.isVoted = false,
    this.tripDay = 0,
    this.tripTime = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'duration': duration,
      'cost': cost,
      'votes': votes,
      'totalMembers': totalMembers,
      'suggestedBy': suggestedBy,
      'imageUrls': imageUrls.join(','),
      'isVoted': isVoted ? 1 : 0,
      'tripDay': tripDay,
      'tripTime': tripTime,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Planification.fromMap(Map<String, dynamic> map) {
    return Planification(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      duration: (map['duration'] ?? '') as String,
      cost: (map['cost'] is int)
          ? (map['cost'] as int).toDouble()
          : (map['cost'] as num?)?.toDouble() ?? 0.0,
      votes: (map['votes'] as int?) ?? 0,
      totalMembers: (map['totalMembers'] as int?) ?? 0,
      suggestedBy: map['suggestedBy'] as String,
      imageUrls: (map['imageUrls'] != null && (map['imageUrls'] as String).isNotEmpty)
          ? (map['imageUrls'] as String).split(',')
          : <String>[],
      isVoted: (map['isVoted'] as int?) == 1,
      tripDay: (map['tripDay'] as int?) ?? 0,
      tripTime: (map['tripTime'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Planification copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? duration,
    double? cost,
    int? votes,
    int? totalMembers,
    String? suggestedBy,
    List<String>? imageUrls,
    bool? isVoted,
    int? tripDay,
    String? tripTime,
    DateTime? createdAt,
  }) {
    return Planification(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      cost: cost ?? this.cost,
      votes: votes ?? this.votes,
      totalMembers: totalMembers ?? this.totalMembers,
      suggestedBy: suggestedBy ?? this.suggestedBy,
      imageUrls: imageUrls ?? this.imageUrls,
      isVoted: isVoted ?? this.isVoted,
      tripDay: tripDay ?? this.tripDay,
      tripTime: tripTime ?? this.tripTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
