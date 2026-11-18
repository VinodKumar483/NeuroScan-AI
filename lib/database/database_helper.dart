import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('neuroscan_ai.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    String path;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      path = fileName;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, fileName);
    }

    return await openDatabase(
      path,
      version: 5,

      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: _createDB,

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN profile_image_path TEXT',
          );
        }

        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE scan_history ADD COLUMN prediction_data TEXT',
          );
        }

        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE scan_history ADD COLUMN image_data BLOB',
          );
        }

        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE scan_history ADD COLUMN patient_details TEXT',
          );
        }
      },
    );
  }

  // CREATE TABLES
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        profile_image_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        prediction TEXT NOT NULL,
        confidence REAL NOT NULL,
        probabilities TEXT,
        prediction_data TEXT,
        image_data BLOB,
        patient_details TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        notifications_enabled INTEGER DEFAULT 1,
        theme TEXT DEFAULT 'dark',
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  // USER REGISTRATION
  Future<int> insertUser({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    final db = await database;

    return await db.insert('users', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password_hash': passwordHash,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // GET USER BY EMAIL
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  // GET USER BY ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  // UPDATE PROFILE IMAGE PATH
  Future<int> updateUserProfileImage(int userId, String imagePath) async {
    final db = await database;

    return await db.update(
      'users',
      {'profile_image_path': imagePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // INSERT MRI SCAN RESULT INTO DATABASE
  Future<int> insertScanHistory({
    required int userId,
    required String imagePath,
    required String prediction,
    required double confidence,
    String? probabilities,
    String? predictionData,
    Uint8List? imageData,
    String? patientDetails,
  }) async {
    final db = await database;

    return await db.insert('scan_history', {
      'user_id': userId,
      'image_path': imagePath,
      'prediction': prediction,
      'confidence': confidence,
      'probabilities': probabilities,
      'prediction_data': predictionData,
      'image_data': imageData,
      'patient_details': patientDetails,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // GET SCAN HISTORY OF A SPECIFIC USER
  Future<List<Map<String, dynamic>>> getScanHistoryByUser(int userId) async {
    final db = await database;

    return await db.query(
      'scan_history',
      columns: kIsWeb
          ? null
          : [
              'id',
              'user_id',
              'image_path',
              'prediction',
              'confidence',
              'probabilities',
              'prediction_data',
              'patient_details',
              'created_at',
            ],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  // DELETE A SPECIFIC SCAN
  Future<int> deleteScanHistory(int scanId) async {
    final db = await database;

    return await db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [scanId],
    );
  }

  // DELETE ALL SCANS OF A SPECIFIC USER
  Future<int> deleteAllScanHistoryByUser(int userId) async {
    final db = await database;

    return await db.delete(
      'scan_history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // CLOSE DATABASE
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
