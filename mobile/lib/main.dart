import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  runApp(const SafePickApp());
}

class SafePickApp extends StatelessWidget {
  const SafePickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
