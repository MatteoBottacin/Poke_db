import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    String path = join(await getDatabasesPath(), "poke_db.db");
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {

      await db.execute('''
        CREATE TABLE sessione (
          id       INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id  INTEGER NOT NULL,
          username TEXT NOT NULL,
          token    TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE pokemon (
          id   INTEGER PRIMARY KEY,
          nome TEXT NOT NULL,
          url  TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE catturati (
          id           INTEGER PRIMARY KEY,
          user_id      INTEGER NOT NULL,
          pokemon_id   INTEGER NOT NULL,
          soprannome   TEXT,
          livello      INTEGER NOT NULL,
          data_cattura TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE squadra (
          id                   INTEGER PRIMARY KEY,
          pokemon_catturati_id INTEGER NOT NULL,
          posizione            INTEGER NOT NULL
        )
      ''');

    });
    return _db!;
  }

  static Future<void> insert(String table, Map<String, dynamic> values) async {
    Database db = await getDatabase();
    await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    Database db = await getDatabase();
    return await db.query(table);
  }

  static Future<List<Map<String, dynamic>>> getWhere(String table, String where, List<dynamic> args) async {
    Database db = await getDatabase();
    return await db.query(table, where: where, whereArgs: args);
  }

  static Future<void> deleteWhere(String table, String where, List<dynamic> args) async {
    Database db = await getDatabase();
    await db.delete(table, where: where, whereArgs: args);
  }
}
