import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizos_x_pro/features/projects/models/project.dart';

class ProjectProvider with ChangeNotifier {
  List<Project> _projects = [];
  static const String _storageKey = 'bizos_projects_registry';

  List<Project> get allProjects => [..._projects];

  ProjectProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    final isComplete = prefs.getBool('bizos_setup_complete_projects');
    if (jsonStr != null) {
      try {
        final List decoded = json.decode(jsonStr);
        _projects = decoded.map((m) => Project.fromMap(m)).toList();
      } catch (e) {
        if (isComplete != true) _initMockData();
      }
    } else {
      if (isComplete != true) _initMockData();
    }
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bizos_setup_complete_projects', true);
    final encoded = json.encode(_projects.map((p) => p.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void _initMockData() {
    _projects = [
      Project(
        id: 'proj_1',
        pid: 'PRJ-001-A42F',
        name: 'Alpha Server Migration',
        description: 'Complete overhaul of backend servers to AWS cluster.',
        companyId: '1',
        totalBudget: 150000.0,
        status: ProjectStatus.inProgress,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        estimatedEndDate: DateTime.now().add(const Duration(days: 60)),
        brandColor: Colors.blueAccent,
        financialLogs: [
          CostLog(id: 'c1', description: 'Server Deposits', amount: 12000.0, date: DateTime.now().subtract(const Duration(days: 28)), type: LogType.expense, category: 'Hardware'),
        ],
        taskIds: ['t1', 't2', 't3'],
      ),
      Project(
        id: 'proj_2',
        pid: 'PRJ-002-B71C',
        name: 'Neo Mobile App',
        description: 'Flutter cross-platform application for retail tracking.',
        companyId: '5',
        totalBudget: 85000.0,
        status: ProjectStatus.planned,
        startDate: DateTime.now().add(const Duration(days: 10)),
        estimatedEndDate: DateTime.now().add(const Duration(days: 120)),
        brandColor: Colors.purpleAccent,
      ),
    ];
  }

  String deployProject(String name) {
    final newId = 'proj_${_projects.length + 1}';
    final randomHex = (DateTime.now().millisecondsSinceEpoch % 10000).toRadixString(16).toUpperCase().padLeft(4, '0');
    final newPid = 'PRJ-${(_projects.length + 1).toString().padLeft(3, '0')}-$randomHex';
    
    final newProject = Project(
      id: newId,
      pid: newPid,
      name: name,
      description: 'System generated registry for $name.',
      startDate: DateTime.now(),
      estimatedEndDate: DateTime.now().add(const Duration(days: 30)),
      totalBudget: 0.0,
      brandColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
    );
    
    _projects.add(newProject);
    _saveToStorage();
    notifyListeners();
    return newId;
  }

  List<Project> getProjectsForCompany(String companyId) {
    return _projects.where((p) => p.companyId == companyId).toList();
  }

  List<Project> get standaloneProjects {
    return _projects.where((p) => p.companyId == null).toList();
  }

  void addLog(String projectId, CostLog log) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      _projects[idx] = p.copyWith(financialLogs: [...p.financialLogs, log]);
      _saveToStorage();
      notifyListeners();
    }
  }

  void linkTaskToProject(String projectId, String taskId) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      if (!p.taskIds.contains(taskId)) {
         _projects[idx] = p.copyWith(taskIds: [...p.taskIds, taskId]);
         _saveToStorage();
         notifyListeners();
      }
    }
  }

  void updateProject(Project project) {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx != -1) {
      _projects[idx] = project;
      _saveToStorage();
      notifyListeners();
    }
  }

  void addPlanToProject(String projectId, String title, String description) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      // Generate a unique 6-digit numeric i-CODE
      final random = Random();
      final icode = (random.nextInt(900000) + 100000).toString(); // Always 6 digits
      
      final newPlan = Plan(
        id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
        icode: icode,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        historyLogs: [
          HistoryLog(
            id: 'h_${DateTime.now().millisecondsSinceEpoch}',
            message: 'Strategic Console Log initialized with iCODE: $icode',
            timestamp: DateTime.now(),
            author: 'System Admin',
            actionType: 'INITIALIZATION',
          ),
        ],
      );
      _projects[idx] = p.copyWith(plans: [...p.plans, newPlan]);
      _saveToStorage();
      notifyListeners();
    }
  }

  void updatePlanStatus(String projectId, String planId, ProjectStatus newStatus, String adminName) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      final plans = p.plans.map((pl) {
        if (pl.id == planId) {
          final log = HistoryLog(
            id: 'h_${DateTime.now().millisecondsSinceEpoch}',
            message: 'Status shifted from ${pl.status.name} to ${newStatus.name}',
            timestamp: DateTime.now(),
            author: adminName,
            actionType: 'STATUS_SHIFT',
          );
          return pl.copyWith(status: newStatus, historyLogs: [...pl.historyLogs, log]);
        }
        return pl;
      }).toList();
      _projects[idx] = p.copyWith(plans: plans);
      _saveToStorage();
      notifyListeners();
    }
  }

  void linkTaskToPlan(String projectId, String planId, String taskId, String taskTitle, String adminName) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      final plans = p.plans.map((pl) {
        if (pl.id == planId && !pl.taskIds.contains(taskId)) {
          final log = HistoryLog(
            id: 'h_${DateTime.now().millisecondsSinceEpoch}',
            message: 'Linked secure unit: $taskTitle ($taskId)',
            timestamp: DateTime.now(),
            author: adminName,
            actionType: 'UNIT_LINKED',
          );
          return pl.copyWith(taskIds: [...pl.taskIds, taskId], historyLogs: [...pl.historyLogs, log]);
        }
        return pl;
      }).toList();
      _projects[idx] = p.copyWith(plans: plans);
      _saveToStorage();
      notifyListeners();
    }
  }

  void removePlan(String projectId, String planId) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      _projects[idx] = p.copyWith(plans: p.plans.where((pl) => pl.id != planId).toList());
      _saveToStorage();
      notifyListeners();
    }
  }

  void assignAuthorToPlan(String projectId, String planId, String author) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      final plans = p.plans.map((pl) {
        if (pl.id == planId) {
           final log = HistoryLog(
            id: 'h_${DateTime.now().millisecondsSinceEpoch}',
            message: 'Assigned operator changed to: $author',
            timestamp: DateTime.now(),
            author: 'Security Admin',
            actionType: 'OPERATOR_ASSIGNED',
          );
          return pl.copyWith(assignedAuthor: author, historyLogs: [...pl.historyLogs, log]);
        }
        return pl;
      }).toList();
      _projects[idx] = p.copyWith(plans: plans);
      _saveToStorage();
      notifyListeners();
    }
  }

   void deleteProject(String id) {
    _projects.removeWhere((p) => p.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void reload() => _loadFromStorage();
}
