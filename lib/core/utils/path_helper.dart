import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:ebficBM/core/services/storage_service.dart';
import 'package:path/path.dart' as p;

class PathHelper {
  /// Returns the workspace directory chosen by the user, or a fallback if not set.
  static Future<Directory> getWorkspaceDir(StorageService storage) async {
    final customPath = storage.dataPath;
    
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    // Fallback to application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final defaultDir = Directory(p.join(appDocDir.path, 'ebficBM_Data'));
    if (!await defaultDir.exists()) {
      await defaultDir.create(recursive: true);
    }
    return defaultDir;
  }

  /// Helper to get a file path within the workspace
  static Future<String> getFilePath(StorageService storage, String fileName) async {
    final workspace = await getWorkspaceDir(storage);
    return p.join(workspace.path, fileName);
  }
}
