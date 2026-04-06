import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bizos_x_pro/core/theme/colors.dart';
import 'package:bizos_x_pro/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:bizos_x_pro/core/providers/theme_provider.dart';
import 'package:bizos_x_pro/features/companies/providers/company_provider.dart';
import 'package:bizos_x_pro/features/projects/providers/project_provider.dart';
import 'package:bizos_x_pro/features/tasks/providers/task_provider.dart';
import 'package:bizos_x_pro/core/services/refresh_service.dart';

class BizOSApp extends StatelessWidget {
  const BizOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ebficBM',
            debugShowCheckedModeBanner: false,
            // REMOVED: ResponsiveBreakpoints.builder constraint
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              textTheme: GoogleFonts.outfitTextTheme(),
              scaffoldBackgroundColor: AppColors.lightBackground,
              cardColor: AppColors.lightSurface,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
              scaffoldBackgroundColor: AppColors.darkBackground,
              cardColor: AppColors.darkSurface,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.dark,
              ),
            ),
            home: const GlobalRefreshWrapper(child: HomeScreen()),
          );
        },
      ),
    );
  }
}
