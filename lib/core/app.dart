import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ebficBM/core/theme/colors.dart';
import 'package:ebficBM/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:ebficBM/core/providers/theme_provider.dart';
import 'package:ebficBM/features/companies/providers/company_provider.dart';
import 'package:ebficBM/features/projects/providers/project_provider.dart';
import 'package:ebficBM/features/tasks/providers/task_provider.dart';
import 'package:ebficBM/core/services/refresh_service.dart';
import 'package:ebficBM/core/services/storage_service.dart';
import 'package:ebficBM/features/onboarding/screens/onboarding_screen.dart';

import 'package:ebficBM/widgets/custom_title_bar.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:ebficBM/core/services/refresh_service.dart';

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
      child: Builder(
        builder: (context) {
          return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const RefreshIntent(),
              LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR): const RefreshIntent(),
              LogicalKeySet(LogicalKeyboardKey.f5): const RefreshIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                RefreshIntent: RefreshAction(context: context),
              },
              child: Consumer2<ThemeProvider, StorageService>(
                builder: (context, themeProvider, storageService, child) {
                  final bool isDark = themeProvider.themeMode == ThemeMode.dark;
                  
                  final bool isDesktop = !kIsWeb && (
                    defaultTargetPlatform == TargetPlatform.windows || 
                    defaultTargetPlatform == TargetPlatform.linux || 
                    defaultTargetPlatform == TargetPlatform.macOS
                  );

                  return MaterialApp(
                    title: 'ebficBM',
                    debugShowCheckedModeBanner: false,
                    builder: (context, child) => ResponsiveBreakpoints.builder(
                      child: isDesktop 
                        ? Material(
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 33),
                                  child: ClipRect(child: child!),
                                ),
                                Positioned(
                                  top: 0, left: 0, right: 0,
                                  child: CustomTitleBar(isDark: isDark),
                                ),
                              ],
                            ),
                          )
                        : child!,
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
                      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
                    ),
                    darkTheme: ThemeData(
                      useMaterial3: true,
                      brightness: Brightness.dark,
                      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
                      scaffoldBackgroundColor: AppColors.darkBackground,
                      cardColor: AppColors.darkSurface,
                      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
                    ),
                    home: storageService.isSetupComplete 
                        ? const GlobalRefreshWrapper(child: HomeScreen())
                        : const OnboardingScreen(),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
