import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/job_provider.dart';
import 'providers/interview_provider.dart';
import 'data/services/notification_service.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_page.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService().init();
  await NotificationService().requestPermission();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isListenerSetup = false;
  
  // Untuk membatasi frekuensi event (kurangi spam)
  DateTime? _lastEventTime;
  static const Duration _minEventInterval = Duration(milliseconds: 200); // Tambah jadi 200ms

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _setupAccelerometerListener(ThemeProvider themeProvider) {
    if (_isListenerSetup) return;
    _isListenerSetup = true;
    
    _accelerometerSubscription?.cancel();
    
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        final now = DateTime.now();
        if (_lastEventTime != null && 
            now.difference(_lastEventTime!) < _minEventInterval) {
          return;
        }
        _lastEventTime = now;
        
        themeProvider.processAccelerometerEvent(event.x, event.y, event.z);
      },
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
    );
  }

  void _showThemeChangedSnackbar(ThemeMode newMode) {
    String message;
    IconData icon;
    Color backgroundColor;
    
    switch (newMode) {
      case ThemeMode.light:
        message = '☀️ Mode Terang Aktif';
        icon = Icons.light_mode;
        backgroundColor = Colors.amber.shade700;
        break;
      case ThemeMode.dark:
        message = '🌙 Mode Gelap Aktif';
        icon = Icons.dark_mode;
        backgroundColor = Colors.indigo.shade800;
        break;
      case ThemeMode.system:
        message = '📱 Mengikuti Sistem';
        icon = Icons.settings;
        backgroundColor = Colors.blue.shade700;
        break;
    }
    
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
            const Icon(Icons.vibration, color: Colors.white70, size: 16),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => InterviewProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setupAccelerometerListener(themeProvider);
          });
          
          themeProvider.onThemeToggledByShake = (newMode) {
            _showThemeChangedSnackbar(newMode);
          };
          
          return MaterialApp(
            title: 'Career Portal',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const LoginPage(),
            routes: {
              '/login': (context) => const LoginPage(),
              '/home': (context) => const MainNavigationPage(),
            },
          );
        },
      ),
    );
  }
}