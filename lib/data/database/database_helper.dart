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
        username TEXT UNIQUE,
        password TEXT
      )
    ''');

    // 2. Tabel Wishlist untuk simpan lowongan
    await db.execute('''
      CREATE TABLE wishlist (
        id TEXT PRIMARY KEY, 
        title TEXT,
        company TEXT,
        location TEXT,
        salary TEXT
      )
    ''');

    // 3. Tabel Jadwal Interview
    await db.execute('''
      CREATE TABLE interviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_title TEXT,
        company_name TEXT,
        interview_time TEXT,
        location_coords TEXT
      )
    ''');
  }

  // Hash password menggunakan SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); 
    return sha256.convert(bytes).toString();
  }

  // Register user baru
  Future<int> registerUser(String username, String password) async {
    final db = await database;
    return await db.insert('users', {
      'username': username,
      'password': _hashPassword(password), // Simpan hasil hash
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

  // FUNGSI UNTUK WISHLIST 

  Future<int> addToWishlist(Map<String, dynamic> job) async {
    final db = await database;
    return await db.insert('wishlist', job, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getWishlist() async {
    final db = await database;
    return await db.query('wishlist');
  }

  // FUNGSI UNTUK JADWAL

  Future<int> addInterview(Map<String, dynamic> interview) async {
    final db = await database;
    return await db.insert('interviews', interview);
  }
}