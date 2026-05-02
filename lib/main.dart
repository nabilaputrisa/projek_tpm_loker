import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/job_provider.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Inisialisasi notifikasi, timezone, dll
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JobProvider()),
        // TODO: Tambah provider lain (ThemeProvider, CompassProvider, dll)
      ],
      child: MaterialApp(
        title: 'Career Portal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5E35B1),
            primary: const Color(0xFF5E35B1),
            secondary: const Color(0xFF7E57C2),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF5E35B1),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        // Untuk testing, langsung ke HomePage
        // Nanti ganti ke LoginPage setelah siap
        home: const MainNavigationPage(), // ← ganti dari HomePage
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const MainNavigationPage(), // ← ganti dari HomePage
        },
      ),
    );
  }
}