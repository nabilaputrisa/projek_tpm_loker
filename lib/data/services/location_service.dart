// lib/data/services/location_service.dart
//
// Mengelola permintaan izin GPS dan pengambilan posisi user saat ini.
// Dependensi: geolocator

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Minta izin lokasi jika belum diberikan, lalu kembalikan posisi saat ini.
  /// Melempar [LocationException] jika izin ditolak atau layanan nonaktif.
  Future<Position> getCurrentPosition() async {
    // 1. Cek apakah layanan lokasi aktif di perangkat
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Layanan lokasi nonaktif. Aktifkan GPS di pengaturan perangkat.',
      );
    }

    // 2. Cek & minta izin
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Izin lokasi ditolak. Aplikasi tidak dapat mengakses GPS.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Izin lokasi ditolak secara permanen. '
        'Buka Pengaturan > Aplikasi untuk mengaktifkannya.',
      );
    }

    // 3. Ambil posisi dengan akurasi tinggi
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Stream posisi real-time (opsional, untuk tracking).
  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // update tiap 10 meter
        ),
      );
}

/// Exception khusus untuk error lokasi agar mudah ditangkap di UI.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}