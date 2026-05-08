import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class GuidelinesScreen extends StatefulWidget {
  const GuidelinesScreen({super.key});

  @override
  State<GuidelinesScreen> createState() => _GuidelinesScreenState();
}

class _GuidelinesScreenState extends State<GuidelinesScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _nodes = [
    {
      'title': 'Company Root',
      'icon': IconsaxPlusBold.building_3,
      'color': const Color(0xFFF59E0B),
      'desc': 'Define the top-level parent enterprises. Manage global billing, overarching access roles, and overarching identities.',
    },
    {
      'title': 'Projects Hub',
      'icon': IconsaxPlusBold.folder_open,
      'color': const Color(0xFF3B82F6),
      'desc': 'Within companies, create targeted projects. Organize workspaces, bring in specialized teams, and map out project scopes.',
    },
    {
      'title': 'Strategic Plan',
      'icon': IconsaxPlusBold.map_1,
      'color': const Color(0xFF10B981),
      'desc': 'Outline the vision. Set major milestones, timelines, and dependencies before breaking work down into daily operations.',
    },
    {
      'title': 'Central Console',
      'icon': IconsaxPlusBold.cpu_setting,
      'color': const Color(0xFF8B5CF6),
      'desc': 'The beating heart. Assign leaders, calculate resource margins, and monitor cross-project performance in real-time.',
    },
    {
      'title': 'Task Execution',
      'icon': IconsaxPlusBold.task_square,
      'color': const Color(0xFFEC4899),
      'desc': 'The ground level. Execute granular tasks, trigger immediate notifications, and close objectives to move the plan forward.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background colors
    final bgColors = isDark 
        ? [const Color(0xFF0F172A), const Color(0xFF020617)]
        : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('3D System Workflow', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Dynamic 3D depth background
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bgColors)),
          ),
          
          // Floating background particles
          Positioned(
             top: -50, right: -50,
             child: _GlowingOrb(color: Colors.blueAccent.withOpacity(0.15), size: 300),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 30, duration: 4000.ms),
          
          Positioned(
             bottom: 100, left: -100,
             child: _GlowingOrb(color: Colors.purpleAccent.withOpacity(0.15), size: 350),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(begin: 0, end: 40, duration: 5000.ms),

          // 3D Scrolling List
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 40,
              bottom: 100,
              left: 20,
              right: 20,
            ),
            itemCount: _nodes.length,
            itemBuilder: (context, index) {
              // Calculate 3D Parallax & Rotation effect
              final itemPositionOffset = index * 180.0; // Approximate height per item
              final distance = _scrollOffset - itemPositionOffset;
              final normalizedDistance = (distance / 400).clamp(-1.0, 1.0);
              
              // 3D Matrix Transformation
              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateX(-normalizedDistance * 0.4) // tilt forward/backward based on scroll
                ..scale(1.0 - (normalizedDistance.abs() * 0.1)) // slightly shrink cards as they move away
                ..translate(0.0, normalizedDistance * 30); // slight parallax Y shift

              return Transform(
                transform: transform,
                alignment: FractionalOffset.center,
                child: _build3DNodeCard(
                  index: index,
                  data: _nodes[index],
                  isDark: isDark,
                  isLast: index == _nodes.length - 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _build3DNodeCard({required int index, required Map<String, dynamic> data, required bool isDark, required bool isLast}) {
    final title = data['title'] as String;
    final desc = data['desc'] as String;
    final color = data['color'] as Color;
    final icon = data['icon'] as IconData;

    final cardBg = isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.6);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

    return Column(
      children: [
        Container(
          height: 140, // Fixed height to maintain 3D uniformity
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 3D Floating Icon Element
              Positioned(
                right: -20,
                top: -20,
                child: Icon(icon, size: 140, color: color.withOpacity(isDark ? 0.1 : 0.05)),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Glowing Step Indicator
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.3), blurRadius: 12),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.05, duration: 2.seconds),
                    
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 150).ms).slideX(begin: 0.1),
        
        // 3D Connecting Line (Workflow Flow)
        if (!isLast)
          Container(
            height: 40,
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, _nodes[index + 1]['color'] as Color],
              ),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
              ]
            ),
          ).animate().fadeIn(delay: ((index * 150) + 100).ms),
      ],
    );
  }
}

// Helper Widget for ambient 3D glowing background
class _GlowingOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowingOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
           BoxShadow(
             color: color,
             blurRadius: 100,
             spreadRadius: 50,
           )
        ]
      ),
    );
  }
}
