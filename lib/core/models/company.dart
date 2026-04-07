class Company {
  final String id;
  final String name;
  final String description;
  final List<String> projectIds;
  final Map<String, dynamic> statsSnapshot;

  Company({
    required this.id,
    required this.name,
    this.description = '',
    this.projectIds = const [],
    this.statsSnapshot = const {
      'totalProgressPercentage': 0.0,
      'totalTasks': 0,
      'completedTasks': 0,
      'overallStatus': 'Active',
    },
  });

  Company copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? projectIds,
    Map<String, dynamic>? statsSnapshot,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      projectIds: projectIds ?? this.projectIds,
      statsSnapshot: statsSnapshot ?? this.statsSnapshot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'projectIds': projectIds,
      'statsSnapshot': statsSnapshot,
    };
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      projectIds: List<String>.from(json['projectIds'] ?? []),
      statsSnapshot: Map<String, dynamic>.from(json['statsSnapshot'] ?? {}),
    );
  }
}
