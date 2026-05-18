import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebficbm/features/projects/models/project.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/pusher_service.dart' as import_pusher;

class ProjectProvider with ChangeNotifier {
  ApiService? _api;
  List<Project> _projects = [];
  static const String _storageKey = 'bizos_projects_registry';
  bool _isLoading = false;
  bool _isSyncing = false;
  Timer? _syncTimer;

  List<Project> get allProjects => [..._projects];
  bool get isLoading => _isLoading;

  ProjectProvider() {
    _loadFromStorage();
  }

  void update(ApiService? api) {
    _api = api;
    if (_api != null && _projects.isEmpty) {
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
            if (message != null && (message.startsWith('project_') || message.startsWith('plan_') || message.startsWith('task_'))) {
              syncWithDatabase();
            }
          } catch (_) {
            syncWithDatabase();
          }
        }
      });
      _pusherInitialized = true;
    } catch (e) {
      debugPrint('ProjectProvider Pusher Init Error: $e');
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => syncWithDatabase());
    // Initial sync
    syncWithDatabase();
  }

  Future<void> syncWithDatabase() async {
    if (_api == null || _isSyncing) return;
    
    try {
      _isSyncing = true;
      // We usually fetch all projects the user has access to. 
      // Filter by company happens on UI or via query param.
      final response = await _api!.get('/projects');
      if (response is List) {
        _projects = response.map((m) => Project.fromMap(m)).toList();
        await _saveToStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Project Sync Error: $e');
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
        _projects = decoded.map((m) => Project.fromMap(m)).toList();
      } catch (e) {
        debugPrint('Error loading projects from storage: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_projects.map((p) => p.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<String?> deployProject({
    required String name,
    String? companyId,
    String category = 'General',
    String description = '',
  }) async {
    if (_api == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api!.post('/projects', {
        'name': name,
        'company_id': companyId,
        'category': category,
        'description': description,
      });

      if (response != null) {
        final newProject = Project.fromMap(response);
        _projects.insert(0, newProject);
        await _saveToStorage();
        _isLoading = false;
        notifyListeners();
        return newProject.id;
      }
    } catch (e) {
      debugPrint('❌ Project Deployment Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  List<Project> getProjectsForCompany(String companyId) {
    // String comparison since ID might be int or string from API
    return _projects.where((p) => p.companyId?.toString() == companyId.toString()).toList();
  }

  Future<void> addLog(String projectId, CostLog log) async {
    if (_api == null) return;
    
    // Find numeric ID if mobile uses string IDs
    final project = _projects.firstWhere((p) => p.id == projectId);
    
    try {
      final response = await _api!.post('/projects/${project.id}/cost-logs', {
        'description': log.description,
        'amount': log.amount,
        'type': log.type.index == 0 ? 'expense' : 'revenue',
        'category': log.category,
        'log_date': log.date.toIso8601String().split('T')[0],
      });

      if (response != null) {
        await syncWithDatabase(); // Refresh everything
      }
    } catch (e) {
      debugPrint('❌ Cost Log Sync Error: $e');
    }
  }

  Future<void> addPlanToProject(String projectId, String title, String description) async {
    if (_api == null) return;
    
    try {
      final response = await _api!.post('/projects/$projectId/plans', {
        'title': title,
        'description': description,
      });

      if (response != null) {
        await syncWithDatabase();
      }
    } catch (e) {
      debugPrint('❌ Add Plan Error: $e');
    }
  }

  Future<void> updateProject(Project project) async {
    if (_api == null) return;
    try {
      final response = await _api!.put('/projects/${project.id}', project.toMap());
      if (response != null) {
        await syncWithDatabase();
      }
    } catch (e) {
      debugPrint('❌ Update Project Error: $e');
    }
  }

  // ── MANUAL COMPANY ATTACHMENT SYSTEM ─────────────────────────────────────

  /// Method 2: From Project Single Page — attach this project to a company
  Future<bool> attachToCompany(String projectId, String companyId) async {
    if (_api == null) return false;
    try {
      final response = await _api!.post('/projects/$projectId/attach-company', {
        'company_id': companyId,
      });
      if (response != null) {
        await syncWithDatabase();
        return true;
      }
    } catch (e) {
      debugPrint('❌ Attach Company Error: $e');
    }
    return false;
  }

  /// Method 1: From Company Single Page — batch-attach multiple projects
  Future<List<Map<String, dynamic>>> batchAttachToCompany(
      String companyId, List<String> projectIds) async {
    if (_api == null) return [];
    try {
      final response = await _api!.post(
        '/companies/$companyId/attach-projects',
        {'project_ids': projectIds},
      );
      if (response != null) {
        await syncWithDatabase();
        return List<Map<String, dynamic>>.from(response['results'] ?? []);
      }
    } catch (e) {
      debugPrint('❌ Batch Attach Error: $e');
    }
    return [];
  }

  /// Detach a project from its company — returns to creator private scope
  Future<bool> detachFromCompany(String projectId) async {
    if (_api == null) return false;
    try {
      final response = await _api!.post('/projects/$projectId/detach-company', {});
      if (response != null) {
        await syncWithDatabase();
        return true;
      }
    } catch (e) {
      debugPrint('❌ Detach Company Error: $e');
    }
    return false;
  }

  /// Fetch all unattached projects (null company_id) for the picker modal
  Future<List<Project>> fetchUnattachedProjects() async {
    if (_api == null) return [];
    try {
      final response = await _api!.get('/projects/unattached');
      if (response is List) {
        return response.map((m) => Project.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint('❌ Fetch Unattached Error: $e');
    }
    return [];
  }

  /// Get all private/unattached projects (null companyId) from local cache
  List<Project> get unattachedProjects =>
      _projects.where((p) => p.companyId == null || p.companyId!.isEmpty).toList();

  /// Get all pending-approval projects (isApproved = false) from local cache
  List<Project> get pendingProjects =>
      _projects.where((p) => !p.isApproved).toList();

  Future<void> removePlan(String projectId, String planId) async {
    if (_api == null) return;
    try {
      await _api!.delete('/plans/$planId');
      await syncWithDatabase();
    } catch (e) {
      debugPrint('❌ Remove Plan Error: $e');
    }
  }

  Future<void> assignAuthorToPlan(String projectId, String planId, String author) async {
    if (_api == null) return;
    try {
      await _api!.put('/plans/$planId', {'assigned_to': author});
      await syncWithDatabase();
    } catch (e) {
      debugPrint('❌ Assign Author Error: $e');
    }
  }

  Future<void> updatePlanStatus(String projectId, String planId, String status) async {
    if (_api == null) return;
    try {
      await _api!.put('/plans/$planId', {'status': status});
      await syncWithDatabase();
    } catch (e) {
      debugPrint('❌ Update Plan Status Error: $e');
    }
  }

  Future<void> linkTaskToPlan(String projectId, String planId, String taskId, String taskTitle, String author) async {
    if (_api == null) return;
    try {
      await _api!.put('/tasks/$taskId', {
        'plan_id': planId,
        'project_id': projectId,
      });
      await syncWithDatabase();
    } catch (e) {
      debugPrint('❌ Link Task Error: $e');
    }
  }

  Future<void> clearSyncLogs(String projectId) async {
    await syncWithDatabase();
  }

  Future<void> deleteProject(String id) async {
    if (_api == null) return;
    final backup = [..._projects];
    _projects.removeWhere((p) => p.id == id);
    notifyListeners();
    try {
      await _api!.delete('/projects/$id');
      await _saveToStorage();
    } catch (e) {
      _projects = backup;
      notifyListeners();
      debugPrint('❌ Delete Project Error: $e');
    }
  }

  void reload() => syncWithDatabase();

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
