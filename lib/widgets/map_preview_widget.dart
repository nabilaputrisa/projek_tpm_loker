// lib/widgets/map_preview_widget.dart
//
// Mini map di halaman detail lowongan.
// Fitur:
//   • Marker lokasi kantor
//   • Tombol "Lokasi Saya" → GPS fokus ke posisi user
//   • CompassPointer overlay → panah berputar real-time (Magnetometer)
//   • Snackbar informatif saat error GPS / sensor tidak tersedia
//
// PERUBAHAN (FIX BUG 3):
//   Ditambahkan _HeadingSmoother untuk meredam jitter sensor magnetometer.
//   Raw sensor noise menyebabkan panah bergetar tiap frame. Moving average
//   5 sampel menghaluskan pergerakan tanpa menambah lag yang terasa.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../data/services/location_service.dart';
import 'compass_pointer.dart';

// ════════════════════════════════════════════════════════════════════════════
// HEADING SMOOTHER (FIX BUG 3)
// ════════════════════════════════════════════════════════════════════════════

/// Moving average sederhana untuk heading kompas.
///
/// Masalah: Raw magnetometer sangat noisy → panah bergetar terus.
/// Solusi: Rata-ratakan N sampel terakhir. Dengan [windowSize] = 5
/// getaran halus teredam tanpa lag yang terasa oleh pengguna.
///
/// Catatan khusus heading: rata-rata circular (bukan aritmatika biasa)
/// dipakai agar transisi 359°→1° tidak menghasilkan 180° (Selatan).
class _HeadingSmoother {
  final int windowSize;
  final List<double> _samples = [];

  _HeadingSmoother({this.windowSize = 5});

  /// Tambahkan sampel baru dan kembalikan heading yang sudah dihaluskan.
  double add(double heading) {
    _samples.add(heading);
    if (_samples.length > windowSize) _samples.removeAt(0);
    return _average();
  }

  /// Circular mean: konversi ke vektor unit, rata-ratakan, konversi balik.
  double _average() {
    double sinSum = 0;
    double cosSum = 0;
    for (final h in _samples) {
      final rad = h * (math.pi / 180);
      sinSum += math.sin(rad);
      cosSum += math.cos(rad);
    }
    final avg = math.atan2(sinSum / _samples.length, cosSum / _samples.length);
    final degrees = avg * (180 / math.pi);
    return (degrees + 360) % 360; // normalisasi ke 0–360
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MAP PREVIEW WIDGET
// ════════════════════════════════════════════════════════════════════════════

class MapPreviewWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final String title;

  const MapPreviewWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.title,
  });

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  // ── Controllers ────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  // ── State ──────────────────────────────────────────────────────────────────
  double _heading = 0.0;
  bool _compassAvailable = false;
  bool _isLocating = false;
  LatLng? _userLatLng;

  // ── Subscriptions ──────────────────────────────────────────────────────────
  StreamSubscription<CompassEvent>? _compassSub;

  // FIX BUG 3: Smoother untuk meredam jitter sensor.
  final _smoother = _HeadingSmoother(windowSize: 5);

  // ── Map style: subtle gray ─────────────────────────────────────────────────
  static const String _mapStyle = '''
  [
    {"featureType":"all","elementType":"labels.text.fill",
     "stylers":[{"color":"#4a5568"}]},
    {"featureType":"water","elementType":"geometry",
     "stylers":[{"color":"#c8e6f5"}]},
    {"featureType":"landscape","elementType":"geometry",
     "stylers":[{"color":"#f0f4f8"}]},
    {"featureType":"road","elementType":"geometry",
     "stylers":[{"color":"#ffffff"}]},
    {"featureType":"road","elementType":"geometry.stroke",
     "stylers":[{"color":"#d1d9e0"}]},
    {"featureType":"poi","elementType":"geometry",
     "stylers":[{"color":"#e8f4ea"}]}
  ]
  ''';

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _startCompass();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPASS
  // ══════════════════════════════════════════════════════════════════════════

  void _startCompass() {
    final stream = FlutterCompass.events;
    if (stream == null) return;

    setState(() => _compassAvailable = true);

    _compassSub = stream.listen((CompassEvent event) {
      final h = event.heading;
      if (h != null && mounted) {
        // FIX BUG 3: Gunakan smoothed heading, bukan raw.
        // Tanpa ini: setState dipanggil setiap event mentah → panah jitter.
        final smoothed = _smoother.add(h);
        setState(() => _heading = smoothed);
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GPS – "Lokasi Saya"
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _goToMyLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final Position pos = await _locationService.getCurrentPosition();
      final userLatLng = LatLng(pos.latitude, pos.longitude);

      setState(() => _userLatLng = userLatLng);

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: userLatLng, zoom: 15),
        ),
      );
    } on LocationException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Gagal mendapatkan lokasi. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF2D6A9F),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MARKERS
  // ══════════════════════════════════════════════════════════════════════════

  Set<Marker> get _markers {
    final officeLatLng = LatLng(widget.lat, widget.lng);

    return {
      Marker(
        markerId: const MarkerId('office'),
        position: officeLatLng,
        infoWindow: InfoWindow(
          title: widget.title,
          snippet: 'Lokasi Kantor',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      if (_userLatLng != null)
        Marker(
          markerId: const MarkerId('user'),
          position: _userLatLng!,
          infoWindow: const InfoWindow(title: 'Posisi Saya'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final officeLatLng = LatLng(widget.lat, widget.lng);

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: officeLatLng,
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController ctrl) {
              _mapController = ctrl;
              ctrl.setMapStyle(_mapStyle);
            },
          ),
          if (_compassAvailable)
            Positioned(
              top: 12,
              left: 12,
              child: _CompassBadge(heading: _heading),
            ),
          Positioned(
            bottom: 12,
            right: 12,
            child: _MyLocationButton(
              isLoading: _isLocating,
              onTap: _goToMyLocation,
            ),
          ),
          if (!_compassAvailable)
            Positioned(
              top: 12,
              left: 12,
              child: _SensorUnavailableBadge(),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS (tidak berubah dari versi asli)
// ════════════════════════════════════════════════════════════════════════════

class _CompassBadge extends StatelessWidget {
  final double heading;

  const _CompassBadge({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CompassPointer(heading: heading, size: 32),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _headingLabel(heading),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3C5E),
                ),
              ),
              Text(
                '${heading.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7A8D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _headingLabel(double h) {
    if (h < 22.5 || h >= 337.5) return 'Utara';
    if (h < 67.5) return 'Timur Laut';
    if (h < 112.5) return 'Timur';
    if (h < 157.5) return 'Tenggara';
    if (h < 202.5) return 'Selatan';
    if (h < 247.5) return 'Barat Daya';
    if (h < 292.5) return 'Barat';
    return 'Barat Laut';
  }
}

class _MyLocationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _MyLocationButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF2D6A9F),
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF2D6A9F),
                size: 24,
              ),
      ),
    );
  }
}

class _SensorUnavailableBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.sensors_off, size: 14, color: Color(0xFF9E9E9E)),
          SizedBox(width: 5),
          Text(
            'Kompas tidak tersedia',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7A8D)),
          ),
        ],
      ),
    );
  }
}