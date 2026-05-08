import 'package:flutter/material.dart';

enum ProjectStatus { planned, inProgress, delayed, completed, archived, draft }

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
      id: map['id']?.toString() ?? '',
      icode: map['icode']?.toString() ?? 'IC-0000',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      taskIds: List<String>.from(map['taskIds'] ?? []),
      author: map['author'] ?? 'Admin',
      assignedAuthor: map['assignedAuthor'] ?? 'Unassigned',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      status: Project._parseStatus(map['status']), // Reuse Project's parser
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
      id: map['id']?.toString() ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date'] ?? map['log_date'] ?? DateTime.now().toIso8601String()),
      type: _parseType(map['type']),
      category: map['category'] ?? 'General',
    );
  }

  static LogType _parseType(dynamic val) {
    if (val is int) return LogType.values[val % LogType.values.length];
    if (val is String) {
      if (val.toLowerCase() == 'revenue') return LogType.revenue;
      if (val.toLowerCase() == 'expense') return LogType.expense;
      final idx = int.tryParse(val);
      if (idx != null) return LogType.values[idx % LogType.values.length];
    }
    return LogType.expense;
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
  final String? companyName;
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
  final bool isApproved;


  Project({
    required this.id,
    required this.pid,
    required this.name,
    this.category = 'General',
    required this.description,
    this.companyId,
    this.companyName,
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
    this.isApproved = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pid': pid,
      'name': name,
      'category': category,
      'description': description,
      'companyId': companyId,
      'companyName': companyName,
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
      'isApproved': isApproved,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id']?.toString() ?? '',
      pid: map['pid']?.toString() ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      companyId: map['companyId']?.toString() ?? map['company_id']?.toString(),
      companyName: map['company']?['name']?.toString() ?? map['companyName']?.toString(),
      totalBudget: (map['totalBudget'] ?? map['total_budget'] ?? 0).toDouble(),
      minBudget: (map['minBudget'] ?? map['min_budget'] ?? 0).toDouble(),
      maxBudget: (map['maxBudget'] ?? map['max_budget'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      startDate: DateTime.parse(map['startDate'] ?? map['start_date'] ?? DateTime.now().toIso8601String()),
      estimatedEndDate: DateTime.parse(map['estimatedEndDate'] ?? map['estimated_end_date'] ?? DateTime.now().toIso8601String()),
      actualEndDate: (map['actualEndDate'] ?? map['actual_end_date']) != null ? DateTime.parse(map['actualEndDate'] ?? map['actual_end_date']) : null,
      brandColor: Color(int.tryParse(map['brandColor']?.toString() ?? '') ?? int.tryParse(map['brand_color']?.toString()?.replaceAll('#', '0xFF') ?? '') ?? 0xFF6366F1),
      website: map['website'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['phone'] ?? '',
      coverPhotoUrl: map['coverPhotoUrl'] ?? map['cover_photo_url'] ?? '',
      adminPhotos: List<String>.from(map['adminPhotos'] ?? []),
      inspirationText: map['inspirationText'] ?? map['inspiration_text'] ?? '',
      managerSignature: map['managerSignature'] ?? '',
      additionalLinks: List<String>.from(map['additionalLinks'] ?? []),
      taskIds: List<String>.from(map['taskIds'] ?? []),
      plans: List<Plan>.from((map['plans'] as List? ?? []).map((p) => Plan.fromMap(p))),
      financialLogs: List<CostLog>.from(((map['financialLogs'] ?? map['cost_logs'] ?? map['costLogs']) as List? ?? []).map((l) => CostLog.fromMap(l))),
      syncLogs: List<HistoryLog>.from(((map['syncLogs'] ?? map['history_logs']) as List? ?? []).map((l) => HistoryLog.fromMap(l))),
      isApproved: _parseBool(map['isApproved'] ?? map['is_approved'] ?? true),
    );
  }

  static ProjectStatus _parseStatus(dynamic val) {
    if (val is int) return ProjectStatus.values[val % ProjectStatus.values.length];
    if (val is String) {
      final idx = int.tryParse(val);
      if (idx != null) return ProjectStatus.values[idx % ProjectStatus.values.length];
      return ProjectStatus.values.firstWhere((e) => e.name == val, orElse: () => ProjectStatus.planned);
    }
    return ProjectStatus.planned;
  }

  static bool _parseBool(dynamic val) {
    if (val is bool) return val;
    if (val is int) return val == 1;
    if (val is String) {
      final s = val.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes' || s == 'approved' || s == 'active';
    }
    return false;
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
      companyId: companyId ?? this.companyId, companyName: companyName ?? this.companyName, totalBudget: totalBudget ?? this.totalBudget,
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
