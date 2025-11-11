import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:path/path.dart';
import '../models/journal_entry.dart';
import '../models/planification.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'journal_entries';
  static const String _planningTable = 'planning_suggestions';

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
    if (kIsWeb) {
      throw UnsupportedError('Local SQLite (sqflite) is not supported on Web.');
    }
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'travel_journal.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensurePlanningTable(db);
      },
    );
  }

  // Créer les tables
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

    // Insérer des données d'exemple
    await _insertSampleData(db);
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

  // Ensure planning table exists (idempotent)
  Future<void> _ensurePlanningTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_planningTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        duration TEXT,
        cost REAL DEFAULT 0,
        votes INTEGER DEFAULT 0,
        totalMembers INTEGER DEFAULT 0,
        suggestedBy TEXT NOT NULL,
        imageUrls TEXT,
        isVoted INTEGER DEFAULT 0,
        tripDay INTEGER DEFAULT 0,
        tripTime TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');
    final countRes = await db.rawQuery('SELECT COUNT(*) as c FROM $_planningTable');
    final c = countRes.first['c'] as int? ?? 0;
    if (c == 0) {
      await _insertPlanningSampleData(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _ensurePlanningTable(db);
      await _insertPlanningSampleData(db);
    }
    if (oldVersion < 3) {
      await _addColumnIfMissing(db, _planningTable, 'tripDay', 'INTEGER', defaultValue: '0');
      await _addColumnIfMissing(db, _planningTable, 'tripTime', 'TEXT', defaultValue: "''");
    }
  }

  Future<void> _addColumnIfMissing(Database db, String table, String column, String type, {String? defaultValue}) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => (row['name'] as String).toLowerCase() == column.toLowerCase());
    if (!exists) {
      final def = defaultValue != null ? ' DEFAULT $defaultValue' : '';
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type$def');
    }
  }

  // Insert sample planning suggestions
  Future<void> _insertPlanningSampleData(Database db) async {
    final suggestions = [
      {
        'title': 'Tour Eiffel',
        'description': 'Visite de la célèbre tour de Paris',
        'category': 'Monument',
        'duration': '2h',
        'cost': 25.0,
        'votes': 8,
        'totalMembers': 10,
        'suggestedBy': 'Marie',
        'imageUrls': '',
        'isVoted': 1,
        'tripDay': 1,
        'tripTime': '09:00',
        'createdAt': DateTime(2024, 6, 15).millisecondsSinceEpoch,
      },
      {
        'title': 'Louvre',
        'description': 'Musée d\'art et d\'histoire',
        'category': 'Musée',
        'duration': '4h',
        'cost': 17.0,
        'votes': 6,
        'totalMembers': 10,
        'suggestedBy': 'Pierre',
        'imageUrls': '',
        'isVoted': 0,
        'tripDay': 1,
        'tripTime': '14:00',
        'createdAt': DateTime(2024, 6, 16).millisecondsSinceEpoch,
      },
    ];

    for (final s in suggestions) {
      await db.insert(_planningTable, s);
    }
  }

  // ----------------- Planification CRUD -----------------

  Future<int> insertPlanification(Planification p) async {
    final db = await database;
    return await db.insert(_planningTable, p.toMap());
  }

  Future<List<Planification>> getAllPlanifications() async {
    final db = await database;
    final maps = await db.query(
      _planningTable,
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Planification.fromMap(maps[i]));
  }

  Future<Planification?> getPlanificationById(int id) async {
    final db = await database;
    final maps = await db.query(
      _planningTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return Planification.fromMap(maps.first);
    return null;
  }

  Future<int> updatePlanification(Planification p) async {
    final db = await database;
    return await db.update(
      _planningTable,
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<int> deletePlanification(int id) async {
    final db = await database;
    return await db.delete(
      _planningTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Planification>> searchPlanifications(String query) async {
    final db = await database;
    final maps = await db.query(
      _planningTable,
      where: 'title LIKE ? OR description LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Planification.fromMap(maps[i]));
  }

  Future<List<Planification>> getPlanificationsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      _planningTable,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Planification.fromMap(maps[i]));
  }

  Future<void> toggleVote(int id) async {
    final db = await database;
    final row = await db.query(_planningTable, where: 'id = ?', whereArgs: [id], limit: 1);
    if (row.isEmpty) return;
    final current = row.first;
    final isVoted = (current['isVoted'] as int? ?? 0) == 1;
    final currentVotes = (current['votes'] as int? ?? 0);
    final newVotes = isVoted ? (currentVotes - 1) : (currentVotes + 1);
    await db.update(
      _planningTable,
      {
        'isVoted': isVoted ? 0 : 1,
        'votes': newVotes < 0 ? 0 : newVotes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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
