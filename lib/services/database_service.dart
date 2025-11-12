import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';

class DatabaseService {
  static Database? _database;

  // Table names
  static const String _journalTable = 'journal_entries';
  static const String _usersTable = 'users';
  static const String _groupsTable = 'groups';
  static const String _groupMembersTable = 'group_members';

  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Getter DB
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Init DB (⇧ bump to v4 to add groups.image_path)
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'travel_journal.db');

    return await openDatabase(
      path,
      version: 4, // v1: journal, v2: users, v3: groups+members(+dates), v4: groups.image_path
      onConfigure: (db) async {
        // Enforce foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        // v2: add users (if upgrading from v1)
        if (oldVersion < 2) {
          await _createUsersTable(db);
        }
        // v3: add groups + group_members (+ start/end dates)
        if (oldVersion < 3) {
          await _createGroupsTables(db);
        }
        // v4: add image_path to groups
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE $_groupsTable ADD COLUMN image_path TEXT');
          } catch (_) {
            // Column may already exist if table was recreated; ignore
          }
        }
      },
    );
  }

  // Create all tables for fresh install
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_journalTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date INTEGER NOT NULL,
        author TEXT NOT NULL,
        type TEXT NOT NULL,
        location TEXT NOT NULL,
        mood TEXT NOT NULL,
        photos TEXT,
        likes INTEGER DEFAULT 0,
        comments INTEGER DEFAULT 0
      )
    ''');

    await _createUsersTable(db);
    await _createGroupsTables(db);

    // Insert sample data for journal
    await _insertSampleData(db);
  }

  // ---------- Table creators

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createGroupsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_groupsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        owner_id INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        start_date INTEGER,
        end_date INTEGER,
        image_path TEXT,
        FOREIGN KEY (owner_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_groupMembersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role TEXT NOT NULL, -- 'owner' | 'member'
        added_at INTEGER NOT NULL,
        UNIQUE (group_id, user_id),
        FOREIGN KEY (group_id) REFERENCES $_groupsTable(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');
  }

  // ---------- Sample data for journal
  Future<void> _insertSampleData(Database db) async {
    final sampleEntries = [
      {
        'title': 'Arrivée à Paris',
        'content':
        'Premier jour à Paris ! L\'ambiance est magique, nous avons pris un café près de Notre-Dame.',
        'date': DateTime(2024, 6, 15, 14, 30).millisecondsSinceEpoch,
        'author': 'Marie',
        'type': 'text',
        'location': 'Paris, France',
        'mood': 'excited',
        'photos': '',
        'likes': 5,
        'comments': 2,
      },
      {
        'title': 'Tour Eiffel au coucher du soleil',
        'content':
        'Vue incroyable depuis le Trocadéro ! Les photos ne rendent pas justice à la beauté du moment.',
        'date': DateTime(2024, 6, 15, 19, 45).millisecondsSinceEpoch,
        'author': 'Pierre',
        'type': 'photo',
        'location': 'Tour Eiffel, Paris',
        'mood': 'amazed',
        'photos': '',
        'likes': 8,
        'comments': 3,
      },
      {
        'title': 'Dégustation de macarons',
        'content':
        'Pause gourmande chez Pierre Hermé. Les saveurs sont exceptionnelles !',
        'date': DateTime(2024, 6, 16, 11, 15).millisecondsSinceEpoch,
        'author': 'Julie',
        'type': 'food',
        'location': 'Champs-Élysées, Paris',
        'mood': 'happy',
        'photos': '',
        'likes': 6,
        'comments': 1,
      },
    ];

    for (final entry in sampleEntries) {
      await db.insert(_journalTable, entry);
    }
  }

  // ---------- JOURNAL CRUD (unchanged)

  Future<int> insertEntry(JournalEntry entry) async {
    final db = await database;
    return await db.insert(_journalTable, entry.toMap());
  }

  Future<List<JournalEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query(_journalTable, orderBy: 'date DESC');
    return List.generate(maps.length, (i) => JournalEntry.fromMap(maps[i]));
  }

  Future<JournalEntry?> getEntryById(int id) async {
    final db = await database;
    final maps = await db.query(
      _journalTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return JournalEntry.fromMap(maps.first);
    return null;
  }

  Future<int> updateEntry(JournalEntry entry) async {
    final db = await database;
    return await db.update(
      _journalTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete(_journalTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<JournalEntry>> searchEntries(String query) async {
    final db = await database;
    final maps = await db.query(
      _journalTable,
      where: 'title LIKE ? OR content LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => JournalEntry.fromMap(maps[i]));
  }

  Future<List<JournalEntry>> getEntriesByType(String type) async {
    final db = await database;
    final maps = await db.query(
      _journalTable,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => JournalEntry.fromMap(maps[i]));
  }

  Future<List<JournalEntry>> getEntriesByMood(String mood) async {
    final db = await database;
    final maps = await db.query(
      _journalTable,
      where: 'mood = ?',
      whereArgs: [mood],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => JournalEntry.fromMap(maps[i]));
  }

  Future<void> likeEntry(int id) async {
    final db = await database;
    await db.rawUpdate('UPDATE $_journalTable SET likes = likes + 1 WHERE id = ?', [id]);
  }

  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final totalEntries =
    await db.rawQuery('SELECT COUNT(*) as count FROM $_journalTable');
    final totalLikes =
    await db.rawQuery('SELECT SUM(likes) as total FROM $_journalTable');
    final totalPhotos = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_journalTable WHERE photos IS NOT NULL AND photos != ""');

    return {
      'totalEntries': (totalEntries.first['count'] as int?) ?? 0,
      'totalLikes': (totalLikes.first['total'] as int?) ?? 0,
      'totalPhotos': (totalPhotos.first['count'] as int?) ?? 0,
    };
  }

  // ---------- Utility

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<bool> testDatabaseConfiguration() async {
    try {
      print('🧪 Testing database configuration...');
      final db = await database;
      print('✅ Database connection successful');

      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$_journalTable'");
      if (tables.isEmpty) {
        print('❌ Table $_journalTable does not exist');
        return false;
      }
      print('✅ Table $_journalTable exists');

      final testEntry = JournalEntry(
        title: 'Test Entry',
        content: 'This is a test entry',
        date: DateTime.now(),
        author: 'Test User',
        type: 'text',
        location: 'Test Location',
        mood: 'neutral',
        photos: [],
      );

      final insertedId = await insertEntry(testEntry);
      print('✅ Test insertion successful (ID: $insertedId)');

      final retrievedEntry = await getEntryById(insertedId);
      if (retrievedEntry == null) {
        print('❌ Failed to retrieve test entry');
        return false;
      }
      print('✅ Test retrieval successful');

      await deleteEntry(insertedId);
      final deletedEntry = await getEntryById(insertedId);
      if (deletedEntry != null) {
        print('❌ Failed to delete test entry');
        return false;
      }
      print('✅ Test deletion successful');

      print('🎉 All database tests passed!');
      return true;
    } catch (e) {
      print('❌ Database test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await database;

      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$_journalTable'");
      final tableExists = tables.isNotEmpty;

      final countResult =
      await db.rawQuery('SELECT COUNT(*) as count FROM $_journalTable');
      final entryCount = (countResult.first['count'] as int?) ?? 0;

      final info = {
        'database_path': db.path,
        'table_exists': tableExists,
        'entry_count': entryCount,
        'database_version': await db.getVersion(),
        'last_check': DateTime.now().toIso8601String(),
      };

      print('📊 Database Info: $info');
      return info;
    } catch (e) {
      print('❌ Error getting database info: $e');
      return {'error': e.toString()};
    }
  }

  Future<void> resetDatabase() async {
    try {
      final db = await database;
      await db.delete(_journalTable);
      await _insertSampleData(db);
      print('✅ Database reset successfully');
    } catch (e) {
      print('❌ Error resetting database: $e');
      rethrow;
    }
  }
}
