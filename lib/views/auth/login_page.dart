import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:projektpm/views/auth/biometric_helper.dart';
import 'package:projektpm/views/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';
//import '../auth/biometric_helper.dart'; // Import BiometricHelper

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

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isRegisterMode = false; // Toggle antara Login dan Register

  // Variabel untuk biometric
  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  String? _biometricType;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadBiometricPreference();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Cek support biometric
  Future<void> _checkBiometricSupport() async {
    _biometricSupported = await BiometricHelper.isBiometricSupported();

    if (_biometricSupported) {
      final biometrics = await BiometricHelper.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.fingerprint)) {
        _biometricType = "Sidik Jari";
      } else if (biometrics.contains(BiometricType.face)) {
        _biometricType = "Wajah";
      } else if (biometrics.contains(BiometricType.iris)) {
        _biometricType = "Iris";
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  // Load preferensi biometric dari SharedPreferences
  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    if (mounted) {
      setState(() {});
    }
  }

  // Simpan preferensi biometric
  Future<void> _saveBiometricPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    _biometricEnabled = enabled;
    if (mounted) {
      setState(() {});
    }
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

  // Login dengan biometric (tanpa password)
  Future<void> _loginWithBiometric() async {
    if (!_biometricSupported) {
      _showSnackBar("Perangkat tidak mendukung biometrik", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Autentikasi biometric
      final isAuthenticated = await BiometricHelper.authenticate();

      if (!mounted) return;

      if (isAuthenticated) {
        // Coba ambil username terakhir yang login
        final prefs = await SharedPreferences.getInstance();
        final lastUsername = prefs.getString('last_username');

        if (lastUsername != null) {
          // Login dengan username terakhir
          _usernameController.text = lastUsername;
          await _handleLoginWithBiometric(lastUsername);
        } else {
          _showSnackBar(
            "Belum ada riwayat login. Silakan login dengan password terlebih dahulu.",
            isError: true,
          );
        }
      } else {
        _showSnackBar("Verifikasi biometrik gagal", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error biometrik: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handle login dengan biometric
  Future<void> _handleLoginWithBiometric(String username) async {
    try {
      // Ambil data user dari database
      final userData = await _dbHelper.getUserByUsername(username);

      if (userData != null) {
        // Simpan username ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_username', username);

        _navigateToHome();
      } else {
        _showSnackBar("User tidak ditemukan", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", isError: true);
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

        // Simpan username terakhir untuk biometric
        await prefs.setString('last_username', _usernameController.text.trim());

        // Cek apakah user ingin menggunakan biometric untuk login berikutnya
        if (_biometricSupported && _biometricEnabled == false) {
          await _showBiometricSetupDialog();
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

  // Dialog setup biometric setelah login berhasil
  Future<void> _showBiometricSetupDialog() async {
    if (!mounted) return;

    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Aktifkan Login Biometrik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kamu bisa login lebih cepat dengan biometrik untuk下一次.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _biometricType == "Sidik Jari"
                      ? Icons.fingerprint
                      : Icons.face,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gunakan ${_biometricType ?? "Biometrik"} untuk login',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );

    if (shouldEnable == true) {
      // Verifikasi biometric sekali lagi untuk konfirmasi
      final isAuthenticated = await BiometricHelper.authenticate();
      if (isAuthenticated) {
        await _saveBiometricPreference(true);
        _showSnackBar("✓ Login biometrik berhasil diaktifkan", isError: false);
      } else {
        _showSnackBar(
          "Verifikasi gagal, biometrik tidak diaktifkan",
          isError: true,
        );
      }
    }

    _navigateToHome();
  }

  // Dialog Verifikasi Biometric saat login
  Future<void> _showBiometricVerificationDialog() async {
    if (!_biometricSupported) {
      _showSnackBar("Perangkat tidak mendukung biometrik", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isAuthenticated = await BiometricHelper.authenticate();

      if (!mounted) return;

      if (isAuthenticated) {
        // Ambil username terakhir
        final prefs = await SharedPreferences.getInstance();
        final lastUsername = prefs.getString('last_username');

        if (lastUsername != null) {
          _usernameController.text = lastUsername;
          await _handleLoginWithBiometric(lastUsername);
        } else {
          _showSnackBar(
            "Silakan login dengan password terlebih dahulu",
            isError: true,
          );
        }
      } else {
        _showSnackBar("Verifikasi biometrik gagal", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error biometrik: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Navigasi ke Home
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationPage()),
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

                  // Form hanya ditampilkan jika tidak menggunakan biometric
                  if (!_isRegisterMode && _biometricEnabled) ...[
                    // Tombol Login dengan Biometric
                    SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: _isLoading
                              ? null
                              : _showBiometricVerificationDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _biometricType == "Sidik Jari"
                                    ? Icons.fingerprint
                                    : Icons.face,
                                size: 50,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Login dengan ${_biometricType ?? "Biometrik"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tekan untuk verifikasi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'atau login dengan password',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400])),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Input Username (sembunyikan jika biometric enabled)
                  if (!_isRegisterMode && _biometricEnabled) ...[
                    // Jika biometric enabled, tampilkan username yang tersimpan
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Username',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                FutureBuilder<String?>(
                                  future: _getLastUsername(),
                                  builder: (context, snapshot) {
                                    final username = snapshot.data ?? '';
                                    return Text(
                                      username,
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () async {
                              await _saveBiometricPreference(false);
                              setState(() {});
                            },
                            tooltip: 'Ganti akun',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Tampilkan form login biasa
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
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
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
                  ],

                  const SizedBox(height: 30),

                  // Tombol Login/Register
                  if (!(_isRegisterMode == false &&
                      _biometricEnabled == true)) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_isRegisterMode
                                  ? _handleRegister
                                  : _handleLogin),
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
                  ],

                  const SizedBox(height: 16),

                  // Tombol Biometric (jika support dan tidak dalam mode biometric)
                  if (!_isRegisterMode &&
                      _biometricSupported &&
                      !_biometricEnabled) ...[
                    TextButton.icon(
                      onPressed: _loginWithBiometric,
                      icon: Icon(
                        _biometricType == "Sidik Jari"
                            ? Icons.fingerprint
                            : Icons.face,
                        color: Colors.blue[700],
                      ),
                      label: Text(
                        'Login dengan ${_biometricType ?? "Biometrik"}',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

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

  // Helper untuk mendapatkan username terakhir
  Future<String?> _getLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_username');
  }
}
