import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebficBM/features/tasks/models/system_task.dart';
import 'package:archive/archive.dart';
import 'package:universal_html/html.dart' as html;

class TaskProvider extends ChangeNotifier {
  List<SystemTask> _tasks = [];
  final List<SystemTask> _drafts = [];
  static const String _storageKey = 'bizos_console_tasks';

  List<SystemTask> get allTasks => _tasks;
  List<SystemTask> get draftTasks => _drafts;

  TaskProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    final isComplete = prefs.getBool('bizos_setup_complete_tasks');
    if (jsonStr != null) {
      try {
        final List decoded = json.decode(jsonStr);
        _tasks = decoded.map((m) => SystemTask.fromMap(m)).toList();
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
    await prefs.setBool('bizos_setup_complete_tasks', true);
    final encoded = json.encode(_tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void _initMockData() {
    _tasks = [
      SystemTask(id: 't1', taskNumber: 'TSK-001', title: 'Implement Glassmorphism Dashboard', status: TaskStatus.done, priority: TaskPriority.high, allocatedCost: 1500, assignee: 'Design Team'),
      SystemTask(id: 't2', taskNumber: 'TSK-002', title: 'Setup the global project task Registry', status: TaskStatus.inProgress, priority: TaskPriority.critical, allocatedCost: 8000, assignee: 'Lead Dev'),
      SystemTask(id: 't3', taskNumber: 'TSK-003', title: 'Migrate legacy data', status: TaskStatus.todo, priority: TaskPriority.medium, allocatedCost: 2000, assignee: 'Backend Eng'),
    ];
  }

  void addTask(SystemTask task) {
    _tasks.add(task);
    _saveToStorage();
    notifyListeners();
  }

  void updateTask(SystemTask task) {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
       _tasks[idx] = task;
       _saveToStorage();
       notifyListeners();
    }
  }

  void updateTaskStatus(String taskId, TaskStatus status, {String? planId}) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
       _tasks[idx] = _tasks[idx].copyWith(status: status, planId: planId);
       _saveToStorage();
       notifyListeners();
    }
  }

  void moveToDraft(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _drafts.add(_tasks[idx]);
      _tasks.removeAt(idx);
      _saveToStorage();
      notifyListeners();
    }
  }

  void restoreFromDraft(String taskId) {
    final idx = _drafts.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks.add(_drafts[idx]);
      _drafts.removeAt(idx);
      _saveToStorage();
      notifyListeners();
    }
  }

  void deletePermanently(String taskId, bool isFromDraft) {
    if (isFromDraft) {
      _drafts.removeWhere((t) => t.id == taskId);
    } else {
      _tasks.removeWhere((t) => t.id == taskId);
    }
    _saveToStorage();
    notifyListeners();
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
  void reload() => _loadFromStorage();
}
