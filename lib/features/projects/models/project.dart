import 'package:flutter/material.dart';

enum ProjectStatus { planned, inProgress, delayed, completed, archived }

enum LogType { expense, revenue }

class HistoryLog {
  final String id;
  final String message;
  final DateTime timestamp;
  final String author;
  final String actionType; // e.g. "STATUS_CHANGE", "TASK_LINKED", "CREATED"

  HistoryLog({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.author,
    required this.actionType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'author': author,
      'actionType': actionType,
    };
  }

  factory HistoryLog.fromMap(Map<String, dynamic> map) {
    return HistoryLog(
      id: map['id'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      author: map['author'] ?? 'Admin',
      actionType: map['actionType'] ?? 'GENERAL',
    );
  }
}

class Plan {
  final String id;
  final String icode; // New: Unique Tracking Code
  final String title;
  final String description;
  final List<String> taskIds;
  final String author;
  final String assignedAuthor;
  final DateTime createdAt;
  final ProjectStatus status;
  final List<HistoryLog> historyLogs; // New: Traceability Logs

  Plan({
    required this.id,
    required this.icode,
    required this.title,
    required this.description,
    this.taskIds = const [],
    this.author = 'Admin',
    this.assignedAuthor = 'Unassigned',
    required this.createdAt,
    this.status = ProjectStatus.planned,
    this.historyLogs = const [],
  });

  Plan copyWith({
    String? id, String? icode, String? title, String? description, List<String>? taskIds,
    String? author, String? assignedAuthor, DateTime? createdAt, ProjectStatus? status,
    List<HistoryLog>? historyLogs,
  }) {
    return Plan(
      id: id ?? this.id,
      icode: icode ?? this.icode,
      title: title ?? this.title,
      description: description ?? this.description,
      taskIds: taskIds ?? this.taskIds,
      author: author ?? this.author,
      assignedAuthor: assignedAuthor ?? this.assignedAuthor,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      historyLogs: historyLogs ?? this.historyLogs,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'icode': icode,
      'title': title,
      'description': description,
      'taskIds': taskIds,
      'author': author,
      'assignedAuthor': assignedAuthor,
      'createdAt': createdAt.toIso8601String(),
      'status': status.index,
      'historyLogs': historyLogs.map((l) => l.toMap()).toList(),
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'] ?? '',
      icode: map['icode'] ?? 'IC-0000',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      taskIds: List<String>.from(map['taskIds'] ?? []),
      author: map['author'] ?? 'Admin',
      assignedAuthor: map['assignedAuthor'] ?? 'Unassigned',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      status: ProjectStatus.values[map['status'] ?? 0],
      historyLogs: (map['historyLogs'] as List? ?? []).map((l) => HistoryLog.fromMap(l)).toList(),
    );
  }
}

class CostLog {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final LogType type;
  final String category;

  CostLog({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.type = LogType.expense,
    this.category = 'General',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.index,
      'category': category,
    };
  }

  factory CostLog.fromMap(Map<String, dynamic> map) {
    return CostLog(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      type: LogType.values[map['type'] ?? 0],
      category: map['category'] ?? 'General',
    );
  }

  CostLog copyWith({String? id, String? description, double? amount, DateTime? date, LogType? type, String? category}) {
    return CostLog(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
    );
  }
}

// Removed old ProjectTask completely.

class Project {
  final String id;
  final String pid;
  final String name;
  final String category;
  final String description;
  final String? companyId;
  final double totalBudget;
  final double minBudget;
  final double maxBudget;
  final ProjectStatus status;
  final DateTime startDate;
  final DateTime estimatedEndDate;
  final DateTime? actualEndDate;
  final Color brandColor;
  
  // Additional info
  final String website;
  final String phoneNumber;
  final String coverPhotoUrl;
  final List<String> adminPhotos; // Multi-admin profile photos
  final String inspirationText;
  final String managerSignature;
  final List<String> additionalLinks;
  
  final List<String> taskIds;
  final List<Plan> plans;
  final List<CostLog> financialLogs;
  final List<HistoryLog> syncLogs; // New: Activity logs for attachment/sync

