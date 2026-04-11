import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/features/projects/providers/project_provider.dart';
import 'package:ebficbm/features/projects/screens/project_workspace_screen.dart';
import 'package:ebficbm/features/tasks/models/system_task.dart';
import 'package:ebficbm/features/tasks/providers/task_provider.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  void _showCreateDialog(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(IconsaxPlusLinear.folder_add, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('New Master Project', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18)),
        ]),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Project Name',
            hintText: 'e.g. Infrastructure Hub',
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                Provider.of<ProjectProvider>(context, listen: false).deployProject(titleCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Strategic Registry Deployed Successfully!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Deploy Project'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          final projects = projectProvider.allProjects;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, textColor, isMobile, isDark),
              const SizedBox(height: 16),
              _buildTabs(isMobile, isDark, projectProvider),
              const SizedBox(height: 16),
              Expanded(child: _buildProjectTable(context, isDark, textColor, isMobile, projects)),
            ],
          );
        }
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, bool isMobile, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Projects Registry', style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: textColor)),
        ElevatedButton.icon(
          onPressed: () => _showCreateDialog(context, isDark),
          icon: const Icon(IconsaxPlusLinear.add, size: 18),
          label: Text(isMobile ? 'New' : 'Project'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isMobile, bool isDark, ProjectProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(title: 'Active Network', count: provider.allProjects.length, isSelected: true),
          const SizedBox(width: 8),
          _TabItem(title: 'Completed', count: 0, isSelected: false),
          const SizedBox(width: 8),
          _TabItem(title: 'On Hold', count: 0, isSelected: false),
        ],
      ),
    );
  }

  Widget _buildProjectTable(BuildContext context, bool isDark, Color textColor, bool isMobile, List<dynamic> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconsaxPlusLinear.folder_add, size: 80, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 24),
            Text('No Projects Registered', style: TextStyle(fontSize: 18, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context, isDark),
              icon: const Icon(IconsaxPlusLinear.add),
              label: const Text('Initialize First Project'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final proj = projects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectWorkspaceScreen(projectId: proj.id))),
            onLongPress: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  title: const Text('Delete Strategic Registry?'),
                  content: Text('This action will permanently purge "${proj.name}" and all linked deployment logs. This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProjectProvider>().deleteProject(proj.id);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                      child: const Text('Purge Permanently'),
                    ),
                  ],
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: GlassContainer(
              blur: 5.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: proj.brandColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(IconsaxPlusLinear.folder, color: proj.brandColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(proj.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13.5), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: proj.pid));
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('PID Copied: ${proj.pid}'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                  margin: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ));
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(proj.pid, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    const SizedBox(width: 4),
                                    const Icon(IconsaxPlusLinear.copy, size: 9, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Consumer<TaskProvider>(
                        builder: (context, tp, _) {
                          final linked = tp.allTasks.where((t) => proj.taskIds.contains(t.id));
                          final progress = linked.isEmpty ? 0.0 : linked.where((t) => t.status == TaskStatus.done).length / linked.length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tracker', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text('${(progress * 100).toInt()}% Done', style: const TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Financial Limit', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('\$${proj.consumedBudget.toStringAsFixed(0)} / \$${proj.totalBudget.toStringAsFixed(0)}', style: TextStyle(color: proj.consumedBudget > proj.totalBudget * 0.9 ? AppColors.error : textColor, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(IconsaxPlusLinear.arrow_right_3, color: isDark ? Colors.white24 : Colors.black26, size: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final int count;
  final bool isSelected;
  const _TabItem({required this.title, required this.count, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.grey[200]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54), fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(count.toString(), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black))),
          ),
        ],
      ),
    );
  }
}
