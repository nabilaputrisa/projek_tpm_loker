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
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dbHelper = DatabaseHelper();
  final LocalAuthentication _auth = LocalAuthentication();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isRegisterMode = false; // Toggle antara Login dan Register

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Menampilkan pesan singkat
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Validasi input
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  // Logika Registrasi
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _dbHelper.registerUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      _showSnackBar("✓ Registrasi Berhasil! Silakan Login.");

      // Reset form dan switch ke mode login
      setState(() {
        _isRegisterMode = false;
        _passwordController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().contains('Username sudah digunakan')
            ? "Username sudah digunakan, pilih yang lain"
            : "Gagal registrasi: ${e.toString()}",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Logika Login Utama
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success = await _dbHelper.loginUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Simpan username ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'logged_username',
          _usernameController.text.trim(),
        );

        // Cek apakah 2FA aktif
        bool isTwoStepActive = prefs.getBool('two_step_auth') ?? false;

        if (isTwoStepActive) {
          await _showBiometricDialog();
        } else {
          _navigateToHome();
        }
      } else {
        _showSnackBar("Username atau Password Salah!", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Dialog Sidik Jari
  Future<void> _showBiometricDialog() async {
    try {
      // Cek apakah device support biometric
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        if (!mounted) return;
        _showSnackBar(
          "Perangkat tidak mendukung biometrik. Masuk tanpa verifikasi.",
          isError: true,
        );
        _navigateToHome();
        return;
      }

      bool authenticated = await _auth.authenticate(
        localizedReason: 'Verifikasi sidik jari untuk masuk',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        _navigateToHome();
      } else {
        _showSnackBar("Verifikasi biometrik gagal", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error biometrik: ${e.toString()}", isError: true);
      // Tetap arahkan ke home jika biometric error
      _navigateToHome();
    }
  }

  // Navigasi ke Home
  void _navigateToHome() {
    // TODO: Ganti dengan route home page Anda
    // Contoh: Navigator.pushReplacementNamed(context, '/home');

    _showSnackBar("✓ Login Berhasil! Selamat Datang.");

    // Sementara untuk testing, tampilkan dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Berhasil'),
        content: Text('Selamat datang, ${_usernameController.text}!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Lingkaran
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Title
                  Text(
                    _isRegisterMode ? "Buat Akun Baru" : "Career Portal",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegisterMode
                        ? "Daftar untuk memulai"
                        : "Temukan karir impianmu",
                    style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                  ),
                  const SizedBox(height: 40),

                  // Input Username
                  TextFormField(
                    controller: _usernameController,
                    validator: _validateUsername,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blue[700]),
                      labelText: "Username",
                      hintText: "Masukkan username",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.blue.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Password
                  TextFormField(
                    controller: _passwordController,
                    validator: _validatePassword,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Colors.blue[700]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.blue[700],
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      labelText: "Password",
                      hintText: "Masukkan password",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.blue.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Tombol Login/Register
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_isRegisterMode ? _handleRegister : _handleLogin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        disabledBackgroundColor: Colors.blue[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isRegisterMode ? "DAFTAR" : "LOGIN",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Login/Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegisterMode
                            ? "Sudah punya akun? "
                            : "Belum punya akun? ",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  _formKey.currentState?.reset();
                                });
                              },
                        child: Text(
                          _isRegisterMode ? "Login di sini" : "Daftar di sini",
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