  Project({
    required this.id,
    required this.pid,
    required this.name,
    this.category = 'General',
    required this.description,
    this.companyId,
    this.totalBudget = 0.0,
    this.minBudget = 0.0,
    this.maxBudget = 0.0,
    this.status = ProjectStatus.planned,
    required this.startDate,
    required this.estimatedEndDate,
    this.actualEndDate,
    required this.brandColor,
    this.website = '',
    this.phoneNumber = '',
    this.coverPhotoUrl = '',
    this.adminPhotos = const [],
    this.inspirationText = '',
    this.managerSignature = '',
    this.additionalLinks = const [],
    this.taskIds = const [],
    this.plans = const [],
    this.financialLogs = const [],
    this.syncLogs = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pid': pid,
      'name': name,
      'category': category,
      'description': description,
      'companyId': companyId,
      'totalBudget': totalBudget,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
      'status': status.index,
      'startDate': startDate.toIso8601String(),
      'estimatedEndDate': estimatedEndDate.toIso8601String(),
      'actualEndDate': actualEndDate?.toIso8601String(),
      'brandColor': brandColor.value,
      'website': website,
      'phoneNumber': phoneNumber,
      'coverPhotoUrl': coverPhotoUrl,
      'adminPhotos': adminPhotos,
      'inspirationText': inspirationText,
      'managerSignature': managerSignature,
      'additionalLinks': additionalLinks,
      'taskIds': taskIds,
      'plans': plans.map((p) => p.toMap()).toList(),
      'financialLogs': financialLogs.map((l) => l.toMap()).toList(),
      'syncLogs': syncLogs.map((l) => l.toMap()).toList(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      pid: map['pid'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      companyId: map['companyId'],
      totalBudget: (map['totalBudget'] ?? 0).toDouble(),
      minBudget: (map['minBudget'] ?? 0).toDouble(),
      maxBudget: (map['maxBudget'] ?? 0).toDouble(),
      status: ProjectStatus.values[map['status'] ?? 0],
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      estimatedEndDate: DateTime.parse(map['estimatedEndDate'] ?? DateTime.now().toIso8601String()),
      actualEndDate: map['actualEndDate'] != null ? DateTime.parse(map['actualEndDate']) : null,
      brandColor: Color(map['brandColor'] ?? 0xFF6366F1),
      website: map['website'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      coverPhotoUrl: map['coverPhotoUrl'] ?? '',
      adminPhotos: List<String>.from(map['adminPhotos'] ?? []),
      inspirationText: map['inspirationText'] ?? '',
      managerSignature: map['managerSignature'] ?? '',
      additionalLinks: List<String>.from(map['additionalLinks'] ?? []),
      taskIds: List<String>.from(map['taskIds'] ?? []),
      plans: (map['plans'] as List? ?? []).map((p) => Plan.fromMap(p)).toList(),
      financialLogs: (map['financialLogs'] as List? ?? []).map((l) => CostLog.fromMap(l)).toList(),
      syncLogs: (map['syncLogs'] as List? ?? []).map((l) => HistoryLog.fromMap(l)).toList(),
    );
  }

  double get consumedBudget => financialLogs.where((l) => l.type == LogType.expense).fold(0.0, (sum, log) => sum + log.amount);
  double get generatedRevenue => financialLogs.where((l) => l.type == LogType.revenue).fold(0.0, (sum, log) => sum + log.amount);

  Project copyWith({
    String? id, String? pid, String? name, String? category, String? description,
    String? companyId, double? totalBudget, double? minBudget, double? maxBudget,
    ProjectStatus? status, DateTime? startDate, DateTime? estimatedEndDate,
    DateTime? actualEndDate, Color? brandColor, String? website, String? phoneNumber,
    String? coverPhotoUrl, List<String>? adminPhotos, String? inspirationText, String? managerSignature,
    List<String>? additionalLinks, List<String>? taskIds, List<Plan>? plans,
    List<CostLog>? financialLogs, List<HistoryLog>? syncLogs,
  }) {
    return Project(
      id: id ?? this.id, pid: pid ?? this.pid, name: name ?? this.name,
      category: category ?? this.category, description: description ?? this.description,
      companyId: companyId ?? this.companyId, totalBudget: totalBudget ?? this.totalBudget,
      minBudget: minBudget ?? this.minBudget, maxBudget: maxBudget ?? this.maxBudget,
      status: status ?? this.status, startDate: startDate ?? this.startDate,
      estimatedEndDate: estimatedEndDate ?? this.estimatedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate, brandColor: brandColor ?? this.brandColor,
      website: website ?? this.website, phoneNumber: phoneNumber ?? this.phoneNumber,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl, 
      adminPhotos: adminPhotos ?? this.adminPhotos,
      inspirationText: inspirationText ?? this.inspirationText,
      managerSignature: managerSignature ?? this.managerSignature,
      additionalLinks: additionalLinks ?? this.additionalLinks,
      taskIds: taskIds ?? this.taskIds,
      plans: plans ?? this.plans,
      financialLogs: financialLogs ?? this.financialLogs,
      syncLogs: syncLogs ?? this.syncLogs,
    );
  }
}
