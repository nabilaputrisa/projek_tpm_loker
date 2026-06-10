import 'package:local_auth/local_auth.dart';

class BiometricHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Cek apakah perangkat support biometric
  static Future<bool> isBiometricSupported() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();

      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  // Ambil jenis biometric yang tersedia
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Proses autentikasi biometric
  static Future<bool> authenticate() async {
    try {
      final bool isAuthenticated = await _auth.authenticate(
        localizedReason: 'Verifikasi identitas untuk masuk',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }
}
