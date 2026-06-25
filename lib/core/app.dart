import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/core/providers/theme_provider.dart';
import 'package:ebficbm/features/companies/providers/company_provider.dart';
import 'package:ebficbm/features/companies/providers/company_external_quota_provider.dart';
import 'package:ebficbm/features/companies/providers/company_stock_provider.dart';
import 'package:ebficbm/features/projects/providers/project_provider.dart';
import 'package:ebficbm/features/tasks/providers/task_provider.dart';
import 'package:ebficbm/features/assets/providers/asset_provider.dart';
import 'package:ebficbm/core/services/refresh_service.dart';
import 'package:ebficbm/core/services/storage_service.dart';
import 'package:ebficbm/features/onboarding/screens/onboarding_screen.dart';
import 'package:ebficbm/core/providers/auth_provider.dart';
import 'package:ebficbm/features/auth/presentation/login_screen.dart';
import 'package:ebficbm/features/auth/presentation/join_screen.dart';
import 'package:ebficbm/widgets/real_time_sync_wrapper.dart';
import 'package:ebficbm/features/chat/providers/chat_provider.dart';
import 'package:ebficbm/features/chat/data/chat_service.dart';

import 'package:ebficbm/widgets/custom_title_bar.dart';
import 'package:ebficbm/widgets/premium_loading_screen.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';

import 'package:ebficbm/core/providers/team_provider.dart';
import 'package:ebficbm/core/providers/td_set_provider.dart';

class BizOSApp extends StatelessWidget {
  const BizOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TdSetProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CompanyProvider>(
          create: (_) => CompanyProvider(),
          update: (_, auth, company) => company!..update(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CompanyExternalQuotaProvider>(
          create: (_) => CompanyExternalQuotaProvider(),
          update: (_, auth, quota) => quota!..update(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CompanyStockProvider>(
          create: (_) => CompanyStockProvider(),
          update: (_, auth, stock) => stock!..update(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProjectProvider>(
          create: (_) => ProjectProvider(),
          update: (_, auth, project) => project!..update(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, task) => task!..update(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AssetProvider>(
          create: (_) => AssetProvider(),
          update: (_, auth, asset) => asset!..update(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TeamProvider>(
          create: (_) => TeamProvider(),
          update: (_, auth, team) => team!..update(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) => ChatProvider(ChatService(Provider.of<AuthProvider>(context, listen: false).api)),
          update: (context, auth, chat) => chat!,
        ),
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
              child: Consumer3<ThemeProvider, StorageService, AuthProvider>(
                builder: (context, themeProvider, storageService, authProvider, child) {
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
                      child: Builder(
                        builder: (context) {
                          final bp = ResponsiveBreakpoints.of(context);
                          
                          final Widget mainContent = isDesktop 
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
                            : child!;

                          if (bp.isMobile) {
                            return ResponsiveScaledBox(
                              width: 450,
                              child: mainContent,
                            );
                          } else if (bp.isTablet) {
                            return ResponsiveScaledBox(
                              width: 800,
                              child: mainContent,
                            );
                          }

                          return mainContent;
                        },
                      ),
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
                    home: () {
                      if (kIsWeb) {
                        final fragment = Uri.base.fragment;
                        
                        // Handle SSO Callback
                        if (fragment.startsWith('/sso-callback')) {
                          final uri = Uri.parse('http://dummy$fragment');
                          final token = uri.queryParameters['token'];
                          if (token != null) {
                            // Perform auto-login with this token
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              authProvider.loginWithToken(token);
                            });
                          }
                        }

                        // Handle Join Invitation
                        if (fragment.contains('/join/')) {
                          final segments = fragment.split('/');
                          if (segments.isNotEmpty) {
                            final token = segments.last;
                            if (token.length >= 32) { // Tokens are typically 40 chars
                              return JoinScreen(invitationToken: token);
                            }
                          }
                        }
                      }

                      if (authProvider.isInitializing) {
                        return const PremiumLoadingScreen();
                      }

                      if (!storageService.isSetupComplete) {
                        return const OnboardingScreen();
                      }
                      
                      if (!authProvider.isLoggedIn) {
                        return const LoginScreen();
                      }

                      return GlobalRefreshWrapper(
                        child: RealTimeSyncWrapper(child: const HomeScreen())
                      );
                    }(),
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
