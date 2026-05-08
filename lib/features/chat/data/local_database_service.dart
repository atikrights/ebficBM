import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  static Database? _database;

  factory LocalDatabaseService() => _instance;

  LocalDatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ebm_chat_mobile_v2.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY,
        client_id TEXT,
        sender_id INTEGER,
        receiver_id INTEGER,
        message TEXT,
        status TEXT,
        created_at TEXT,
        is_mine INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        partner_id TEXT PRIMARY KEY,
        last_message TEXT,
        last_message_at TEXT,
        unread_count INTEGER
      )
    ''');
  }

  Future<void> saveMessage(Map<String, dynamic> msg) async {
    final db = await database;
    await db.insert('messages', msg, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMessages(String partnerId) async {
    final db = await database;
    return await db.query('messages', 
      where: 'sender_id = ? OR receiver_id = ?', 
      whereArgs: [partnerId, partnerId],
      orderBy: 'id ASC'
    );
  }
}
