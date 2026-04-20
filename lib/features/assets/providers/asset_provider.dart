import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import '../models/asset_model.dart';

// ---------------------------------------------------------------------------
// Image compression helper (runs in isolate to keep UI smooth)
// Only available on non-web platforms. On web, we skip compression.
// ---------------------------------------------------------------------------
Future<_CompressResult?> _compressInBackground(_CompressInput input) async {
  try {
    // We use dart:io Uint8List + manual JPEG-quality approach via flutter_image_compress.
    // Since flutter_image_compress may not be installed, we provide a safe fallback:
    // just copy the file and generate a tiny thumbnail by reading raw bytes.
    // If flutter_image_compress IS installed, swap the body below.
    final srcFile = File(input.sourcePath);
    if (!srcFile.existsSync()) return null;

    // -- Thumbnail: copy + resize would go here with flutter_image_compress --
    // For now we copy the file as-is (safe no-dependency implementation).
    // When flutter_image_compress is added, replace with:
    //   final result = await FlutterImageCompress.compressAndGetFile(...);
    await srcFile.copy(input.outputPath);

    // Thumbnail = same file for now (replace with compressed 200×200 version)
    await srcFile.copy(input.thumbPath);

    return _CompressResult(
      compressedPath: input.outputPath,
      thumbPath: input.thumbPath,
      newSizeBytes: srcFile.lengthSync(),
    );
  } catch (e) {
    return null;
  }
}

class _CompressInput {
  final String sourcePath;
  final String outputPath;
  final String thumbPath;
  const _CompressInput({
    required this.sourcePath,
    required this.outputPath,
    required this.thumbPath,
  });
}

class _CompressResult {
  final String compressedPath;
  final String thumbPath;
  final int newSizeBytes;
  const _CompressResult({
    required this.compressedPath,
    required this.thumbPath,
    required this.newSizeBytes,
  });
}

// ---------------------------------------------------------------------------

class AssetProvider extends ChangeNotifier {
  final List<AssetModel> _assets = [];
  bool _isLoading = true;

  // ── Pagination
  static const int _pageSize = 30;
  int _loadedCount = _pageSize;

  // ── Folders
  final List<AssetFolderModel> _folders = [];
  bool _isUploading = false;
  String? _uploadStatus;

  List<AssetFolderModel> get folders => List.unmodifiable(_folders);

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get uploadStatus => _uploadStatus;

  /// Full master list
  List<AssetModel> get allAssets => List.unmodifiable(_assets);

  /// Only assets that are not in the Drafts/Trash
  List<AssetModel> get activeAssets => _assets.where((a) => !a.isDeleted).toList();

  /// Assets moved to Drafts/Trash
  List<AssetModel> get draftAssets => _assets.where((a) => a.isDeleted).toList();

  /// Visible assets respecting current page window.
  List<AssetModel> pagedAssets(List<AssetModel> filtered) {
    if (filtered.length <= _loadedCount) return filtered;
    return filtered.take(_loadedCount).toList();
  }

  bool hasMore(List<AssetModel> filtered) => filtered.length > _loadedCount;

  void loadMore() {
    _loadedCount += _pageSize;
    notifyListeners();
  }

  AssetProvider() {
    _loadFromStorage();
  }

  // ── Storage ──────────────────────────────────────────────────────────────

  Future<void> _loadFromStorage() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Assets
      final assetData = prefs.getString('ebm_assets');
      if (assetData != null) {
        final List<AssetModel> loaded = await compute(_decodeAssets, assetData);
        _assets.clear();
        _assets.addAll(loaded);
      }

