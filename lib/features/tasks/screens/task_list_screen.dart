import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'package:ebficbm/features/tasks/models/system_task.dart';
import 'package:ebficbm/features/tasks/providers/task_provider.dart';
import 'package:ebficbm/features/projects/providers/project_provider.dart';
import 'package:ebficbm/features/projects/models/project.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ebficbm/features/tasks/screens/task_workspace_screen.dart';
import 'package:ebficbm/features/companies/providers/company_provider.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedTaskIds = {};
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, barrierColor: Colors.black.withOpacity(0.7), builder: (ctx) => _CreateTaskDialog());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final provider = context.watch<TaskProvider>();

    final activeTasks = provider.allTasks.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) || t.taskNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    final draftTasks = provider.draftTasks.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) || t.taskNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isDesktop 
        ? FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context),
            backgroundColor: AppColors.primary,
            elevation: 0,
            icon: const Icon(IconsaxPlusBold.add, color: Colors.white),
            label: const Text('Create Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : FloatingActionButton(
            onPressed: () => _showCreateDialog(context),
            backgroundColor: AppColors.primary,
            elevation: 0,
            child: const Icon(IconsaxPlusBold.add, color: Colors.white),
          ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 7), // Exact 7px top space
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LINE 1: Search + Filter Icon ──
                Padding(
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
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                              prefixIcon: Icon(IconsaxPlusLinear.search_normal_1, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildHeaderButton(IconsaxPlusLinear.filter, () => _showFilterPopup(context), isDark, AppColors.primary, isDesktop),
                    ],
                  ),
                ),

                // Filters (Tabs like Projects page)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterTab('Active', 0, isDark, AppColors.primary, activeTasks.length),
                        _buildFilterTab('Archived', 1, isDark, AppColors.primary, draftTasks.length),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

          // ── Multi-Action Bar ──
          if (_selectedTaskIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
              child: Row(children: [
                Text('${_selectedTaskIds.length} Selected', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                _bulkAction(IconsaxPlusLinear.document_download, 'Export ZIP', AppColors.primary, () {
                  final selectedTasks = provider.allTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
                  provider.generateMultiTaskZip(selectedTasks);
                  setState(() => _selectedTaskIds.clear());
                }),
                const SizedBox(width: 12),
                _bulkAction(IconsaxPlusLinear.trash, _tabCtrl.index == 0 ? 'To Draft' : 'Delete', AppColors.error, () {
                  for (final id in _selectedTaskIds) {
                    if (_tabCtrl.index == 0) {
                      provider.moveToDraft(id);
                    } else {
                      provider.deletePermanently(id, true);
                    }
                  }
                  setState(() => _selectedTaskIds.clear());
                }),
                const SizedBox(width: 12),
                IconButton(onPressed: () => setState(() => _selectedTaskIds.clear()), icon: const Icon(IconsaxPlusLinear.close_circle, size: 18, color: Colors.grey)),
              ]),
            ).animate().slideY(begin: 1, end: 0).fadeIn(),

          Expanded(
            child: IndexedStack(
              index: _tabCtrl.index,
              children: [
                activeTasks.isEmpty ? _buildEmpty(isDark, false) : _buildTaskList(activeTasks, isDark, provider, isDraft: false),
                draftTasks.isEmpty ? _buildEmpty(isDark, true) : _buildTaskList(draftTasks, isDark, provider, isDraft: true),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFilterTab(String label, int index, bool isDark, Color primaryColor, int count) {
    final isSelected = _tabCtrl.index == index;
    final bg = isSelected ? primaryColor : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02));
    final textColor = isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.black38);

    return GestureDetector(
      onTap: () => setState(() => _tabCtrl.index = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap, bool isDark, Color primaryColor, bool isDesktop) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black87),
            if (isDesktop) ...[
              const SizedBox(width: 8),
              Text('Filter', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterPopup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter system is synchronizing...'), duration: Duration(seconds: 1)),
    );
  }

  Widget _bulkAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildTaskList(List<SystemTask> tasks, bool isDark, TaskProvider tp, {required bool isDraft}) {
    if (tasks.isEmpty) return _buildEmpty(isDark, isDraft);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = _selectedTaskIds.contains(task.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) _selectedTaskIds.add(task.id);
                    else _selectedTaskIds.remove(task.id);
                  });
                },
              ),
              Expanded(child: _buildTaskRow(context, task, isDark, isDraft, tp)),
            ],
          ),
        ).animate().fade(delay: (20 * index).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildEmpty(bool isDark, bool isDraft) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isDraft ? IconsaxPlusLinear.trash : IconsaxPlusLinear.setting_4, size: 64, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 16),
          Text(isDraft ? 'No nodes in drafts' : 'Console is clear. No active nodes.', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context, SystemTask task, bool isDark, bool isDraft, TaskProvider tp) {
    return InkWell(
      onTap: () {
        if (!isDraft) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TaskWorkspaceScreen(taskId: task.id)));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 16,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDraft ? AppColors.error : AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(isDraft ? IconsaxPlusLinear.trash : IconsaxPlusLinear.task_square, color: isDraft ? AppColors.error : AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark, fontSize: 15), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: task.taskNumber));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('UID Copied: ${task.taskNumber}'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(task.taskNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
                              const SizedBox(width: 4),
                              const Icon(IconsaxPlusLinear.copy, size: 10, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Creator: ${task.author} • Assignee: ${task.assignee}',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (isDraft)
              IconButton(onPressed: () => tp.restoreFromDraft(task.id), icon: const Icon(IconsaxPlusLinear.rotate_left, size: 20, color: AppColors.success))
            else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('\$${task.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(task.status.name.toUpperCase(), style: TextStyle(fontSize: 9, color: _getStatusColor(task.status), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo: return Colors.amber;
      case TaskStatus.inProgress: return const Color(0xFF818CF8);
      case TaskStatus.review: return AppColors.warning;
      case TaskStatus.done: 
      case TaskStatus.completed: return AppColors.success;
      default: return AppColors.primary;
    }
  }
}

// ── Quick Create Dialog Interface ──
class _CreateTaskDialog extends StatefulWidget {
  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _iCodeCtrl = TextEditingController();
  
  Project? _selectedProject;
  Plan? _selectedPlan;
  
  Project? _matchedProject;
  Plan? _matchedPlan;

  late final AnimationController _anim;
  late final Animation<double> _scaleAnim;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _anim.forward();

    _iCodeCtrl.addListener(_onICodeChanged);
  }

  void _onICodeChanged() {
    final code = _iCodeCtrl.text.trim().toLowerCase();
    
    // Clear matched if user types something else
    if (_matchedPlan != null && _matchedPlan!.icode.toLowerCase() != code) {
      setState(() {
        _matchedPlan = null;
        _matchedProject = null;
        _selectedPlan = null;
        _selectedProject = null;
      });
    }

    if (code.isEmpty) return;
    
    final pp = Provider.of<ProjectProvider>(context, listen: false);
    for (var project in pp.allProjects) {
      for (var plan in project.plans) {
        if (plan.icode.toLowerCase() == code) {
          if (_matchedPlan?.id != plan.id) {
            setState(() {
              _matchedProject = project;
              _matchedPlan = plan;
              // Automatically select and link the plan and project
              _selectedProject = project;
              _selectedPlan = plan;
            });
          }
          return;
        }
      }
    }
  }

  void _attachMatchedPlan() {
    if (_matchedPlan != null && _matchedProject != null) {
      setState(() {
        _selectedProject = _matchedProject;
        _selectedPlan = _matchedPlan;
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _iCodeCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _isCreating = true);

    final tp = Provider.of<TaskProvider>(context, listen: false);
    final pp = Provider.of<ProjectProvider>(context, listen: false);
    final cp = Provider.of<CompanyProvider>(context, listen: false);

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 10000).toRadixString(16).toUpperCase().padLeft(4, '0');
    final newNumber = 'TSK-${(tp.allTasks.length + 1).toString().padLeft(3, '0')}-$randomSuffix';

    final newTask = SystemTask(
      id: newId,
      taskNumber: newNumber,
      title: title,
      author: 'Super Admin',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      planId: _selectedPlan?.id,
      projectId: _selectedProject?.id,
    );

    final companyId = _selectedProject?.companyId ?? cp.selectedCompany?.id ?? (cp.companies.isNotEmpty ? cp.companies.first.id : '1');

    final createdTask = await tp.addTask(newTask, companyId: companyId);

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    
    Navigator.pop(context);
    
    final finalTaskId = createdTask?.id ?? newId;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskWorkspaceScreen(taskId: finalTaskId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            margin: EdgeInsets.all(isMobile ? 16 : 24),
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161622) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20)),
              ],
              border: isDark ? Border.all(color: Colors.white10) : null,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(IconsaxPlusLinear.task_square, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Create New Task',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _titleCtrl,
                    autofocus: true,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      labelStyle: TextStyle(color: subColor, fontSize: 12),
                      hintText: 'e.g. Integrate Analytics Module',
                      hintStyle: TextStyle(color: subColor.withOpacity(0.5), fontSize: 12),
                      prefixIcon: const Icon(IconsaxPlusLinear.edit, size: 16, color: AppColors.primary),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
              
                  Consumer<ProjectProvider>(
                    builder: (context, pp, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _iCodeCtrl,
                          style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Smart Link (Plan iCode)',
                            labelStyle: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.normal),
                            hintText: 'Paste PLN-001 or browse...',
                            hintStyle: TextStyle(color: subColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.normal),
                            prefixIcon: const Icon(IconsaxPlusLinear.scan_barcode, size: 16, color: AppColors.primary),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            isDense: true,
                            suffixIcon: _matchedPlan != null && _selectedPlan?.id != _matchedPlan?.id
                                ? IconButton(
                                    icon: const Icon(IconsaxPlusBold.tick_circle, color: AppColors.success),
                                    onPressed: _attachMatchedPlan,
                                  )
                                : (_selectedPlan != null && _selectedPlan?.id == _matchedPlan?.id)
                                    ? IconButton(
                                        icon: const Icon(IconsaxPlusLinear.close_circle, color: AppColors.error),
                                        onPressed: () {
                                          setState(() {
                                            _iCodeCtrl.clear();
                                            _matchedPlan = null;
                                            _matchedProject = null;
                                            _selectedPlan = null;
                                            _selectedProject = null;
                                          });
                                        },
                                      )
                                    : PopupMenuButton<Map<String, dynamic>>(
                                        icon: const Icon(IconsaxPlusLinear.arrow_down_1, size: 16, color: AppColors.primary),
                                        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (data) {
                                          final Project p = data['project'];
                                          final Plan plan = data['plan'];
                                          _iCodeCtrl.text = plan.icode;
                                          setState(() {
                                            _matchedProject = p;
                                            _matchedPlan = plan;
                                          });
                                          _attachMatchedPlan();
                                        },
                                        itemBuilder: (context) {
                                          List<PopupMenuEntry<Map<String, dynamic>>> items = [];
                                          for (var p in pp.allProjects) {
                                            if (p.plans.isEmpty) continue;
                                            items.add(PopupMenuItem(
                                              enabled: false,
                                              child: Text(p.name, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ));
                                            for (var plan in p.plans) {
                                              items.add(PopupMenuItem(
                                                value: {'project': p, 'plan': plan},
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 8.0),
                                                  child: Text('${plan.title} (${plan.icode})', style: TextStyle(color: textColor, fontSize: 12)),
                                                ),
                                              ));
                                            }
                                          }
                                          if (items.isEmpty) {
                                            items.add(const PopupMenuItem(enabled: false, child: Text('No plans available')));
                                          }
                                          return items;
                                        },
                                      ),
                          ),
                        ),
                        
                        if (_selectedPlan != null && _selectedProject != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.success.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(IconsaxPlusBold.tick_circle, color: AppColors.success, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11),
                                      children: [
                                        const TextSpan(text: 'Attached to '),
                                        TextSpan(text: '${_selectedPlan!.title} Console', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                                        TextSpan(text: ' in ${_selectedProject!.name}.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                        ] else if (_matchedPlan != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(IconsaxPlusBold.info_circle, color: AppColors.warning, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Click the tick icon to attach to ${_matchedPlan!.title}.',
                                    style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 200.ms),
                        ],
                      ],
                    ),
                  ),
              
                  const SizedBox(height: 24),
              
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Cancel', style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isCreating ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isCreating 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

