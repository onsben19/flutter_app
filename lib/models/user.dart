class AppUser {
  final int? id;
  final String email;
  final String displayName;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  AppUser({
    this.id,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      email: map['email'] as String,
      displayName: map['display_name'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email.trim().toLowerCase(),
      'display_name': displayName.trim(),
      'password_hash': passwordHash,
      'salt': salt,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
