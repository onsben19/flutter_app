import 'package:sqflite/sqflite.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import 'database_service.dart';

class GroupRepository {
  static const String _groupsTable = 'groups';
  static const String _groupMembersTable = 'group_members';
  static const String _usersTable = 'users';

  /// Create a group, auto-add owner, optionally add members by email.
  /// Returns (groupId, notFoundEmails).
  Future<(int groupId, List<String> notFound)> createGroup({
    required int ownerId,
    required String name,
    String? description,
    List<String> memberEmails = const [],
    DateTime? startDate,
    DateTime? endDate,
    String? imagePath, // ⬅️ NEW
  }) async {
    final db = await DatabaseService().database;

    return await db.transaction<(int, List<String>)>((txn) async {
      final groupId = await txn.insert(_groupsTable, {
        'name': name.trim(),
        'description':
        (description ?? '').trim().isEmpty ? null : description!.trim(),
        'owner_id': ownerId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'start_date': startDate?.millisecondsSinceEpoch,
        'end_date': endDate?.millisecondsSinceEpoch,
        'image_path': imagePath, // ⬅️ save image path
      });

      // owner membership
      await txn.insert(_groupMembersTable, {
        'group_id': groupId,
        'user_id': ownerId,
        'role': 'owner',
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });

      // resolve emails to user ids
      final notFound = <String>[];
      for (final raw in memberEmails) {
        final email = raw.trim().toLowerCase();
        if (email.isEmpty) continue;

        final rows = await txn.query(
          _usersTable,
          columns: ['id'],
          where: 'email = ?',
          whereArgs: [email],
          limit: 1,
        );

        if (rows.isEmpty) {
          notFound.add(email);
          continue;
        }

        final userId = rows.first['id'] as int;

        // insert member (ignore if duplicate)
        await txn.insert(
          _groupMembersTable,
          {
            'group_id': groupId,
            'user_id': userId,
            'role': 'member',
            'added_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      return (groupId, notFound);
    });
  }

  /// Join group_members -> users to fetch display_name + email + role
  Future<List<Map<String, dynamic>>> getMembersWithUser(int groupId) async {
    final db = await DatabaseService().database;
    return await db.rawQuery('''
      SELECT 
        gm.user_id,
        gm.role,
        gm.added_at,
        u.display_name,
        u.email
      FROM $_groupMembersTable gm
      INNER JOIN $_usersTable u ON u.id = gm.user_id
      WHERE gm.group_id = ?
      ORDER BY 
        CASE WHEN gm.role = 'owner' THEN 0 ELSE 1 END,
        u.display_name COLLATE NOCASE ASC
    ''', [groupId]);
  }

  Future<List<Group>> getGroupsForUser(int userId) async {
    final db = await DatabaseService().database;
    final rows = await db.rawQuery('''
      SELECT g.* FROM $_groupsTable g
      INNER JOIN $_groupMembersTable gm ON gm.group_id = g.id
      WHERE gm.user_id = ?
      ORDER BY g.created_at DESC
    ''', [userId]);

    return rows.map((m) => Group.fromMap(m)).toList();
  }

  Future<int> countMembers(int groupId) async {
    final db = await DatabaseService().database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_groupMembersTable WHERE group_id = ?',
      [groupId],
    );
    final c = res.first['c'];
    if (c is int) return c;
    if (c is num) return c.toInt();
    return 0;
  }

  Future<DateTime?> getStartDate(int groupId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      _groupsTable,
      columns: ['start_date'],
      where: 'id = ?',
      whereArgs: [groupId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final v = rows.first['start_date'];
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v as int);
  }

  Future<DateTime?> getEndDate(int groupId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      _groupsTable,
      columns: ['end_date'],
      where: 'id = ?',
      whereArgs: [groupId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final v = rows.first['end_date'];
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v as int);
  }

  Future<void> addMemberByEmail({
    required int groupId,
    required String email,
    String role = 'member',
  }) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      _usersTable,
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('Utilisateur introuvable: $email');
    }
    final userId = rows.first['id'] as int;

    await db.insert(
      _groupMembersTable,
      {
        'group_id': groupId,
        'user_id': userId,
        'role': role,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Remove a member
  Future<void> removeMember(int groupId, int userId) async {
    final db = await DatabaseService().database;
    await db.delete(
      _groupMembersTable,
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
  }

  // Delete a group (will cascade delete members)
  Future<void> deleteGroup(int groupId) async {
    final db = await DatabaseService().database;
    await db.delete(
      _groupsTable,
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  // --- Image helpers ---------------------------------------------------------

  /// Update or remove a group's image (pass null to clear).
  Future<void> updateGroupImage(int groupId, String? imagePath) async {
    final db = await DatabaseService().database;
    await db.update(
      _groupsTable,
      {'image_path': imagePath},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Fetch a raw row (e.g., to read image_path without changing your Group model)
  Future<Map<String, dynamic>> getRawGroupRow(int groupId) async {
    final db = await DatabaseService().database;
    final rows = await db.query(
      _groupsTable,
      where: 'id = ?',
      whereArgs: [groupId],
      limit: 1,
    );
    if (rows.isEmpty) return {};
    return rows.first;
  }
}
