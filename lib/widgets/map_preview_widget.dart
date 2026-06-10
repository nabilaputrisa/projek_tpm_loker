import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../data/services/location_service.dart';
import 'compass_pointer.dart';

class DistanceHelper {
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371;
    final double lat1 = point1.latitude * math.pi / 180;
    final double lat2 = point2.latitude * math.pi / 180;
    final double deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;
    
    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
  
  static String formatDistance(double km) {
    if (km < 0.1) return '${(km * 1000).toStringAsFixed(0)} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.toStringAsFixed(0)} km';
  }
}

class _HeadingSmoother {
  final int windowSize;
  final List<double> _samples = [];
  _HeadingSmoother({this.windowSize = 5});
  
  double add(double heading) {
    _samples.add(heading);
    if (_samples.length > windowSize) _samples.removeAt(0);
    return _average();
  }
  
  double _average() {
    double sinSum = 0, cosSum = 0;
    for (final h in _samples) {
      final rad = h * (math.pi / 180);
      sinSum += math.sin(rad);
      cosSum += math.cos(rad);
    }
    final avg = math.atan2(sinSum / _samples.length, cosSum / _samples.length);
    return (avg * (180 / math.pi) + 360) % 360;
  }
}


class MapPreviewWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final String title;
  const MapPreviewWidget({
    super.key, 
    required this.lat, 
    required this.lng, 
    required this.title
  });

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  
  // Compass
  double _heading = 0.0;
  bool _compassAvailable = false;
  StreamSubscription<CompassEvent>? _compassSub;
  final _smoother = _HeadingSmoother(windowSize: 5);
  
  // GPS
  bool _isLocating = false;
  LatLng? _userLatLng;
  StreamSubscription<Position>? _positionStream;
  
  // Mode
  bool _compassMode = false;
  
  // Zoom level
  double _currentZoom = 15;
  
  // Polyline (garis penghubung)
  Set<Polyline> _polylines = {};
  
  // Flag untuk menghindari update infinite loop
  bool _isUpdatingFromUser = false;
  
  static const String _mapStyle = '''
  [{"featureType":"all","elementType":"labels.text.fill","stylers":[{"color":"#4a5568"}]},
   {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c8e6f5"}]},
   {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f0f4f8"}]},
   {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
   {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#e8f4ea"}]}]
  ''';

  @override
  void initState() {
    super.initState();
    _startCompass();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startCompass() {
    final stream = FlutterCompass.events;
    if (stream == null) return;
    
    setState(() => _compassAvailable = true);
    
    _compassSub = stream.listen((CompassEvent event) {
      final h = event.heading;
      if (h != null && mounted) {
        final smoothed = _smoother.add(h);
        setState(() => _heading = smoothed);
        
        if (_compassMode && !_isUpdatingFromUser && _mapController != null && _userLatLng != null) {
          _updateMapRotation(smoothed);
        }
      }
    });
  }

  void _startLocationTracking() {
    _positionStream = _locationService.positionStream.listen((Position pos) {
      if (!mounted) return;
      
      final newLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLatLng = newLatLng;
        _updatePolyline();
      });
      
      if (!_isUpdatingFromUser && _mapController != null && _userLatLng != null) {
        _updateMapPosition(newLatLng);
      }
    });
  }

  void _updatePolyline() {
    if (_userLatLng == null) return;
    
    final officeLatLng = LatLng(widget.lat, widget.lng);
    
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('distance_line'),
          points: [_userLatLng!, officeLatLng],
          color: Colors.blue.withOpacity(0.7),
          width: 2,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          geodesic: true,
        ),
      };
    });
  }

  void _updateMapPosition(LatLng position) {
    if (_mapController == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: _currentZoom,
          bearing: _compassMode ? _heading : 0,
        ),
      ),
    );
  }

  void _updateMapRotation(double heading) {
    if (_mapController == null || _userLatLng == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _userLatLng!,
          zoom: _currentZoom,
          bearing: heading,
        ),
      ),
    );
  }

  void _toggleCompassMode() {
    setState(() => _compassMode = !_compassMode);
    
    if (_compassMode && _mapController != null && _userLatLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLatLng!,
            zoom: _currentZoom,
            bearing: _heading,
          ),
        ),
      );
    } else if (_mapController != null && _userLatLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLatLng!,
            zoom: _currentZoom,
            bearing: 0,
          ),
        ),
      );
    }
  }


  void _zoomToCountryLevel() {
    if (_mapController == null) return;
    _currentZoom = 5;
    _mapController!.animateCamera(CameraUpdate.zoomTo(5));
    setState(() {});
  }

  Future<void> _goToMyLocation() async {
    final cs = Theme.of(context).colorScheme;
    if (_isLocating) return;
    setState(() => _isLocating = true);
    
    try {
      final Position pos = await _locationService.getCurrentPosition();
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLatLng = userLatLng;
        _updatePolyline();
      });
      
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userLatLng,
            zoom: 17,
            bearing: _compassMode ? _heading : 0,
          ),
        ),
      );
    } on LocationException catch (e) {
      _showSnackBar(e.message, cs, isError: true);
    } catch (e) {
      _showSnackBar('Gagal mendapatkan lokasi', cs, isError: true);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }
  
  void _goToOffice() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(widget.lat, widget.lng),
          zoom: 15,
          bearing: 0,
        ),
      ),
    );
    setState(() => _compassMode = false);
  }

  void _showSnackBar(String message, ColorScheme cs, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Set<Marker> get _markers {
    final officeLatLng = LatLng(widget.lat, widget.lng);
    
    return {
      Marker(
        markerId: const MarkerId('office'),
        position: officeLatLng,
        infoWindow: InfoWindow(title: widget.title, snippet: 'Lokasi Kantor'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      if (_userLatLng != null)
        Marker(
          markerId: const MarkerId('user'),
          position: _userLatLng!,
          infoWindow: const InfoWindow(title: 'Posisi Saya'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          rotation: _compassMode ? _heading : 0,
          flat: true,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 320,
      child: Stack(
        children: [

          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.lat, widget.lng),
              zoom: 15,
              bearing: 0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            gestureRecognizers: Set()
              ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
              ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()))
              ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
              ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer())),
            onMapCreated: (GoogleMapController ctrl) {
              _mapController = ctrl;
              ctrl.setMapStyle(_mapStyle);
            },
            onCameraMoveStarted: () {
              _isUpdatingFromUser = true;
            },
            onCameraIdle: () {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted && _compassMode) {
                  _isUpdatingFromUser = false;
                } else if (mounted) {
                  _isUpdatingFromUser = false;
                }
              });
            },
            onCameraMove: (CameraPosition pos) {
              _currentZoom = pos.zoom;
            },
          ),
          

          if (_compassAvailable)
            Positioned(
              top: 12,
              left: 12,
              child: _CompassBadge(
                heading: _heading,
                colorScheme: cs,
                isActive: _compassMode,
                onTap: _toggleCompassMode,
              ),
            ),
          

          Positioned(
            top: 12,
            right: 12,
            child: _ResetButton(
              onTap: _goToOffice,
              colorScheme: cs,
            ),
          ),
          

          Positioned(
            bottom: 12,
            right: 12,
            child: _MyLocationButton(
              isLoading: _isLocating,
              onTap: _goToMyLocation,
              colorScheme: cs,
            ),
          ),
          

          Positioned(
            bottom: 12,
            left: 12,
            child: _ZoomToCountryButton(
              onTap: _zoomToCountryLevel,
              colorScheme: cs,
            ),
          ),
          

          if (_compassMode && _compassAvailable)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation, color: cs.onPrimary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Compass ON',
                        style: TextStyle(color: cs.onPrimary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          

          if (!_compassAvailable)
            Positioned(
              top: 12,
              left: 12,
              child: _SensorUnavailableBadge(colorScheme: cs),
            ),
        ],
      ),
    );
  }
}


