import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/enums/entity_level.dart';
import '../../../core/providers/analysis_engine.dart';

class UnifiedAnalysisScreen extends StatefulWidget {
  final EntityLevel level;
  final String entityId;

  const UnifiedAnalysisScreen({
    super.key,
    required this.level,
    required this.entityId,
  });

  @override
  State<UnifiedAnalysisScreen> createState() => _UnifiedAnalysisScreenState();
}

class _UnifiedAnalysisScreenState extends State<UnifiedAnalysisScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisEngine>(
      builder: (context, engine, child) {
        String name = 'Unknown';
        Map<String, dynamic> stats = {
           'totalProgressPercentage': 0.0,
           'totalTasks': 0,
           'completedTasks': 0,
           'overallStatus': 'N/A'
        };

        if (widget.level == EntityLevel.company) {
          final data = engine.getCompany(widget.entityId);
          if (data != null) {
            name = data.name;
            stats = data.statsSnapshot;
          }
        } else if (widget.level == EntityLevel.project) {
          final data = engine.getProject(widget.entityId);
          if (data != null) {
            name = data.name;
            stats = data.statsSnapshot;
          }
        }

        final progressDouble = stats['totalProgressPercentage'] as double? ?? 0.0;
        final int totalTasks = stats['totalTasks'] as int? ?? 0;
        final int completedTasks = stats['completedTasks'] as int? ?? 0;
        final String status = stats['overallStatus'] as String? ?? '-';

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Deep enterprise dark
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '${widget.level.name.toUpperCase()} ANALYSIS',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time Analytics Dashboard',
                    style: TextStyle(
                      color: Colors.blueAccent.shade100,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Progress Chart Area
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: progressDouble),
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 16,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getProgressColor(value),
                                ),
                              );
                            },
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(progressDouble * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              status,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                           title: 'Total Tasks',
                           value: totalTasks.toString(),
                           icon: Icons.task_alt,
                           gradientColors: [Colors.blue.shade800, Colors.blue.shade500],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                           title: 'Completed',
                           value: completedTasks.toString(),
                           icon: Icons.check_circle_outline,
                           gradientColors: [Colors.green.shade800, Colors.green.shade500],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Additional Insights Area based on Level
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.insights, color: Colors.amberAccent),
                            const SizedBox(width: 12),
                            const Text(
                              'AI Insights',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getInsightText(widget.level, progressDouble),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            height: 1.6,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.greenAccent;
    if (progress >= 0.4) return Colors.blueAccent;
    return Colors.orangeAccent;
  }

  String _getInsightText(EntityLevel level, double progress) {
    if (progress == 0.0) return 'Operations have not yet started. Please assign tasks to initiate progress tracking.';
    if (progress == 1.0) return 'Excellent work! All milestones and tasks for this ${level.name} have been fully achieved.';
    if (progress > 0.7) return 'Operations are running smoothly. You are nearing completion with high efficiency.';
    return 'Execution is in progress. Identify any bottlenecks early to maintain the timeline for this ${level.name}.';
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required List<Color> gradientColors}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientColors[0].withOpacity(0.3), gradientColors[1].withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gradientColors[1].withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gradientColors[1], size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
