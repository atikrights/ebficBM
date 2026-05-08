import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/features/projects/providers/project_provider.dart';
import 'package:ebficbm/features/companies/providers/company_provider.dart';
import 'package:ebficbm/features/projects/models/project.dart';
import 'package:ebficbm/features/projects/screens/project_workspace_screen.dart';
import 'package:ebficbm/features/tasks/providers/task_provider.dart';
import 'package:ebficbm/features/tasks/models/system_task.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Hold', 'Complete'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Filter logic matching EBM Central ───────────────────────────────
  List<Project> _applyFilter(List<Project> all) {
    List<Project> filtered = all;

    // Status filter
    if (_selectedFilter == 'Active') {
      filtered = filtered.where((p) => p.status == ProjectStatus.inProgress).toList();
    } else if (_selectedFilter == 'Hold') {
      filtered = filtered.where((p) => p.status == ProjectStatus.delayed).toList();
    } else if (_selectedFilter == 'Complete') {
      filtered = filtered.where((p) => p.status == ProjectStatus.completed).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(q) || 
                        p.pid.toLowerCase().contains(q) ||
                        (p.companyName ?? '').toLowerCase().contains(q) ||
                        (p.companyId ?? '').toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  int _countForFilter(List<Project> all, String filter) {
    if (filter == 'All') return all.length;
    if (filter == 'Active') return all.where((p) => p.status == ProjectStatus.inProgress).length;
    if (filter == 'Hold') return all.where((p) => p.status == ProjectStatus.delayed).length;
    if (filter == 'Complete') return all.where((p) => p.status == ProjectStatus.completed).length;
    return 0;
  }

  void _showCreateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    bool isCreating = false;
    Project? createdProject;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (createdProject != null) {
            return _buildSuccessDialog(ctx, createdProject!, isDark);
          }

          return AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Deploy Project', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: isDark ? Colors.white : Colors.black87)),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx), 
                          icon: Icon(Icons.close, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildFieldLabel('PROJECT NAME', isDark),
                    const SizedBox(height: 8),
                    _buildDialogField(nameCtrl, 'Enter project name...', IconsaxPlusLinear.edit_2, isDark),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isCreating ? null : () async {
                          if (nameCtrl.text.isNotEmpty) {
                            setDialogState(() => isCreating = true);
                            try {
                              final cp = Provider.of<CompanyProvider>(context, listen: false);
                              final companyId = cp.selectedCompany?.id ?? (cp.companies.isNotEmpty ? cp.companies.first.id : null);
                              
                              final projectProv = Provider.of<ProjectProvider>(context, listen: false);
                              final resultId = await projectProv.deployProject(
                                name: nameCtrl.text.trim(),
                                companyId: companyId,
                              );
                              
                              // Since deployProject currently returns String? (ID or error, actually let's just fetch the created project or refetch)
                              // Wait, ProjectProvider in EBM app uses `deployProject` which returns `Future<String?>`.
                              // If successful, we can get it from allProjects.
                              if (resultId != null) {
                                final proj = projectProv.allProjects.firstWhere(
                                  (p) => p.id == resultId, 
                                  orElse: () => Project(
                                    id: resultId, pid: 'NEW', name: nameCtrl.text.trim(), description: '', startDate: DateTime.now(), estimatedEndDate: DateTime.now(), brandColor: Colors.blue
                                  )
                                );
                                setDialogState(() {
                                  createdProject = proj;
                                  isCreating = false;
                                });
                              } else {
                                setDialogState(() => isCreating = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to create project.'), backgroundColor: Colors.red),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isCreating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: isCreating 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('CREATE PROJECT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessDialog(BuildContext context, Project project, bool isDark) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(IconsaxPlusBold.tick_circle, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Successfully Created', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Project "${project.name}" is now live.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
            const SizedBox(height: 32),
            _buildFieldLabel('PROJECT PID (CLICK TO COPY)', isDark),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: project.pid));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PID Copied to Clipboard')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(project.pid, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'monospace', letterSpacing: 1)),
                    const SizedBox(width: 12),
                    const Icon(IconsaxPlusLinear.copy, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: isDark ? Colors.white38 : Colors.black54,
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon, bool isDark) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
          prefixIcon: Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final allProjects = projectProvider.allProjects;
        final filtered = _applyFilter(allProjects);
        final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);

        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 7), // Exact 7px top space
                  _buildHeader(isDark),
                  _buildFilterBar(allProjects, isDark),
                  const SizedBox(height: 12),
                  // ── Content ─────────────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(isDark)
                        : _buildProjectList(context, filtered, isDark),
                  ),
                ],
              ),
            ),
            // Floating Action Button
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showCreateDialog(context),
                backgroundColor: AppColors.primary,
                elevation: 2,
                icon: const Icon(IconsaxPlusLinear.add_circle, color: Colors.white, size: 18),
                label: const Text(
                  'Create',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        );

      },
    );
  }

  // ─── HEADER (Search + filter/draft icons) ─────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Search projects, ID...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    IconsaxPlusLinear.search_normal,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildActionButton(IconsaxPlusLinear.filter, isDark),
          const SizedBox(width: 6),
          _buildActionButton(IconsaxPlusLinear.document_text, isDark),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black87),
    );
  }

  // ─── FILTER TABS (All / Active / Hold / Complete) ───────────────────────
  Widget _buildFilterBar(List<Project> allProjects, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            final count = _countForFilter(allProjects, filter);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedFilter = filter),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              IconsaxPlusLinear.folder,
              size: 64,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Projects Registered',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROJECT LIST ──────────────────────────────────────────────────────
  Widget _buildProjectList(BuildContext context, List<Project> projects, bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 100), // High density margin
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _ProjectListItem(
          project: projects[index],
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProjectWorkspaceScreen(projectId: projects[index].id)),
          ),
        );
      },
    );
  }
}

