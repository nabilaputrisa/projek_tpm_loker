import 'package:geolocator/geolocator.dart';

class LocationService {

// Mendapatkan posisi saat ini dengan pengecekan izin dan layanan lokasi
  Future<Position> getCurrentPosition() async {
    // 1. Cek apakah layanan lokasi aktif
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

// Stream posisi untuk update real-time 
  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, 
        ),
      );
}

/// Exception khusus untuk error lokasi agar mudah ditangkap di UI
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}