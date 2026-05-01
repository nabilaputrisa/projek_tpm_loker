import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dbHelper = DatabaseHelper();
  final LocalAuthentication auth = LocalAuthentication();

  // Menampilkan pesan singkat
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Logika Registrasi
  void _handleRegister() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Username dan Password tidak boleh kosong!");
      return;
    }
    try {
      await _dbHelper.registerUser(
        _usernameController.text,
        _passwordController.text,
      );
      _showSnackBar("Registrasi Berhasil! Silakan Login.");
    } catch (e) {
      _showSnackBar("Gagal: Username mungkin sudah digunakan.");
    }
  }

  // Logika Login Utama
  void _handleLogin() async {
    bool success = await _dbHelper.loginUser(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Untuk testing, kita anggap 2FA selalu aktif
      // Nanti di setting profile, ini bisa diubah jadi dinamis
      bool isTwoStepActive = prefs.getBool('two_step_auth') ?? true; 

      if (isTwoStepActive) {
        _showBiometricDialog();
      } else {
        _navigateToHome();
      }
    } else {
      _showSnackBar("Username atau Password Salah!");
    }
  }

  // Dialog Sidik Jari
  void _showBiometricDialog() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Silakan verifikasi sidik jari untuk masuk',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _navigateToHome();
      }
    } catch (e) {
      _showSnackBar("Error Biometrik: Pastikan sensor tersedia.");
    }
  }

  void _navigateToHome() {
    _showSnackBar("Login Berhasil! Selamat Datang.");
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Lingkaran
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.person_search,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Career Portal",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 40),
              
              // Input Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person, color: Colors.blue[700]),
                  labelText: "Username",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Input Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.blue[700]),
                  labelText: "Password",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Tombol Register
              TextButton(
                onPressed: _handleRegister,
                child: Text(
                  "Belum punya akun? Daftar di sini",
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}