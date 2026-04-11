import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // URL থেকে # সরানোর জন্য
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  usePathUrlStrategy(); // এটি হ্যাশ (#) রিমুভ করবে
  runApp(const EBMControlApp());
}

final _router = GoRouter(
  initialLocation: '/sp-login',
  routes: [
    GoRoute(
      path: '/sp-login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
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
