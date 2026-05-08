class Plan {
  final String id;
  final String name;
  final String projectId;
  final List<String> consoleIds;
  final Map<String, dynamic> statsSnapshot;

  Plan({
    required this.id,
    required this.name,
    required this.projectId,
    this.consoleIds = const [],
    this.statsSnapshot = const {
      'totalProgressPercentage': 0.0,
      'totalTasks': 0,
      'completedTasks': 0,
      'overallStatus': 'Pending',
    },
  });

  Plan copyWith({
    String? id,
    String? name,
    String? projectId,
    List<String>? consoleIds,
    Map<String, dynamic>? statsSnapshot,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      projectId: projectId ?? this.projectId,
      consoleIds: consoleIds ?? this.consoleIds,
      statsSnapshot: statsSnapshot ?? this.statsSnapshot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'projectId': projectId,
      'consoleIds': consoleIds,
      'statsSnapshot': statsSnapshot,
    };
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      projectId: json['projectId'] ?? '',
      consoleIds: List<String>.from(json['consoleIds'] ?? []),
      statsSnapshot: Map<String, dynamic>.from(json['statsSnapshot'] ?? {}),
    );
  }
}
