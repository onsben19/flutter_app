class Comment {
  final int? id;
  final int entryId;
  final String author;
  final String content;
  final DateTime date;
  final int likes;

  Comment({
    this.id,
    required this.entryId,
    required this.author,
    required this.content,
    required this.date,
    this.likes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryId': entryId,
      'author': author,
      'content': content,
      'date': date.toIso8601String(),
      'likes': likes,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      entryId: map['entryId'],
      author: map['author'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      likes: map['likes'] ?? 0,
    );
  }
}