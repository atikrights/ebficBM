import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/project.dart';
import '../models/plan.dart';
import '../models/console.dart';
import '../models/task.dart';

class AnalysisEngine extends ChangeNotifier {
  // State Isolation: Keeping entities in separate memory maps
  final Map<String, Company> _companies = {};
  final Map<String, Project> _projects = {};
  final Map<String, Plan> _plans = {};
  final Map<String, Console> _consoles = {};
  final Map<String, AppTask> _tasks = {};

  Map<String, Company> get companies => _companies;
  Map<String, Project> get projects => _projects;
  Map<String, Plan> get plans => _plans;
  Map<String, Console> get consoles => _consoles;
  Map<String, AppTask> get tasks => _tasks;

  // For UI Demonstration, let's inject dummy data automatically
  AnalysisEngine() {
    _initDummyData();
  }

  Company? getCompany(String id) => _companies[id];
  Project? getProject(String id) => _projects[id];
  Plan? getPlan(String id) => _plans[id];
  Console? getConsole(String id) => _consoles[id];
  AppTask? getTask(String id) => _tasks[id];

  // 1. Linking Service logic
  Future<bool> linkProjectToCompany(String projectId, String companyId) async {
    try {
      final project = _projects[projectId];
      final company = _companies[companyId];
      if (project == null || company == null) return false;

      // Disconnect from old company if necessary
      if (project.companyId != null && project.companyId != companyId) {
        final oldCompany = _companies[project.companyId];
        if (oldCompany != null) {
          final oldProjList = List<String>.from(oldCompany.projectIds)..remove(projectId);
          _companies[project.companyId!] = oldCompany.copyWith(projectIds: oldProjList);
        }
      }

      // Link Project -> Company
      _projects[projectId] = project.copyWith(companyId: companyId);

      // Link Company -> Project
      if (!company.projectIds.contains(projectId)) {
        final newProjList = List<String>.from(company.projectIds)..add(projectId);
        _companies[companyId] = company.copyWith(projectIds: newProjList);
      }

      _bubbleCalculate(companyId: companyId);
      return true;
    } catch (e) {
      debugPrint("Atomic Error: $e"); 
      return false; 
    }
  }

  // 2. Bubbling Calculation Engine
  void _bubbleCalculate({String? companyId, String? projectId, String? planId, String? consoleId}) {
     // An advanced recursive or step-by-step recalculation 
     // For this version we will dispatch a notifyListeners to update UI
     // where the UI reads the snapshot.
     notifyListeners();
  }

  void _initDummyData() {
    // Single powerful Company
    _companies['C1'] = Company(
      id: 'C1', name: 'BizOS Enterprise', description: 'Main holding company',
      projectIds: ['P1', 'P2'],
      statsSnapshot: {'totalProgressPercentage': 0.75, 'totalTasks': 120, 'completedTasks': 90, 'overallStatus': 'Active'}
    );

    // Two Projects
    _projects['P1'] = Project(
      id: 'P1', name: 'Alpha Release', companyId: 'C1', planIds: ['PL1', 'PL2'],
      statsSnapshot: {'totalProgressPercentage': 0.85, 'totalTasks': 50, 'completedTasks': 42, 'overallStatus': 'Testing'}
    );
    _projects['P2'] = Project(
      id: 'P2', name: 'Beta Features', companyId: 'C1', planIds: ['PL3'],
      statsSnapshot: {'totalProgressPercentage': 0.45, 'totalTasks': 70, 'completedTasks': 31, 'overallStatus': 'Development'}
    );

    notifyListeners();
  }
}
