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
      version: 5, // Naikkan versi ke 5
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel users dengan semua kolom lengkap
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

    // Tabel saved_company_favorites untuk menyimpan perusahaan favorit
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

  // Perbaikan logic onUpgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from v$oldVersion to v$newVersion');

    // Upgrade ke versi 2: tambah category dan contract_type ke wishlist
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE wishlist ADD COLUMN category TEXT');
        await db.execute('ALTER TABLE wishlist ADD COLUMN contract_type TEXT');
        print('✓ Upgrade ke v2 berhasil');
      } catch (e) {
        print('Error upgrade ke v2: $e');
      }
    }

    // Upgrade ke versi 3: tambah full_name dan email ke users
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN full_name TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
        print('✓ Upgrade ke v3 berhasil');
      } catch (e) {
        print('Error upgrade ke v3: $e');
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
        print('✓ Tabel applied_jobs dibuat');
      } catch (e) {
        print('Error membuat applied_jobs: $e');
      }
    }

    // Upgrade ke versi 4: tambah kolom profile_image
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profile_image TEXT');
        print('✓ Upgrade ke v4 berhasil (profile_image)');
      } catch (e) {
        print('Error upgrade ke v4: $e');
      }
    }

    // Upgrade ke versi 5: tambah gender, education, skills, cv_path, bio
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN gender TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN education TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN skills TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN cv_path TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN bio TEXT');
        print(
          '✓ Upgrade ke v5 berhasil (gender, education, skills, cv_path, bio)',
        );
      } catch (e) {
        print('Error upgrade ke v5: $e');
      }

      // Buat tabel saved_company_favorites
      try {
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
        print('✓ Tabel saved_company_favorites dibuat');
      } catch (e) {
        print('Error membuat saved_company_favorites: $e');
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
      'gender': '',
      'education': '',
      'skills': '',
      'cv_path': '',
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

  // Update user profile (lengkap)
  Future<void> updateUserProfileFull(
    String username, {
    required String fullName,
    required String email,
    String? gender,
    String? education,
    List<String>? skills,
    String? cvPath,
    String? bio,
    String? profileImagePath,
    String? newPassword,
  }) async {
    final db = await database;

    Map<String, dynamic> updateData = {'full_name': fullName, 'email': email};

    if (gender != null) updateData['gender'] = gender;
    if (education != null) updateData['education'] = education;
    if (skills != null) updateData['skills'] = skills.join(',');
    if (cvPath != null) updateData['cv_path'] = cvPath;
    if (bio != null) updateData['bio'] = bio;
    if (profileImagePath != null)
      updateData['profile_image'] = profileImagePath;
    if (newPassword != null && newPassword.isNotEmpty) {
      updateData['password'] = _hashPassword(newPassword);
    }
    if (cvPath != null) {
      updateData['cv_path'] = cvPath;
    } else {
      updateData['cv_path'] = null;
    }

    print('Update data: $updateData');

    await db.update(
      'users',
      updateData,
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // Update profile image
  Future<void> updateProfileImage(String username, String imagePath) async {
    final db = await database;
    await db.update(
      'users',
      {'profile_image': imagePath},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // Update user profile sederhana (untuk kompatibilitas)
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

  // ========== SAVED COMPANY FAVORITES (PEKERJAAN TERSIMPAN) ==========

  // Simpan company favorit
  Future<int> saveCompanyFavorite(
    String username,
    Map<String, dynamic> job,
  ) async {
    final db = await database;

    final user = await getUserByUsername(username);
    if (user == null) return 0;

    // Cek apakah sudah ada
    final existing = await db.query(
      'saved_company_favorites',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [user['id'], job['id']],
    );

    if (existing.isNotEmpty) return 0; // Sudah ada

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

  // Ambil semua company favorit user
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

  // Hapus company favorit
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

  // Cek apakah company sudah difavoritkan
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

  // Tambahkan method baru di database_helper.dart
  Future<void> deleteCvPath(String username) async {
    final db = await database;
    await db.rawUpdate('UPDATE users SET cv_path = NULL WHERE username = ?', [
      null,
      username,
    ]);
    print('CV path deleted from database for user: $username');
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
