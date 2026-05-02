import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';

class MapPreviewWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final String title;

  const MapPreviewWidget({super.key, required this.lat, required this.lng, required this.title});

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  // ignore: unused_field
  GoogleMapController? _controller;
  double _heading = 0;
  StreamSubscription? _compassSub;

  @override
  void initState() {
    super.initState();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => _heading = event.heading ?? 0);
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.lightBlue.shade100, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(widget.lat, widget.lng), zoom: 15),
            myLocationEnabled: true, // LBS aktif
            myLocationButtonEnabled: true,
            onMapCreated: (ctrl) => _controller = ctrl,
            markers: {
              Marker(markerId: const MarkerId("office"), position: LatLng(widget.lat, widget.lng), infoWindow: InfoWindow(title: widget.title))
            },
          ),
          // Indikator Kompas (Magnetometer)
          Positioned(
            top: 10,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Transform.rotate(
                angle: (_heading * (3.14159 / 180) * -1),
                child: const Icon(Icons.explore, color: Colors.lightBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}