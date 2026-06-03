import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
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
      version: 6,
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
        gender TEXT,
        education TEXT,
        skills TEXT,
        cv_path TEXT,
        bio TEXT,
        profile_image TEXT,
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
        notes TEXT,
        interview_date_time TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

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

    await db.execute('''
      CREATE TABLE saved_company_favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        job_id TEXT NOT NULL,
        job_title TEXT NOT NULL,
        company_name TEXT NOT NULL,
        location TEXT,
        salary TEXT,
        saved_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE wishlist ADD COLUMN category TEXT');
        await db.execute('ALTER TABLE wishlist ADD COLUMN contract_type TEXT');
      } catch (e) {
        debugPrint('Error upgrade v2: $e');
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN full_name TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      } catch (e) {
        debugPrint('Error upgrade v3 (users): $e');
      }
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS applied_jobs (
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
        debugPrint('Error upgrade v3 (applied_jobs): $e');
      }
    }

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profile_image TEXT');
      } catch (e) {
        debugPrint('Error upgrade v4: $e');
      }
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN gender TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN education TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN skills TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN cv_path TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN bio TEXT');
      } catch (e) {
        debugPrint('Error upgrade v5 (users): $e');
      }
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS saved_company_favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            job_id TEXT NOT NULL,
            job_title TEXT NOT NULL,
            company_name TEXT NOT NULL,
            location TEXT,
            salary TEXT,
            saved_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        debugPrint('Error upgrade v5 (saved_company_favorites): $e');
      }
    }

    // Upgrade v6: restrukturisasi tabel interviews
    // Tambah kolom notes, rename interview_time -> interview_date_time,
    // hapus location_coords
    if (oldVersion < 6) {
      try {
        // SQLite tidak support DROP COLUMN / RENAME COLUMN di versi lama,
        // jadi pakai strategi: buat tabel baru, copy data, drop lama, rename
        await db.execute('''
          CREATE TABLE interviews_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_title TEXT NOT NULL,
            company_name TEXT NOT NULL,
            notes TEXT,
            interview_date_time TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Migrasi data lama — interview_time dipindah ke interview_date_time
        await db.execute('''
          INSERT INTO interviews_new (id, job_title, company_name, notes, interview_date_time, created_at)
          SELECT id, job_title, company_name, NULL, interview_time, created_at
          FROM interviews
        ''');

        await db.execute('DROP TABLE interviews');
        await db.execute('ALTER TABLE interviews_new RENAME TO interviews');

        debugPrint('Upgrade v6 berhasil: tabel interviews distrukturisasi');
      } catch (e) {
        debugPrint('Error upgrade v6 (interviews): $e');
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
    final existing = await db.query(
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
      'gender': '',
      'education': '',
      'skills': '',
      'cv_path': null,
      'bio': '',
      'profile_image': '',
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

  static const Object _sentinel = Object();

  Future<void> updateUserProfileFull(
    String username, {
    required String fullName,
    required String email,
    String? gender,
    String? education,
    List<String>? skills,
    Object? cvPath = _sentinel,
    String? bio,
    String? profileImagePath,
    String? newPassword,
  }) async {
    final db = await database;

    final Map<String, dynamic> updateData = {
      'full_name': fullName,
      'email': email,
      'gender': gender ?? '',
      'education': education ?? '',
      'skills': skills != null ? skills.join(',') : '',
      'bio': bio ?? '',
    };

    if (!identical(cvPath, _sentinel)) {
      updateData['cv_path'] = cvPath;
    }
    if (profileImagePath != null) {
      updateData['profile_image'] = profileImagePath;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      updateData['password'] = _hashPassword(newPassword);
    }

    debugPrint('updateUserProfileFull: $updateData');

    final rows = await db.update(
      'users',
      updateData,
      where: 'username = ?',
      whereArgs: [username],
    );
    debugPrint('Rows affected: $rows');
  }

  Future<void> updateProfileImage(String username, String imagePath) async {
    final db = await database;
    await db.update(
      'users',
      {'profile_image': imagePath},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<void> updateUserProfile(
    String username,
    String fullName,
    String email,
    String? newPassword,
  ) async {
    await updateUserProfileFull(
      username,
      fullName: fullName,
      email: email,
      newPassword: newPassword,
    );
  }

  // ========== INTERVIEW ==========

  /// Tambah jadwal interview baru
  Future<int> addInterview({
    required String jobTitle,
    required String companyName,
    String? notes,
    required DateTime interviewDateTime,
  }) async {
    final db = await database;
    return await db.insert('interviews', {
      'job_title': jobTitle,
      'company_name': companyName,
      'notes': notes,
      'interview_date_time': interviewDateTime.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Ambil semua jadwal, diurutkan dari yang paling dekat
  Future<List<Map<String, dynamic>>> getAllInterviews() async {
    final db = await database;
    return await db.query(
      'interviews',
      orderBy: 'interview_date_time ASC',
    );
  }

  /// Ambil jadwal yang akan datang (interview_date_time >= sekarang)
  Future<List<Map<String, dynamic>>> getUpcomingInterviews() async {
    final db = await database;
    return await db.query(
      'interviews',
      where: 'interview_date_time >= ?',
      whereArgs: [DateTime.now().toIso8601String()],
      orderBy: 'interview_date_time ASC',
    );
  }

  /// Ambil satu jadwal berdasarkan id
  Future<Map<String, dynamic>?> getInterviewById(int id) async {
    final db = await database;
    final res = await db.query(
      'interviews',
      where: 'id = ?',
      whereArgs: [id],
    );
    return res.isNotEmpty ? res.first : null;
  }

  /// Update jadwal interview
  Future<int> updateInterview({
    required int id,
    required String jobTitle,
    required String companyName,
    String? notes,
    required DateTime interviewDateTime,
  }) async {
    final db = await database;
    return await db.update(
      'interviews',
      {
        'job_title': jobTitle,
        'company_name': companyName,
        'notes': notes,
        'interview_date_time': interviewDateTime.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus jadwal interview
  Future<int> deleteInterview(int id) async {
    final db = await database;
    return await db.delete(
      'interviews',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== SAVED COMPANY FAVORITES ==========

  Future<int> saveCompanyFavorite(
    String username,
    Map<String, dynamic> job,
  ) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return 0;

    final existing = await db.query(
      'saved_company_favorites',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], job['id']],
    );
    if (existing.isNotEmpty) return 0;

    return await db.insert('saved_company_favorites', {
      'user_id': user['id'],
      'job_id': job['id'],
      'job_title': job['title'],
      'company_name': job['company'],
      'location': job['location'],
      'salary': job['salary'],
      'saved_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSavedCompanyFavorites(
    String username,
  ) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return [];
    return await db.query(
      'saved_company_favorites',
      where: 'user_id = ?',
      whereArgs: [user['id']],
      orderBy: 'saved_at DESC',
    );
  }

  Future<int> removeCompanyFavorite(String username, String jobId) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return 0;
    return await db.delete(
      'saved_company_favorites',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], jobId],
    );
  }

  Future<bool> isCompanyFavorite(String username, String jobId) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return false;
    final result = await db.query(
      'saved_company_favorites',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], jobId],
    );
    return result.isNotEmpty;
  }

  // ========== APPLIED JOBS ==========

  Future<void> saveAppliedJob(
      String username, Map<String, dynamic> job) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return;

    final existing = await db.query(
      'applied_jobs',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], job['id']],
    );
    if (existing.isNotEmpty) return;

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
    final res =
        await db.query('wishlist', where: 'id = ?', whereArgs: [jobId]);
    return res.isNotEmpty;
  }

  // ========== UTILITY ==========

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('wishlist');
    await db.delete('interviews');
    await db.delete('applied_jobs');
    await db.delete('saved_company_favorites');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}