class _CompassBadge extends StatelessWidget {
  final double heading;
  final ColorScheme colorScheme;
  final bool isActive;
  final VoidCallback onTap;

  const _CompassBadge({
    required this.heading,
    required this.colorScheme,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          border: isActive ? Border.all(color: colorScheme.primary, width: 2) : null,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CompassPointer(heading: heading, size: 32),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_headingLabel(heading), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Text('${heading.toStringAsFixed(0)}°', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          ]),
        ]),
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


class _ZoomToCountryButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ZoomToCountryButton({
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: 'Zoom ke level negara',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Icon(Icons.public, size: 22, color: colorScheme.primary),
        ),
      ),
    );
  }
}


class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  const _ResetButton({required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Icon(Icons.business_center, size: 20, color: colorScheme.primary),
      ),
    );
  }
}


class _MyLocationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  const _MyLocationButton({required this.isLoading, required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: isLoading 
          ? Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary))
          : Icon(Icons.my_location, color: colorScheme.primary, size: 22),
      ),
    );
  }
}


class _SensorUnavailableBadge extends StatelessWidget {
  final ColorScheme colorScheme;
  const _SensorUnavailableBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.90),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sensors_off, size: 14, color: colorScheme.outlineVariant),
        const SizedBox(width: 5),
        Text('Kompas tidak tersedia', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}