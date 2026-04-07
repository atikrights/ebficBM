class Console {
  final String id;
  final String name;
  final String planId;
  final List<String> taskIds;
  final Map<String, dynamic> statsSnapshot;

  Console({
    required this.id,
    required this.name,
    required this.planId,
    this.taskIds = const [],
    this.statsSnapshot = const {
      'totalProgressPercentage': 0.0,
      'totalTasks': 0,
      'completedTasks': 0,
      'overallStatus': 'Not Started',
    },
  });

  Console copyWith({
    String? id,
    String? name,
    String? planId,
    List<String>? taskIds,
    Map<String, dynamic>? statsSnapshot,
  }) {
    return Console(
      id: id ?? this.id,
      name: name ?? this.name,
      planId: planId ?? this.planId,
      taskIds: taskIds ?? this.taskIds,
      statsSnapshot: statsSnapshot ?? this.statsSnapshot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'planId': planId,
      'taskIds': taskIds,
      'statsSnapshot': statsSnapshot,
    };
  }

  factory Console.fromJson(Map<String, dynamic> json) {
    return Console(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      planId: json['planId'] ?? '',
      taskIds: List<String>.from(json['taskIds'] ?? []),
      statsSnapshot: Map<String, dynamic>.from(json['statsSnapshot'] ?? {}),
    );
  }
}
