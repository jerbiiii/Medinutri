import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medinutri.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6, // ← bumped de 5 à 6
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE chat_history ADD COLUMN is_archived INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE profiles ADD COLUMN activity_level TEXT DEFAULT "Modérée"',
      );
      await db.execute(
        'ALTER TABLE profiles ADD COLUMN allergies TEXT DEFAULT "Aucune"',
      );
      await db.execute(
        'ALTER TABLE profiles ADD COLUMN medical_conditions TEXT DEFAULT "Aucune"',
      );
      await db.execute(
        'ALTER TABLE profiles ADD COLUMN goal TEXT DEFAULT "Équilibre alimentaire"',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE chat_history ADD COLUMN conversation_id TEXT',
      );
      await db.execute(
        'ALTER TABLE chat_history ADD COLUMN conversation_title TEXT',
      );

      await db.execute('''
        CREATE TABLE IF NOT EXISTS nutrition_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          meals_json TEXT,
          tips_json TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      // Recréer ai_doctors avec doctor_id nullable
      await db.execute('DROP TABLE IF EXISTS ai_doctors');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ai_doctors (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doctor_id TEXT,
          name TEXT NOT NULL,
          specialty TEXT NOT NULL,
          rating TEXT,
          image_url TEXT,
          gender TEXT,
          created_at TEXT
        )
      ''');
    }
    if (oldVersion < 6) {
      // FIX: recréer ai_doctors pour s'assurer que doctor_id est bien nullable
      // (certains devices avaient doctor_id TEXT NOT NULL à cause d'un bug)
      await db.execute('DROP TABLE IF EXISTS ai_doctors');
      await db.execute('''
        CREATE TABLE ai_doctors (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doctor_id TEXT,
          name TEXT NOT NULL,
          specialty TEXT NOT NULL,
          rating TEXT,
          image_url TEXT,
          gender TEXT,
          created_at TEXT
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType UNIQUE,
        password_hash $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles (
        id $idType,
        user_id INTEGER NOT NULL,
        name $textType,
        age $intType,
        gender $textType,
        weight $realType,
        height $realType,
        activity_level $textType DEFAULT 'Modérée',
        allergies $textType DEFAULT 'Aucune',
        medical_conditions $textType DEFAULT 'Aucune',
        goal $textType DEFAULT 'Équilibre alimentaire',
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_history (
        id $idType,
        user_id INTEGER NOT NULL,
        role $textType,
        content $textType,
        timestamp $textType,
        is_archived INTEGER DEFAULT 0,
        conversation_id TEXT,
        conversation_title TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrition_plans (
        id $idType,
        user_id INTEGER NOT NULL,
        title $textType,
        description $textType,
        meals_json $textType,
        tips_json $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // FIX: doctor_id est TEXT nullable (pas NOT NULL)
    await db.execute('''
      CREATE TABLE ai_doctors (
        id $idType,
        doctor_id TEXT,
        name $textType,
        specialty $textType,
        rating TEXT,
        image_url TEXT,
        gender TEXT,
        created_at TEXT
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
