import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/job_provider.dart';
import 'providers/interview_provider.dart';
import 'data/services/notification_service.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService().init();
  await NotificationService().requestPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => InterviewProvider()),
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
        home: const LoginPage(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const MainNavigationPage(),
        },
      ),
    );
  }
}