      // Load Folders
      final folderData = prefs.getString('ebm_asset_folders');
      if (folderData != null) {
        final List<AssetFolderModel> loadedF = await compute(_decodeFolders, folderData);
        _folders.clear();
        _folders.addAll(loadedF);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading assets: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String encodedA = await compute(_encodeAssets, _assets);
      await prefs.setString('ebm_assets', encodedA);

      final String encodedF = await compute(_encodeFolders, _folders);
      await prefs.setString('ebm_asset_folders', encodedF);
    } catch (e) {
      if (kDebugMode) print('Error saving assets: $e');
    }
  }

  // ── Central Sync Hook ───────────────────────────────────────────────────

  /// Use this to automatically store any manually uploaded file into the library.
  Future<String?> syncFileToLibrary(String path, {String? name, String? folderId}) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;

      final ext = path.split('.').last.toLowerCase();
      final size = file.lengthSync();
      final fileName = name ?? path.split(Platform.pathSeparator).last;
      final newId = 'ASSET-${100000 + Random().nextInt(899999)}';

      String finalPath = path;
      String? thumbPath;
      int finalSize = size;
      bool compressed = false;
      AssetType type = _detectType(ext);

      if (!kIsWeb && type == AssetType.image) {
        try {
          final dir = await _getCacheDir();
          final outPath = '${dir.path}/$newId${_outputExt(ext)}';
          final tPath = '${dir.path}/${newId}_thumb.jpg';

          final res = await compute(
            _compressInBackground,
            _CompressInput(
              sourcePath: path,
              outputPath: outPath,
              thumbPath: tPath,
            ),
          );
          if (res != null) {
            finalPath = res.compressedPath;
            thumbPath = res.thumbPath;
            finalSize = res.newSizeBytes;
            compressed = true;
          }
        } catch (_) {}
      }

      _assets.insert(
        0,
        AssetModel(
          id: newId,
          name: fileName,
          path: finalPath,
          type: type,
          sizeBytes: finalSize,
          originalSizeBytes: size,
          thumbnailPath: thumbPath,
          isCompressed: compressed,
        ),
      );
      await _saveToStorage();
      notifyListeners();
      return newId;
    } catch (e) {
      if (kDebugMode) print('Sync error: $e');
      return null;
    }
  }

  /// Use this to automatically store any external URL into the library.
  Future<String?> syncUrlToLibrary(String url, {String? name}) async {
    // 🛡️ SECURITY & DUPLICATION CHECK:
    // If this is already an internal "asset://" link, do NOT create a new duplicate asset.
    if (url.startsWith('asset://')) {
      return url.replaceFirst('asset://', '');
    }

    if (url.isEmpty || !url.startsWith('http')) return null;
    String finalName = name ?? 'Linked Web Asset';
    if (name == null) {
      try {
        final uri = Uri.parse(url);
        if (uri.pathSegments.isNotEmpty) finalName = uri.pathSegments.last;
      } catch (_) {}
    }

    final newId = 'ASSET-${100000 + Random().nextInt(899999)}';
    _assets.insert(
      0,
      AssetModel(
        id: newId,
        name: finalName,
        path: url,
        type: AssetType.image,
        sizeBytes: 0,
        url: url,
      ),
    );
    await _saveToStorage();
    notifyListeners();
    return newId;
  }

  // ── Pick & Import ─────────────────────────────────────────────────────────

  Future<void> pickAndImportAssets({String? folderId}) async {
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true);
      if (result == null) return;

      _isUploading = true;
      _uploadStatus = 'Importing ${result.files.length} file(s)…';
      notifyListeners();

      for (final file in result.files) {
        if (file.path == null) continue;

        final ext = file.extension?.toLowerCase() ?? '';
        AssetType type = _detectType(ext);
        final originalSize = file.size;
        final newId = 'ASSET-${100000 + Random().nextInt(899999)}';

        String finalPath = file.path!;
        String? thumbPath;
        int finalSize = originalSize;
        bool compressed = false;

        // Compress images on non-web platforms
        if (!kIsWeb && type == AssetType.image) {
          try {
            final dir = await _getCacheDir();
            final outPath = '${dir.path}/$newId${_outputExt(ext)}';
            final tPath = '${dir.path}/${newId}_thumb.jpg';

            final res = await compute(
              _compressInBackground,
              _CompressInput(
                sourcePath: file.path!,
                outputPath: outPath,
                thumbPath: tPath,
              ),
            );

            if (res != null) {
              finalPath = res.compressedPath;
              thumbPath = res.thumbPath;
              finalSize = res.newSizeBytes;
              compressed = true;
            }
          } catch (e) {
            if (kDebugMode) print('Compression skipped: $e');
          }
        }

        _assets.insert(
          0,
          AssetModel(
            id: newId,
            name: file.name,
            path: finalPath,
            type: type,
            sizeBytes: finalSize,
            originalSizeBytes: originalSize,
            thumbnailPath: thumbPath,
            isCompressed: compressed,
          ),
        );

        // 📁 Auto-assign to folder if provided
        if (folderId != null && folderId != 'all' && folderId != 'trash') {
          final fIdx = _folders.indexWhere((f) => f.id == folderId);
          if (fIdx != -1) {
            final updatedFolder = _folders[fIdx].copyWith(
              assetIds: [..._folders[fIdx].assetIds, newId],
            );
            _folders[fIdx] = updatedFolder;
          }
        }

        _uploadStatus = 'Processed: ${file.name}';
        notifyListeners();
      }

      await _saveToStorage();
    } catch (e) {
      if (kDebugMode) print('Error picking files: $e');
    } finally {
      _isUploading = false;
      _uploadStatus = null;
      notifyListeners();
    }
  }

  // ── External URL ──────────────────────────────────────────────────────────

  void addExternalUrl(String url) {
    if (url.isEmpty) return;
    
    // 🛡️ Internal duplication check
    if (url.startsWith('asset://')) return;

    String name = 'External Web Link';
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) name = uri.pathSegments.last;
    } catch (_) {}

    _assets.insert(
      0,
      AssetModel(
        id: 'ASSET-${100000 + Random().nextInt(899999)}',
        name: name,
        path: url,
        type: AssetType.image,
        sizeBytes: 0,
        url: url,
      ),
    );
    _saveToStorage();
    notifyListeners();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  /// Move an asset to Drafts
  void removeAsset(String id) {
    final index = _assets.indexWhere((a) => a.id == id);
    if (index != -1) {
      _assets[index] = _assets[index].copyWith(isDeleted: true);
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Restore an asset from Drafts
  void restoreAsset(String id) {
    final index = _assets.indexWhere((a) => a.id == id);
    if (index != -1) {
      _assets[index] = _assets[index].copyWith(isDeleted: false);
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Permanently delete an asset
  void permanentDeleteAsset(String id) {
    _assets.removeWhere((a) => a.id == id);
    _saveToStorage();
    notifyListeners();
  }

  /// Clear all drafts
  void emptyTrash() {
    _assets.removeWhere((a) => a.isDeleted);
    _saveToStorage();
    notifyListeners();
  }

  void updateAssetName(String id, String newName) {
    final index = _assets.indexWhere((a) => a.id == id);
    if (index != -1) {
      _assets[index] = _assets[index].copyWith(name: newName);
      _saveToStorage();
      notifyListeners();
    }
  }

  // ── Folder Management ───────────────────────────────────────────────────

  void createFolder(String name) {
    final id = 'FOLDER-${1000 + Random().nextInt(8999)}';
    _folders.insert(0, AssetFolderModel(id: id, name: name, assetIds: []));
    _saveToStorage();
    notifyListeners();
  }

  void deleteFolder(String folderId) {
    _folders.removeWhere((f) => f.id == folderId);
    _saveToStorage();
    notifyListeners();
  }

  void renameFolder(String folderId, String newName) {
    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx != -1) {
      _folders[idx] = _folders[idx].copyWith(name: newName);
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Add or remove an asset from a folder
  void toggleAssetInFolder(String assetId, String folderId) {
    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx != -1) {
      final folder = _folders[idx];
      final newIds = List<String>.from(folder.assetIds);
      if (newIds.contains(assetId)) {
        newIds.remove(assetId);
      } else {
        newIds.add(assetId);
      }
      _folders[idx] = folder.copyWith(assetIds: newIds);
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Get assets belonging to a specific folder
  List<AssetModel> getAssetsByFolder(String folderId) {
    final folder = _folders.firstWhere((f) => f.id == folderId, 
      orElse: () => AssetFolderModel(id: '', name: '', assetIds: []));
    return _assets.where((a) => folder.assetIds.contains(a.id)).toList();
  }

  void addEditedAsset(
    AssetModel originalAsset,
    String newPath,
    String newName,
    int newSizeBytes,
  ) {
    _assets.insert(
      0,
      AssetModel(
        id: 'ASSET-${100000 + Random().nextInt(899999)}_EDITED',
        name: newName,
        path: newPath,
        type: originalAsset.type,
        sizeBytes: newSizeBytes,
      ),
    );
    _saveToStorage();
    notifyListeners();
  }

  /// Total storage used by all assets.
  int get totalStorageBytes => _assets.fold(0, (s, a) => s + a.sizeBytes);

  /// Total bytes saved by compression across all assets.
  int get totalBytesSaved => _assets.fold(
        0,
        (s, a) => s + (a.originalSizeBytes - a.sizeBytes).clamp(0, a.originalSizeBytes),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  AssetType _detectType(String ext) {
    if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'bmp', 'tiff'].contains(ext)) {
      return AssetType.image;
    }
    if (['pdf', 'doc', 'docx', 'txt', 'csv', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) {
      return AssetType.document;
    }
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      return AssetType.video;
    }
    return AssetType.other;
  }

  String _outputExt(String originalExt) {
    // Keep original format — when flutter_image_compress is added, return .webp
    return '.$originalExt';
  }

  Future<Directory> _getCacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/ebm_asset_cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}

// ── Top-level Isolate Helpers ──────────────────────────────────────────────

String _encodeAssets(List<AssetModel> assets) {
  return jsonEncode(assets.map((a) => a.toMap()).toList());
}

List<AssetModel> _decodeAssets(String data) {
  final List<dynamic> jsonList = jsonDecode(data);
  return jsonList.map((m) => AssetModel.fromMap(m)).toList();
}

String _encodeFolders(List<AssetFolderModel> folders) {
  return jsonEncode(folders.map((f) => f.toMap()).toList());
}

List<AssetFolderModel> _decodeFolders(String data) {
  final List<dynamic> jsonList = jsonDecode(data);
  return jsonList.map((m) => AssetFolderModel.fromMap(m)).toList();
}
