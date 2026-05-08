class AppTask {
  final String id;
  final String title;
  final String description;
  final String consoleId;
  final bool isCompleted;
  final double progress;

  AppTask({
    required this.id,
    required this.title,
    required this.consoleId,
    this.description = '',
    this.isCompleted = false,
    this.progress = 0.0,
  });

  AppTask copyWith({
    String? id,
    String? title,
    String? description,
    String? consoleId,
    bool? isCompleted,
    double? progress,
  }) {
    return AppTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      consoleId: consoleId ?? this.consoleId,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'consoleId': consoleId,
      'isCompleted': isCompleted,
      'progress': progress,
    };
  }

  factory AppTask.fromJson(Map<String, dynamic> json) {
    return AppTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      consoleId: json['consoleId'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      progress: (json['progress'] ?? 0.0).toDouble(),
    );
  }
}
