import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  // Cooldown setelah goyangan
  DateTime? _lastShakeTime;
  static const Duration _shakeCooldown = Duration(seconds: 2);
  
  static const double _shakeThreshold = 20;
  
  double _baseMagnitude = 1.0;
  bool _isCalibrated = false;
  int _calibrationSamples = 0;
  
  bool _isProcessingShake = false;
  
  double _lastStableMagnitude = 1.0;
  DateTime? _lastStableTime;
  static const Duration _stabilityDuration = Duration(milliseconds: 500);
  static const double _stabilityThreshold = 0.15;

  Function(ThemeMode)? onThemeToggledByShake;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode, {bool fromShake = false}) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
    
    if (fromShake && onThemeToggledByShake != null) {
      onThemeToggledByShake!(mode);
    }
  }

  void _calibrate(double magnitude) {
    if (!_isCalibrated && _calibrationSamples < 30) {
      _baseMagnitude = (_baseMagnitude * _calibrationSamples + magnitude) / (_calibrationSamples + 1);
      _calibrationSamples++;
      if (_calibrationSamples >= 30) {
        _isCalibrated = true;
        _lastStableMagnitude = _baseMagnitude;
        debugPrint('✅ Calibration complete. Base magnitude: $_baseMagnitude');
      }
    }
  }


  void processAccelerometerEvent(double x, double y, double z) {

    double magnitude = sqrt(x * x + y * y + z * z);
    
    if (!_isCalibrated) {
      _calibrate(magnitude);
      return;
    }
    

    double delta = (magnitude - _baseMagnitude).abs();
    
    bool isStable = delta < _stabilityThreshold;
    
    if (isStable) {
    
      _lastStableTime = DateTime.now();
      _lastStableMagnitude = magnitude;
    }
    
    bool isShaking = delta > _shakeThreshold;
    
    if (isShaking && _lastStableTime != null && !_isProcessingShake) {
      Duration timeSinceStable = DateTime.now().difference(_lastStableTime!);
      if (timeSinceStable > _stabilityDuration) {
        _onShakeDetected();
      }
    }
  }
  
  void _onShakeDetected() {
    final now = DateTime.now();
    if (_lastShakeTime != null && 
        now.difference(_lastShakeTime!) < _shakeCooldown) {
      debugPrint('Shake ignored (cooldown)');
      return;
    }
    
    debugPrint('✅ SHAKE DETECTED! Toggling theme...');
    _isProcessingShake = true;
    _lastShakeTime = now;
    
    // Toggle tema
    ThemeMode newMode;
    if (_themeMode == ThemeMode.light) {
      newMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      newMode = ThemeMode.light;
    } else {
      newMode = ThemeMode.dark;
    }
    
    setMode(newMode, fromShake: true);
    
    // Reset flag setelah cooldown
    Future.delayed(_shakeCooldown, () {
      _isProcessingShake = false;
    });
  }
}