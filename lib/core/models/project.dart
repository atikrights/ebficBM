class Project {
  final String id;
  final String name;
  final String description;
  final String? companyId;
  final List<String> planIds;
  final Map<String, dynamic> statsSnapshot;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    this.companyId,
    this.planIds = const [],
    this.statsSnapshot = const {
      'totalProgressPercentage': 0.0,
      'totalTasks': 0,
      'completedTasks': 0,
      'overallStatus': 'Planning',
    },
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? companyId,
    List<String>? planIds,
    Map<String, dynamic>? statsSnapshot,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      planIds: planIds ?? this.planIds,
      statsSnapshot: statsSnapshot ?? this.statsSnapshot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'companyId': companyId,
      'planIds': planIds,
      'statsSnapshot': statsSnapshot,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      companyId: json['companyId'],
      planIds: List<String>.from(json['planIds'] ?? []),
      statsSnapshot: Map<String, dynamic>.from(json['statsSnapshot'] ?? {}),
    );
  }
}
