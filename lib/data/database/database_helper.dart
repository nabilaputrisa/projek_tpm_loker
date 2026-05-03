import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'job_portal.db');
    return await openDatabase(
      path,
      version: 3, // ← naikkan versi ke 3 untuk upgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        full_name TEXT,
        email TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE wishlist (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        company TEXT,
        location TEXT,
        salary TEXT,
        category TEXT,
        contract_type TEXT,
        added_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE interviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_title TEXT NOT NULL,
        company_name TEXT NOT NULL,
        interview_time TEXT NOT NULL,
        location_coords TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabel applied_jobs untuk menyimpan riwayat lamaran
    await db.execute('''
      CREATE TABLE applied_jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        job_id TEXT NOT NULL,
        job_title TEXT NOT NULL,
        company TEXT,
        location TEXT,
        salary TEXT,
        status TEXT DEFAULT 'Applied',
        applied_date TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Migrasi dari v1 → v2 → v3
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE wishlist ADD COLUMN category TEXT');
      await db.execute('ALTER TABLE wishlist ADD COLUMN contract_type TEXT');
    }

    if (oldVersion < 3) {
      // Tambah kolom full_name dan email ke tabel users
      try {
        await db.execute('ALTER TABLE users ADD COLUMN full_name TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      } catch (e) {
        print('Error adding columns to users: $e');
      }

      // Buat tabel applied_jobs
      try {
        await db.execute('''
          CREATE TABLE applied_jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            job_id TEXT NOT NULL,
            job_title TEXT NOT NULL,
            company TEXT,
            location TEXT,
            salary TEXT,
            status TEXT DEFAULT 'Applied',
            applied_date TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        print('Error creating applied_jobs table: $e');
      }
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ========== USER AUTH ==========

  Future<int> registerUser(String username, String password) async {
    final db = await database;
    List<Map<String, dynamic>> existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (existing.isNotEmpty) throw Exception('Username sudah digunakan');
    return await db.insert('users', {
      'username': username,
      'password': _hashPassword(password),
      'full_name': '',
      'email': '',
    });
  }

  Future<bool> loginUser(String username, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, _hashPassword(password)],
    );
    return res.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return res.isNotEmpty ? res.first : null;
  }

  // ========== PROFILE METHODS ==========

  // Update user profile
  Future<void> updateUserProfile(
    String username,
    String fullName,
    String email,
    String? newPassword,
  ) async {
    final db = await database;

    Map<String, dynamic> updateData = {'full_name': fullName, 'email': email};

    if (newPassword != null && newPassword.isNotEmpty) {
      updateData['password'] = _hashPassword(newPassword);
    }

    await db.update(
      'users',
      updateData,
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // ========== APPLIED JOBS METHODS ==========

  // Simpan lamaran pekerjaan
  Future<void> saveAppliedJob(String username, Map<String, dynamic> job) async {
    final db = await database;

    final user = await getUserByUsername(username);
    if (user == null) return;

    // Cek apakah sudah pernah melamar job ini
    final existing = await db.query(
      'applied_jobs',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], job['id']],
    );

    if (existing.isNotEmpty) return; // Sudah pernah melamar

    await db.insert('applied_jobs', {
      'user_id': user['id'],
      'job_id': job['id'],
      'job_title': job['title'],
      'company': job['company'],
      'location': job['location'],
      'salary': job['salary'],
      'status': 'Applied',
      'applied_date': DateTime.now().toIso8601String(),
    });
  }

  // Ambil semua lamaran user
  Future<List<Map<String, dynamic>>> getAppliedJobs(String username) async {
    final db = await database;

    final user = await getUserByUsername(username);
    if (user == null) return [];

    return await db.query(
      'applied_jobs',
      where: 'user_id = ?',
      whereArgs: [user['id']],
      orderBy: 'applied_date DESC',
    );
  }

  // Cek apakah sudah melamar job tertentu
  Future<bool> hasApplied(String username, String jobId) async {
    final db = await database;

    final user = await getUserByUsername(username);
    if (user == null) return false;

    final result = await db.query(
      'applied_jobs',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], jobId],
    );

    return result.isNotEmpty;
  }

  // Hapus lamaran (opsional)
  Future<int> removeAppliedJob(String username, String jobId) async {
    final db = await database;

    final user = await getUserByUsername(username);
    if (user == null) return 0;

    return await db.delete(
      'applied_jobs',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], jobId],
    );
  }

  // ========== WISHLIST ==========

  Future<int> addToWishlist(Map<String, dynamic> job) async {
    final db = await database;
    return await db.insert(
      'wishlist',
      job,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getWishlist() async {
    final db = await database;
    return await db.query('wishlist', orderBy: 'added_at DESC');
  }

  Future<int> removeFromWishlist(String jobId) async {
    final db = await database;
    return await db.delete('wishlist', where: 'id = ?', whereArgs: [jobId]);
  }

  Future<bool> isInWishlist(String jobId) async {
    final db = await database;
    final res = await db.query('wishlist', where: 'id = ?', whereArgs: [jobId]);
    return res.isNotEmpty;
  }

  // ========== INTERVIEW ==========

  Future<int> addInterview(Map<String, dynamic> interview) async {
    final db = await database;
    return await db.insert('interviews', interview);
  }

  Future<List<Map<String, dynamic>>> getAllInterviews() async {
    final db = await database;
    return await db.query('interviews', orderBy: 'interview_time ASC');
  }

  Future<int> updateInterview(int id, Map<String, dynamic> interview) async {
    final db = await database;
    return await db.update(
      'interviews',
      interview,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInterview(int id) async {
    final db = await database;
    return await db.delete('interviews', where: 'id = ?', whereArgs: [id]);
  }

  // ========== UTILITY ==========

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('wishlist');
    await db.delete('interviews');
    await db.delete('applied_jobs');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