// ─── PROJECT LIST ITEM (CLONED FROM EBM CENTRAL) ─────────────────────────
class _ProjectListItem extends StatefulWidget {
  final Project project;
  final bool isDark;
  final VoidCallback onTap;

  const _ProjectListItem({
    required this.project,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ProjectListItem> createState() => _ProjectListItemState();
}

class _ProjectListItemState extends State<_ProjectListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.project.status);
    final budgetProgress = widget.project.totalBudget > 0
        ? (widget.project.consumedBudget / widget.project.totalBudget).clamp(0.0, 1.0)
        : 0.0;

    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // 4px vertical gap (2px top + 2px bottom)
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8), // More rounded for premium feel
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : 14,
              vertical: isDesktop ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? (_isHovered ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.03))
                  : (_isHovered ? statusColor.withOpacity(0.04) : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered 
                    ? statusColor.withOpacity(0.5) 
                    : (widget.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                width: _isHovered ? 1.0 : 0.8,
              ),
              boxShadow: widget.isDark ? [] : [
                if (_isHovered)
                  BoxShadow(
                    color: statusColor.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: isDesktop
                ? _buildDesktopLayout(statusColor, budgetProgress)
                : _buildMobileLayout(statusColor, budgetProgress),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Color statusColor, double budgetProgress) {
    final tp = Provider.of<TaskProvider>(context);
    final linkedTasks = tp.allTasks.where((t) => widget.project.taskIds.contains(t.id)).toList();
    final taskProgress = linkedTasks.isEmpty ? 0.0 : linkedTasks.where((t) => t.status == TaskStatus.done).length / linkedTasks.length;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              _buildProjectIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15, // Slightly larger
                              fontWeight: FontWeight.w800,
                              color: widget.isDark ? Colors.white.withOpacity(0.95) : AppColors.textDark,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (widget.project.status == ProjectStatus.draft)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(IconsaxPlusBold.edit_2, size: 10, color: Colors.orangeAccent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildPidCopy(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BUDGET & TASKS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: widget.isDark ? Colors.white38 : Colors.black38)),
                    Text('${(taskProgress * 100).toInt()}% | \$${NumberFormat.compact().format(widget.project.consumedBudget)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white70 : Colors.black87)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: taskProgress,
                    minHeight: 4,
                    backgroundColor: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budgetProgress,
                    minHeight: 4,
                    backgroundColor: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildCompanyInfo(),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: _statusBadge(widget.project.status, statusColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _showDraftDialog(context, widget.project),
                icon: Icon(IconsaxPlusLinear.document_favorite, size: 18, color: widget.isDark ? Colors.white38 : Colors.black38),
                tooltip: 'Move to Draft',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: widget.onTap,
                icon: Icon(IconsaxPlusLinear.eye, size: 18, color: widget.isDark ? Colors.white38 : Colors.black38),
                tooltip: 'Visit Project',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(IconsaxPlusLinear.arrow_right_3, size: 18, color: widget.isDark ? Colors.white24 : Colors.black26),
                onPressed: widget.onTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Color statusColor, double budgetProgress) {
    final tp = Provider.of<TaskProvider>(context);
    final linkedTasks = tp.allTasks.where((t) => widget.project.taskIds.contains(t.id)).toList();
    final taskProgress = linkedTasks.isEmpty ? 0.0 : linkedTasks.where((t) => t.status == TaskStatus.done).length / linkedTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildProjectIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: widget.isDark ? Colors.white.withOpacity(0.95) : AppColors.textDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildPidCopy(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _statusBadge(widget.project.status, statusColor),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BUDGET & TASKS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: widget.isDark ? Colors.white38 : Colors.black45)),
                Text('\$${NumberFormat.compact().format(widget.project.consumedBudget)} / \$${NumberFormat.compact().format(widget.project.totalBudget)}', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white70 : AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: taskProgress,
                minHeight: 3,
                backgroundColor: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budgetProgress,
                minHeight: 3,
                backgroundColor: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCompanyInfo(),
            Row(
              children: [
                IconButton(
                  onPressed: () => _showDraftDialog(context, widget.project),
                  icon: Icon(IconsaxPlusLinear.document_favorite, size: 18, color: widget.isDark ? Colors.white38 : Colors.black38),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onTap,
                  icon: Icon(IconsaxPlusLinear.eye, size: 18, color: widget.isDark ? Colors.white38 : Colors.black38),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onTap,
                  icon: Icon(IconsaxPlusLinear.arrow_right_3, size: 18, color: widget.isDark ? Colors.white38 : Colors.black38),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: widget.project.brandColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(IconsaxPlusBold.folder, color: widget.project.brandColor, size: 20),
      ),
    );
  }

  Widget _buildPidCopy() {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.project.pid));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PID Copied: ${widget.project.pid}'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.project.pid,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
          ),
          const SizedBox(width: 4),
          const Icon(IconsaxPlusLinear.copy, size: 10, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconsaxPlusLinear.shop, size: 12, color: widget.isDark ? Colors.white38 : Colors.black45),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.project.companyName ?? 'Internal Project',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white54 : Colors.black54,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ProjectStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 8, 
          fontWeight: FontWeight.w900, 
          color: color, 
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress: return const Color(0xFF22C55E);
      case ProjectStatus.completed:  return const Color(0xFF6366F1);
      case ProjectStatus.delayed:    return const Color(0xFFF59E0B);
      case ProjectStatus.archived:   return Colors.grey;
      case ProjectStatus.draft:      return Colors.orangeAccent;
      default:                        return const Color(0xFF3B82F6);
    }
  }

  void _showDraftDialog(BuildContext context, Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(IconsaxPlusBold.edit_2, size: 32, color: Colors.orangeAccent),
              ),
              const SizedBox(height: 16),
              const Text('Move to Draft?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'This project will be private and only visible to administrators.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${project.name} moved to drafts'), backgroundColor: Colors.orangeAccent),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Move to Draft', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn(),
    );
  }
}
