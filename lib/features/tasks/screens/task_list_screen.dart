import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficBM/core/theme/colors.dart';
import 'package:ebficBM/widgets/glass_container.dart';
import 'package:ebficBM/features/tasks/models/system_task.dart';
import 'package:ebficBM/features/tasks/providers/task_provider.dart';
import 'package:ebficBM/features/projects/providers/project_provider.dart';
import 'package:ebficBM/features/projects/models/project.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ebficBM/features/tasks/screens/task_workspace_screen.dart';

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

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Search ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                    decoration: InputDecoration(hintText: 'Lookup Console Node (UID or Title)...', hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13), prefixIcon: Icon(IconsaxPlusLinear.search_normal_1, size: 18, color: isDark ? Colors.white38 : Colors.black38), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(IconsaxPlusLinear.add, size: 18),
                label: Text(isDesktop ? 'New Console Node' : 'New'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white, elevation: 0, padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Tabs ──
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.indigoAccent,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(child: Row(children: [const Icon(IconsaxPlusLinear.task_square, size: 16), const SizedBox(width: 8), const Text('Active'), const SizedBox(width: 4), Text('(${activeTasks.length})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])),
              Tab(child: Row(children: [const Icon(IconsaxPlusLinear.trash, size: 16), const SizedBox(width: 8), const Text('Drafts'), const SizedBox(width: 4), Text('(${draftTasks.length})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])),
            ],
          ),
          const SizedBox(height: 16),

          // ── Multi-Action Bar ──
          if (_selectedTaskIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigoAccent.withOpacity(0.3))),
              child: Row(children: [
                Text('${_selectedTaskIds.length} Selected', style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                _bulkAction(IconsaxPlusLinear.document_download, 'Export ZIP', Colors.indigoAccent, () {
                  final selectedTasks = provider.allTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
                  provider.generateMultiTaskZip(selectedTasks);
                  setState(() => _selectedTaskIds.clear());
                }),
                const SizedBox(width: 12),
                _bulkAction(IconsaxPlusLinear.trash, _tabCtrl.index == 0 ? 'To Draft' : 'Delete', Colors.redAccent, () {
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

          // ── Registry List ──
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildTaskList(activeTasks, isDark, provider, isDraft: false),
                _buildTaskList(draftTasks, isDark, provider, isDraft: true),
              ],
            ),
          ),
        ],
      ),
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
                activeColor: Colors.indigoAccent,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (isDraft ? Colors.redAccent : Colors.indigoAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(isDraft ? IconsaxPlusLinear.trash : IconsaxPlusLinear.task_square, color: isDraft ? Colors.redAccent : Colors.indigoAccent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 13), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: task.taskNumber));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('UID Copied: ${task.taskNumber}'),
                            backgroundColor: Colors.indigoAccent,
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
                              Text(task.taskNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
                              const SizedBox(width: 4),
                              const Icon(IconsaxPlusLinear.copy, size: 10, color: Colors.indigoAccent),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Creator: ${task.author}  |  Assignee: ${task.assignee}',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isDraft)
              IconButton(onPressed: () => tp.restoreFromDraft(task.id), icon: const Icon(IconsaxPlusLinear.rotate_left, size: 18, color: Colors.greenAccent))
            else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${task.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent, fontSize: 14)),
                  Text(task.status.name.toUpperCase(), style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ── Quick Create Dialog Interface ──
class _CreateTaskDialog extends StatefulWidget {
  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  Project? _selectedProject;
  Plan? _selectedPlan;
  late final AnimationController _anim;
  late final Animation<double> _scaleAnim;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _anim.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _isCreating = true);

    final tp = Provider.of<TaskProvider>(context, listen: false);
    final pp = Provider.of<ProjectProvider>(context, listen: false);

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
    );

    tp.addTask(newTask);

    if (_selectedProject != null) {
      pp.linkTaskToProject(_selectedProject!.id, newId);
    }

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskWorkspaceScreen(taskId: newId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(IconsaxPlusLinear.task_square, color: Colors.indigoAccent, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Register Master Task',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: TextStyle(color: subColor),
                    hintText: 'e.g. Integrate Analytics Module',
                    prefixIcon: const Icon(IconsaxPlusLinear.edit, size: 18),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigoAccent)),
                  ),
                ),
                const SizedBox(height: 20),

                Consumer<ProjectProvider>(
                  builder: (context, pp, _) => Column(
                    children: [
                      DropdownButtonFormField<Project?>(
                        value: _selectedProject,
                        dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Link to Project',
                          labelStyle: TextStyle(color: subColor),
                          prefixIcon: const Icon(IconsaxPlusLinear.folder, size: 18),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('No Project Link')),
                          ...pp.allProjects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedProject = val;
                            _selectedPlan = null;
                          });
                        },
                      ),
                      if (_selectedProject != null && _selectedProject!.plans.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Plan?>(
                          value: _selectedPlan,
                          dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Allocate to Plan',
                            labelStyle: TextStyle(color: subColor),
                            prefixIcon: const Icon(IconsaxPlusLinear.hierarchy, size: 18),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Global Project Node')),
                            ..._selectedProject!.plans.map((p) => DropdownMenuItem(value: p, child: Text(p.title))),
                          ],
                          onChanged: (val) => setState(() => _selectedPlan = val),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: subColor)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isCreating ? null : _handleCreate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isCreating 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create & Open Registry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
