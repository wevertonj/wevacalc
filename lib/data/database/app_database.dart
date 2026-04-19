import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String _databaseName = 'wevacalc.db';
  static const int _databaseVersion = 1;

  final DatabaseFactory _databaseFactory;
  Database? _database;

  AppDatabase({DatabaseFactory? databaseFactory})
    : _databaseFactory = databaseFactory ?? databaseFactorySqflitePlugin;

  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }

    return _database!;
  }

  Future<void> initialize({bool inMemory = false}) async {
    final path = inMemory ? inMemoryDatabasePath : _databaseName;
    _database = await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expression TEXT NOT NULL,
        result TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        name TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
