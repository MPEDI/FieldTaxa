import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'fieldtaxa.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE field_items (
        id TEXT PRIMARY KEY,
        file_path TEXT,
        type INTEGER NOT NULL,
        source INTEGER NOT NULL,
        captured_at TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        lat REAL,
        lng REAL,
        is_obs_only INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sightings (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        observed_at TEXT NOT NULL,
        lat REAL,
        lng REAL,
        FOREIGN KEY (item_id) REFERENCES field_items(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE taxonomy_nodes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        id TEXT PRIMARY KEY,
        filter_labels TEXT NOT NULL DEFAULT '[]',
        date_from TEXT,
        date_to TEXT,
        searched_at TEXT NOT NULL,
        result_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
