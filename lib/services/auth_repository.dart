import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import 'database_service.dart';

class EmailAlreadyUsed implements Exception {
  final String message;
  EmailAlreadyUsed([this.message = 'Email already in use']);
  @override
  String toString() => message;
}

class InvalidCredentials implements Exception {
  final String message;
  InvalidCredentials([this.message = 'Invalid credentials']);
  @override
  String toString() => message;
}

class AuthRepository {
  static const String _usersTable = 'users';

  /// Register a new user (fullName, email, password).
  /// - normalizes email
  /// - enforces unique email
  /// - salts + hashes password
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final db = await DatabaseService().database;
    final normalizedEmail = email.trim().toLowerCase();

    // unique email guard
    final exists = await db.query(
      _usersTable,
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (exists.isNotEmpty) {
      throw EmailAlreadyUsed();
    }

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    final user = AppUser(
      email: normalizedEmail,
      displayName: fullName.trim(),
      passwordHash: hash,
      salt: salt,
      createdAt: DateTime.now(),
    );

    final id = await db.insert(_usersTable, user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);

    return AppUser(
      id: id,
      email: user.email,
      displayName: user.displayName,
      passwordHash: user.passwordHash,
      salt: user.salt,
      createdAt: user.createdAt,
    );
  }

  /// Login with email + password (throws InvalidCredentials on failure).
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final db = await DatabaseService().database;
    final normalizedEmail = email.trim().toLowerCase();

    final rows = await db.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw InvalidCredentials();
    }

    final user = AppUser.fromMap(rows.first);
    final computed = _hashPassword(password, user.salt);
    if (computed != user.passwordHash) {
      throw InvalidCredentials();
    }

    return user;
  }

  /// (Optional) Read-only helper to fetch user by email.
  Future<AppUser?> getByEmail(String email) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  // --- crypto helpers ---

  String _generateSalt([int length = 16]) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }
}
