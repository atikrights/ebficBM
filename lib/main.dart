import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ebficbm/core/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/core/services/storage_service.dart';
import 'package:ebficbm/core/providers/analysis_engine.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:ebficbm/core/config/app_config.dart';
import 'package:ebficbm/core/services/pusher_service.dart';
import 'package:ebficbm/core/providers/auth_provider.dart';
import 'package:ebficbm/core/providers/team_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safely initialize SharedPreferences to catch disk corruption
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences corrupted or failed: $e');
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        final directory = await getApplicationSupportDirectory();
        final file = File('${directory.path}/shared_preferences.json');
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted corrupted shared_preferences.json');
        }
        // Try again after deleting
        await SharedPreferences.getInstance();
      } catch (recoveryError) {
        debugPrint('Could not recover SharedPreferences: $recoveryError');
        SharedPreferences.setMockInitialValues({});
      }
    } else {
      SharedPreferences.setMockInitialValues({});
    }
  }

  // Initialize Global Configurations
  await AppConfig.instance.init();
  
  // Initialize Real-time Sync
  await PusherService().init();
  
  // Platform-specific Initialization for Desktop
  if (!kIsWeb && (
      defaultTargetPlatform == TargetPlatform.windows || 
      defaultTargetPlatform == TargetPlatform.linux || 
      defaultTargetPlatform == TargetPlatform.macOS
    )) {
      // Initialize window manager
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      // Bitsdojo Window Control
      doWhenWindowReady(() {
        final win = appWindow;
        win.minSize = const Size(800, 600);
        win.size = const Size(1280, 800);
        win.alignment = Alignment.center;
        win.show();
      });
    }

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storageService),
        ChangeNotifierProvider(create: (_) => AnalysisEngine()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const BizOSApp(),
    ),
  );
}
