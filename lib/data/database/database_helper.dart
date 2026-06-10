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
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel users
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

    // Tabel wishlist (DENGAN user_id)
    await db.execute('''
      CREATE TABLE wishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        job_id TEXT NOT NULL,
        title TEXT NOT NULL,
        company TEXT,
        location TEXT,
        salary TEXT,
        category TEXT,
        contract_type TEXT,
        added_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, job_id)
      )
    ''');

    // Tabel interviews (DENGAN user_id)
    await db.execute('''
      CREATE TABLE interviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        job_title TEXT NOT NULL,
        company_name TEXT NOT NULL,
        notes TEXT,
        interview_date_time TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabel applied_jobs
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

    // Tabel saved_company_favorites
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

    if (oldVersion < 6) {
      try {
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

    // ============================================
    // MIGRASI VERSI 7: TAMBAHKAN user_id KE wishlist DAN interviews
    // ============================================
    if (oldVersion < 7) {
      try {
        debugPrint('Running migration to version 7: Add user_id to wishlist and interviews');
        
        // -----------------------------------------------------------------
        // 1. PERBAIKI TABEL WISHLIST
        // -----------------------------------------------------------------
        await db.execute('''
          CREATE TABLE wishlist_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            job_id TEXT NOT NULL,
            title TEXT NOT NULL,
            company TEXT,
            location TEXT,
            salary TEXT,
            category TEXT,
            contract_type TEXT,
            added_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            UNIQUE(user_id, job_id)
          )
        ''');
        
        await db.execute('''
          INSERT INTO wishlist_new (user_id, job_id, title, company, location, salary, category, contract_type, added_at)
          SELECT 
            (SELECT id FROM users LIMIT 1),
            id, title, company, location, salary, category, contract_type, added_at
          FROM wishlist
          WHERE EXISTS (SELECT 1 FROM users LIMIT 1)
        ''');
        
        await db.execute('DROP TABLE wishlist');
        await db.execute('ALTER TABLE wishlist_new RENAME TO wishlist');
        
        // -----------------------------------------------------------------
        // 2. PERBAIKI TABEL INTERVIEWS
        // -----------------------------------------------------------------
        await db.execute('''
          CREATE TABLE interviews_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            job_title TEXT NOT NULL,
            company_name TEXT NOT NULL,
            notes TEXT,
            interview_date_time TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
        
        await db.execute('''
          INSERT INTO interviews_new (user_id, job_title, company_name, notes, interview_date_time, created_at)
          SELECT 
            (SELECT id FROM users LIMIT 1),
            job_title, company_name, notes, interview_date_time, created_at
          FROM interviews
          WHERE EXISTS (SELECT 1 FROM users LIMIT 1)
        ''');
        
        await db.execute('DROP TABLE interviews');
        await db.execute('ALTER TABLE interviews_new RENAME TO interviews');
        
        debugPrint('Migration to version 7 completed successfully!');
        
      } catch (e) {
        debugPrint('Error upgrading to version 7: $e');
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

    await db.update(
      'users',
      updateData,
      where: 'username = ?',
      whereArgs: [username],
    );
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

  // ========== WISHLIST METHODS (DENGAN user_id) ==========

  Future<int> addToWishlist(String username, Map<String, dynamic> job) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return 0;
    
    final existing = await db.query(
      'wishlist',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], job['job_id']],
    );
    if (existing.isNotEmpty) return 0;
    
    return await db.insert('wishlist', {
      'user_id': user['id'],
      'job_id': job['job_id'],
      'title': job['title'],
      'company': job['company'],
      'location': job['location'],
      'salary': job['salary'],
      'category': job['category'],
      'contract_type': job['contract_type'],
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getWishlist(String username) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return [];
    
    return await db.query(
      'wishlist',
      where: 'user_id = ?',
      whereArgs: [user['id']],
      orderBy: 'added_at DESC',
    );
  }

  Future<int> removeFromWishlist(String username, String jobId) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return 0;
    
    return await db.delete(
      'wishlist',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], jobId],
    );
  }

  Future<bool> isInWishlist(String username, String jobId) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return false;
    
    final result = await db.query(
      'wishlist',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], jobId],
    );
    return result.isNotEmpty;
  }

  Future<int> clearWishlist(String username) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return 0;
    
    return await db.delete(
      'wishlist',
      where: 'user_id = ?',
      whereArgs: [user['id']],
    );
  }

  // ========== INTERVIEW METHODS (DENGAN user_id) ==========

  Future<int> addInterview({
    required String username,
    required String jobTitle,
    required String companyName,
    String? notes,
    required DateTime interviewDateTime,
  }) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return 0;
    
    return await db.insert('interviews', {
      'user_id': user['id'],
      'job_title': jobTitle,
      'company_name': companyName,
      'notes': notes,
      'interview_date_time': interviewDateTime.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllInterviews(String username) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return [];
    
    return await db.query(
      'interviews',
      where: 'user_id = ?',
      whereArgs: [user['id']],
      orderBy: 'interview_date_time ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getUpcomingInterviews(String username) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return [];
    
    return await db.query(
      'interviews',
      where: 'user_id = ? AND interview_date_time >= ?',
      whereArgs: [user['id'], DateTime.now().toIso8601String()],
      orderBy: 'interview_date_time ASC',
    );
  }

  Future<Map<String, dynamic>?> getInterviewById(int id, String username) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return null;
    
    final res = await db.query(
      'interviews',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, user['id']],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateInterview({
    required int id,
    required String username,
    required String jobTitle,
    required String companyName,
    String? notes,
    required DateTime interviewDateTime,
  }) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return 0;
    
    return await db.update(
      'interviews',
      {
        'job_title': jobTitle,
        'company_name': companyName,
        'notes': notes,
        'interview_date_time': interviewDateTime.toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, user['id']],
    );
  }

  Future<int> deleteInterview(int id, String username) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return 0;
    
    return await db.delete(
      'interviews',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, user['id']],
    );
  }

  // ========== APPLIED JOBS METHODS ==========

  Future<void> saveAppliedJob(String username, Map<String, dynamic> job) async {
    final db = await database;
    final user = await getUserByUsername(username);
    if (user == null) return;

    final existing = await db.query(
      'applied_jobs',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], job['job_id']],
    );
    if (existing.isNotEmpty) return;

    await db.insert('applied_jobs', {
      'user_id': user['id'],
      'job_id': job['job_id'],
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

  // ========== SAVED COMPANY FAVORITES ==========

  Future<int> saveCompanyFavorite(String username, Map<String, dynamic> job) async {
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

  Future<List<Map<String, dynamic>>> getSavedCompanyFavorites(String username) async {
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