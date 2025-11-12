class JournalEntry {
  final int? id;
  final String title;
  final String content;
  final DateTime date;
  final String author;
  final String type;
  final String location;
  final String mood;
  final List<String> photos;
  final int likes;
  final int comments;

  JournalEntry({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    required this.type,
    required this.location,
    required this.mood,
    required this.photos,
    this.likes = 0,
    this.comments = 0,
  });

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.millisecondsSinceEpoch,
      'author': author,
      'type': type,
      'location': location,
      'mood': mood,
      'photos': photos.join(','), // Stocker les photos séparées par des virgules
      'likes': likes,
      'comments': comments,
    };
  }

  // Créer un objet depuis une Map (données SQLite)
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      author: map['author'],
      type: map['type'],
      location: map['location'],
      mood: map['mood'],
      photos: map['photos'] != null && map['photos'].isNotEmpty 
          ? map['photos'].split(',') 
          : [],
      likes: map['likes'],
      comments: map['comments'],
    );
  }

  // Méthode pour créer une copie avec des modifications
  JournalEntry copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? date,
    String? author,
    String? type,
    String? location,
    String? mood,
    List<String>? photos,
    int? likes,
    int? comments,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      author: author ?? this.author,
      type: type ?? this.type,
      location: location ?? this.location,
      mood: mood ?? this.mood,
      photos: photos ?? this.photos,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }

}