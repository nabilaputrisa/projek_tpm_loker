import 'package:flutter/material.dart';
import 'views/auth/login_page.dart'; // Import halaman login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Projek TPM Loker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(), // Halaman pertama yang muncul
    );
  }
}