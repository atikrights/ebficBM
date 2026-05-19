import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebficbm/features/tasks/models/system_task.dart';
import 'package:archive/archive.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/services/pusher_service.dart' as import_pusher;
import '../../../core/network/api_service.dart';

class TaskProvider extends ChangeNotifier {
  ApiService? _api;
  List<SystemTask> _tasks = [];
  final List<SystemTask> _drafts = [];
  static const String _storageKey = 'bizos_console_tasks';
  bool _isSyncing = false;
  Timer? _syncTimer;

  List<SystemTask> get allTasks => _tasks;
  List<SystemTask> get draftTasks => _drafts;

  TaskProvider() {
    _loadFromStorage();
  }

  void update(ApiService? api) {
    _api = api;
    if (_api != null && _tasks.isEmpty) {
      _loadFromStorage().then((_) {
        _startPeriodicSync();
        _initPusher();
      });
    } else if (_api != null) {
      _startPeriodicSync();
      _initPusher();
    }
  }

  bool _pusherInitialized = false;

  void _initPusher() {
    if (_pusherInitialized) return;
    try {
      import_pusher.PusherService().addListener((event) {
        if (event.eventName == 'data.updated' || event.eventName == r'App\Events\DataUpdated') {
          try {
            final Map<String, dynamic> payload = json.decode(event.data.toString());
            final message = payload['message'] as String?;
            if (message != null && message.startsWith('task_')) {
              syncWithDatabase();
            }
          } catch (_) {
            syncWithDatabase();
          }
        }
      });
      _pusherInitialized = true;
    } catch (e) {
      debugPrint('TaskProvider Pusher Init Error: $e');
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => syncWithDatabase());
    syncWithDatabase();
  }

  Future<void> syncWithDatabase({String? projectId, String? planId}) async {
    if (_api == null || _isSyncing) return;

    try {
      _isSyncing = true;
      String endpoint = '/tasks';
      if (projectId != null || planId != null) {
        final params = <String>[];
        if (projectId != null) params.add('project_id=$projectId');
        if (planId != null) params.add('plan_id=$planId');
        endpoint += '?' + params.join('&');
      }

      final response = await _api!.get(endpoint);
      List? rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] is List) {
        rawList = response['data'];
      }

      if (rawList != null) {
        _tasks = rawList.map((m) => SystemTask.fromMap(m)).toList();
        await _saveToStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Task Sync Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List decoded = json.decode(jsonStr);
        _tasks = decoded.map((m) => SystemTask.fromMap(m)).toList();
      } catch (e) {
        debugPrint('Error loading tasks from storage: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<SystemTask?> addTask(SystemTask task, {required String companyId}) async {
    if (_api == null) return null;

    try {
      final response = await _api!.post('/tasks', {
        ...task.toMap(),
        'company_id': companyId,
      });

      if (response != null) {
        final created = SystemTask.fromMap(response);
        _tasks.insert(0, created);
        await _saveToStorage();
        notifyListeners();
        return created;
      }
    } catch (e) {
      debugPrint('❌ Add Task Error: $e');
    }
    return null;
  }

  Future<void> updateTask(SystemTask task) async {
    if (_api == null) return;

    try {
      final response = await _api!.put('/tasks/${task.id}', task.toMap());
      if (response != null) {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          _tasks[idx] = SystemTask.fromMap(response);
          await _saveToStorage();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Update Task Error: $e');
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final updated = _tasks[idx].copyWith(status: status);
      await updateTask(updated);
    }
  }

  Future<void> moveToDraft(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _tasks.removeAt(idx);
      _drafts.add(task);
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> restoreFromDraft(String taskId) async {
    final idx = _drafts.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _drafts.removeAt(idx);
      _tasks.insert(0, task);
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> deletePermanently(String taskId, [bool fromDraft = false]) async {
    if (fromDraft) {
      _drafts.removeWhere((t) => t.id == taskId);
      notifyListeners();
      await _saveToStorage();
      return;
    }

    if (_api == null) return;

    final backup = [..._tasks];
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();

    try {
      await _api!.delete('/tasks/$taskId');
      await _saveToStorage();
    } catch (e) {
      _tasks = backup;
      notifyListeners();
      debugPrint('❌ Delete Task Error: $e');
    }
  }

  // ── Multi-Task Export Engine ──
  void generateMultiTaskZip(List<SystemTask> tasks) {
    if (tasks.isEmpty) return;
    final archive = Archive();
    
    for (final task in tasks) {
      final summary = _generateSummaryText(task);
      final bytes = utf8.encode(summary);
      archive.addFile(ArchiveFile('${task.taskNumber}/Summary_${task.taskNumber}.txt', bytes.length, bytes));
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      final blob = html.Blob([zipData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Bulk_Export_${DateTime.now().millisecondsSinceEpoch}.zip")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  String _generateSummaryText(SystemTask task) {
    return """UID: ${task.taskNumber}\nTITLE: ${task.title}\nSTATUS: ${task.status.name}""";
  }

  void reload() => syncWithDatabase();

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
