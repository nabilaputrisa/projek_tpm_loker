// lib/providers/compass_provider.dart
//
// Mengelola stream magnetometer dari flutter_compass.
// Expose heading (derajat 0–360) sebagai ChangeNotifier.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CompassProvider extends ChangeNotifier {
  StreamSubscription<CompassEvent>? _subscription;

  double _heading = 0.0;
  bool _isAvailable = false;
  bool _isListening = false;

  double get heading => _heading;
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  /// Mulai mendengarkan sensor magnetometer.
  void startListening() {
    if (_isListening) return;

    final stream = FlutterCompass.events;
    if (stream == null) {
      _isAvailable = false;
      notifyListeners();
      return;
    }

    _isAvailable = true;
    _isListening = true;

    _subscription = stream.listen(
      (CompassEvent event) {
        final h = event.heading;
        if (h != null) {
          _heading = h;
          notifyListeners();
        }
      },
      onError: (_) {
        _isAvailable = false;
        _isListening = false;
        notifyListeners();
      },
    );

    notifyListeners();
  }

  /// Berhenti mendengarkan sensor (hemat baterai saat widget tidak terpakai).
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}