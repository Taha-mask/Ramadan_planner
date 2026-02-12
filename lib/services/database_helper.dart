import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/assessment.dart';
import '../models/azkar_stat.dart';
import '../models/quran.dart';
import '../models/todo.dart';
import '../models/worship.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ramadan_planner.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS azkar_stats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT,
          zikrText TEXT,
          count INTEGER
        )
      ''');
    }
    if (oldVersion < 3) {
      // Version 3 was from-to range
      await db.execute('DROP TABLE IF EXISTS quran_progress');
      await db.execute('''
        CREATE TABLE quran_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT,
          juzFrom INTEGER,
          surahFrom TEXT,
          pageFrom INTEGER,
          ayahFrom INTEGER,
          juzTo INTEGER,
          surahTo TEXT,
          pageTo INTEGER,
          ayahTo INTEGER
        )
      ''');
    }
    if (oldVersion < 4) {
      // Simplified point progress
      await db.execute('DROP TABLE IF EXISTS quran_progress');
      await db.execute('''
        CREATE TABLE quran_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT,
          juz INTEGER,
          surah TEXT,
          page INTEGER,
          ayah INTEGER
        )
      ''');
    }
    if (oldVersion < 5) {
      // Add type to todos
      await db.execute("ALTER TABLE todos ADD COLUMN type TEXT DEFAULT 'todo'");
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE worship (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        prayerName TEXT,
        isCompleted INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE quran_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        juz INTEGER,
        surah TEXT,
        page INTEGER,
        ayah INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        isCompleted INTEGER,
        date TEXT,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        rating REAL,
        dua TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE azkar_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        zikrText TEXT,
        count INTEGER
      )
    ''');
  }

  // Generic methods for Worship
  Future<int> insertWorship(WorshipEntry entry) async {
    Database db = await database;
    return await db.insert(
      'worship',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WorshipEntry>> getWorshipByDate(String date) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'worship',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) => WorshipEntry.fromMap(maps[i]));
  }

  // Generic methods for Quran
  Future<int> insertQuranProgress(QuranProgress progress) async {
    Database db = await database;
    return await db.insert(
      'quran_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Generic methods for Todos
  Future<int> insertTodo(TodoTask todo) async {
    Database db = await database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<TodoTask>> getTodosByDate(String date) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) => TodoTask.fromMap(maps[i]));
  }

  Future<int> updateTodo(TodoTask todo) async {
    Database db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(int id) async {
    Database db = await database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // Generic methods for Assessment
  Future<int> insertAssessment(DailyAssessment assessment) async {
    Database db = await database;
    return await db.insert(
      'assessments',
      assessment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailyAssessment?> getAssessmentByDate(String date) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
    if (maps.isEmpty) return null;
    return DailyAssessment.fromMap(maps.first);
  }

  // Generic methods for Azkar Stats
  Future<void> incrementAzkarCount(
    String date,
    String text, {
    int count = 1,
  }) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'azkar_stats',
      where: 'date = ? AND zikrText = ?',
      whereArgs: [date, text],
    );

    if (maps.isEmpty) {
      await db.insert('azkar_stats', {
        'date': date,
        'zikrText': text,
        'count': count,
      });
    } else {
      int currentCount = maps.first['count'];
      await db.update(
        'azkar_stats',
        {'count': currentCount + count},
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAzkarStatsByDate(String date) async {
    Database db = await database;
    return await db.query(
      'azkar_stats',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'count DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPrayerStatsLast7Days() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT date, COUNT(*) as completed_count 
      FROM worship 
      WHERE isCompleted = 1 
      GROUP BY date 
      ORDER BY date DESC 
      LIMIT 7
    ''');
  }

  Future<List<Map<String, dynamic>>> getAssessmentStatsLast7Days() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT date, rating 
      FROM assessments 
      ORDER BY date DESC 
      LIMIT 7
    ''');
  }

  Future<List<QuranProgress>> getQuranByDate(String date) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quran_progress',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) => QuranProgress.fromMap(maps[i]));
  }

  Future<List<AzkarStat>> getAzkarStatsListByDate(String date) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'azkar_stats',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) => AzkarStat.fromMap(maps[i]));
  }
}
