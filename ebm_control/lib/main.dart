import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const EBMControlApp());
}

class EBMControlApp extends StatelessWidget {
  const EBMControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EBM Control Center',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
