import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'travel_journal.db';
  static const int _databaseVersion = 2; // Augmenter la version

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table des entrées de journal
    await db.execute('''
      CREATE TABLE journal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        author TEXT NOT NULL,
        type TEXT NOT NULL,
        location TEXT NOT NULL,
        mood TEXT NOT NULL,
        photos TEXT,
        likes INTEGER DEFAULT 0,
        comments INTEGER DEFAULT 0
      )
    ''');

    // Table des commentaires
    await db.execute('''
      CREATE TABLE comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entryId INTEGER NOT NULL,
        author TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        likes INTEGER DEFAULT 0,
        FOREIGN KEY (entryId) REFERENCES journal_entries (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Créer la table comments si elle n'existe pas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entryId INTEGER NOT NULL,
          author TEXT NOT NULL,
          content TEXT NOT NULL,
          date TEXT NOT NULL,
          likes INTEGER DEFAULT 0,
          FOREIGN KEY (entryId) REFERENCES journal_entries (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // Méthodes pour les entrées de journal
  Future<int> insertEntry(JournalEntry entry) async {
    final db = await database;
    return await db.insert('journal_entries', entry.toMap());
  }

  Future<List<JournalEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'journal_entries',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return JournalEntry.fromMap(maps[i]);
    });
  }

  Future<void> likeEntry(int entryId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE journal_entries 
      SET likes = likes + 1 
      WHERE id = ?
    ''', [entryId]);
  }

  Future<void> deleteEntry(int entryId) async {
    final db = await database;
    await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
    // Les commentaires seront supprimés automatiquement grâce à ON DELETE CASCADE
  }

  // Méthodes pour les commentaires
  Future<int> insertComment({
    required int entryId,
    required String author,
    required String content,
  }) async {
    final db = await database;
    final commentId = await db.insert('comments', {
      'entryId': entryId,
      'author': author,
      'content': content,
      'date': DateTime.now().toIso8601String(),
      'likes': 0,
    });

    // Mettre à jour le compteur de commentaires dans l'entrée
    await db.rawUpdate('''
      UPDATE journal_entries 
      SET comments = comments + 1 
      WHERE id = ?
    ''', [entryId]);

    return commentId;
  }

  Future<List<Map<String, dynamic>>> getComments(int entryId) async {
    final db = await database;
    return await db.query(
      'comments',
      where: 'entryId = ?',
      whereArgs: [entryId],
      orderBy: 'date DESC',
    );
  }

  Future<void> likeComment(int commentId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE comments 
      SET likes = likes + 1 
      WHERE id = ?
    ''', [commentId]);
  }

  Future<void> deleteComment(int commentId, int entryId) async {
    final db = await database;
    await db.delete(
      'comments',
      where: 'id = ?',
      whereArgs: [commentId],
    );

    // Mettre à jour le compteur de commentaires dans l'entrée
    await db.rawUpdate('''
      UPDATE journal_entries 
      SET comments = comments - 1 
      WHERE id = ?
    ''', [entryId]);
  }

  // Fermer la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}