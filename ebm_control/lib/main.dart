import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const EBMControlApp());
}

// Router Configuration
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("ACCESS DENIED", style: TextStyle(color: Colors.red, letterSpacing: 5))),
      ),
    ),
    GoRoute(
      path: '/sp-login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);

class EBMControlApp extends StatelessWidget {
  const EBMControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EBM Control Center',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
