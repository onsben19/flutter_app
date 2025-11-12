import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'journal_entries';
  static const String _usersTable = 'users'; // NEW

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Getter pour la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialiser la base de données
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'travel_journal.db');

    return await openDatabase(
      path,
      version: 2, // ⬆️ bumped from 1 to 2
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createUsersTable(db);
        }
      },
    );
  }

  // Créer les tables (fresh installs)
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
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

    // NEW: create users table on fresh DB
    await _createUsersTable(db);

    // Insérer des données d'exemple
    await _insertSampleData(db);
  }

  // NEW: helper to create the users table
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

  // Insérer des données d'exemple
  Future<void> _insertSampleData(Database db) async {
    final sampleEntries = [
      {
        'title': 'Arrivée à Paris',
        'content': 'Premier jour à Paris ! L\'ambiance est magique, nous avons pris un café près de Notre-Dame.',
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
        'content': 'Vue incroyable depuis le Trocadéro ! Les photos ne rendent pas justice à la beauté du moment.',
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
        'content': 'Pause gourmande chez Pierre Hermé. Les saveurs sont exceptionnelles !',
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
      await db.insert(_tableName, entry);
    }
  }

  // CRUD Operations

  // Créer une nouvelle entrée
  Future<int> insertEntry(JournalEntry entry) async {
    final db = await database;
    return await db.insert(_tableName, entry.toMap());
  }

  // Lire toutes les entrées
  Future<List<JournalEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'date DESC', // Plus récent en premier
    );

    return List.generate(maps.length, (i) {
      return JournalEntry.fromMap(maps[i]);
    });
  }

  // Lire une entrée par ID
  Future<JournalEntry?> getEntryById(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return JournalEntry.fromMap(maps.first);
    }
    return null;
  }

  // Mettre à jour une entrée
  Future<int> updateEntry(JournalEntry entry) async {
    final db = await database;
    return await db.update(
      _tableName,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Supprimer une entrée
  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Rechercher des entrées
  Future<List<JournalEntry>> searchEntries(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'title LIKE ? OR content LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return JournalEntry.fromMap(maps[i]);
    });
  }

  // Obtenir les entrées par type
  Future<List<JournalEntry>> getEntriesByType(String type) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return JournalEntry.fromMap(maps[i]);
    });
  }

  // Obtenir les entrées par humeur
  Future<List<JournalEntry>> getEntriesByMood(String mood) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'mood = ?',
      whereArgs: [mood],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return JournalEntry.fromMap(maps[i]);
    });
  }

  // Liker une entrée
  Future<void> likeEntry(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $_tableName SET likes = likes + 1 WHERE id = ?',
      [id],
    );
  }

  // Statistiques
  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final totalEntries = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    final totalLikes = await db.rawQuery('SELECT SUM(likes) as total FROM $_tableName');
    final totalPhotos = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE photos IS NOT NULL AND photos != ""'
    );

    return {
      'totalEntries': totalEntries.first['count'] as int,
      'totalLikes': (totalLikes.first['total'] as int?) ?? 0,
      'totalPhotos': totalPhotos.first['count'] as int,
    };
  }

  // Fermer la base de données
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Fonction de test de la base de données
  Future<bool> testDatabaseConfiguration() async {
    try {
      print('🧪 Testing database configuration...');

      // Test 1: Connexion à la base
      final db = await database;
      print('✅ Database connection successful');

      // Test 2: Vérification de la table
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'"
      );
      if (tables.isEmpty) {
        print('❌ Table $_tableName does not exist');
        return false;
      }
      print('✅ Table $_tableName exists');

      // Test 3: Test d'insertion
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

      // Test 4: Test de lecture
      final retrievedEntry = await getEntryById(insertedId);
      if (retrievedEntry == null) {
        print('❌ Failed to retrieve test entry');
        return false;
      }
      print('✅ Test retrieval successful');

      // Test 5: Test de suppression
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

  // Ajoutez cette fonction pour vérifier l'état de la base
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await database;

      // Vérifier si la table existe
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'"
      );

      final tableExists = tables.isNotEmpty;

      // Compter les entrées
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final entryCount = countResult.first['count'] as int;

      // Informations sur la base
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

  // Fonction pour réinitialiser la base (utile pour debug)
  Future<void> resetDatabase() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      await _insertSampleData(db);
      print('✅ Database reset successfully');
    } catch (e) {
      print('❌ Error resetting database: $e');
      rethrow;
    }
  }
}
