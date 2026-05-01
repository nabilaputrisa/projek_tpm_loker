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
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Membuat tabel-tabel yang dibutuhkan
  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel User untuk Login 
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Tabel Wishlist untuk simpan lowongan
    await db.execute('''
      CREATE TABLE wishlist (
        id TEXT PRIMARY KEY, 
        title TEXT NOT NULL,
        company TEXT,
        location TEXT,
        salary TEXT,
        added_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 3. Tabel Jadwal Interview
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
  }

  // Hash password menggunakan SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); 
    return sha256.convert(bytes).toString();
  }

  // ========== USER AUTHENTICATION ==========

  // Register user baru
  Future<int> registerUser(String username, String password) async {
    final db = await database;
    
    // Cek apakah username sudah ada
    List<Map<String, dynamic>> existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Username sudah digunakan');
    }
    
    return await db.insert('users', {
      'username': username,
      'password': _hashPassword(password),
    });
  }

  // Login check
  Future<bool> loginUser(String username, String password) async {
    final db = await database;
    String hashedInput = _hashPassword(password);
    
    List<Map<String, dynamic>> res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedInput],
    );
    
    return res.isNotEmpty;
  }

  // Get user data (optional, untuk profil)
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    List<Map<String, dynamic>> res = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    
    return res.isNotEmpty ? res.first : null;
  }

  // ========== WISHLIST FUNCTIONS ==========

  Future<int> addToWishlist(Map<String, dynamic> job) async {
    final db = await database;
    return await db.insert(
      'wishlist', 
      job, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<List<Map<String, dynamic>>> getWishlist() async {
    final db = await database;
    return await db.query('wishlist', orderBy: 'added_at DESC');
  }

  Future<int> removeFromWishlist(String jobId) async {
    final db = await database;
    return await db.delete(
      'wishlist',
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  Future<bool> isInWishlist(String jobId) async {
    final db = await database;
    List<Map<String, dynamic>> res = await db.query(
      'wishlist',
      where: 'id = ?',
      whereArgs: [jobId],
    );
    return res.isNotEmpty;
  }

  // ========== INTERVIEW SCHEDULE FUNCTIONS ==========

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
    return await db.delete(
      'interviews',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== UTILITY FUNCTIONS ==========

  // Clear all data (untuk testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('wishlist');
    await db.delete('interviews');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}