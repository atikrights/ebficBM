import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:file_picker/file_picker.dart';
import 'package:ebficbm/features/projects/models/project.dart';
import 'package:ebficbm/features/projects/providers/project_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebficbm/features/tasks/models/system_task.dart';
import 'package:ebficbm/features/tasks/providers/task_provider.dart';
import 'package:ebficbm/core/utils/pdf_generator.dart';
import 'package:ebficbm/features/tasks/screens/task_list_screen.dart';
import 'package:ebficbm/features/tasks/screens/task_workspace_screen.dart';
import 'package:ebficbm/core/services/refresh_service.dart';
import 'package:ebficbm/features/settings/screens/settings_screen.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  final String projectId;

  const ProjectWorkspaceScreen({super.key, required this.projectId});

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  int _selectedIndex = 0;
  Plan? _activePlan; 
  bool _isExporting = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSessionState();
  }

  Future<void> _loadSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_workspace_id', widget.projectId); // Save presence
    final savedIndex = prefs.getInt('workspace_tab_${widget.projectId}');
    if (savedIndex != null && savedIndex < _tabNames.length) {
      if (mounted) setState(() => _selectedIndex = savedIndex);
    }
  }

  Future<void> _clearWorkspacePresence() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_workspace_id');
  }

  Future<void> _saveSessionState(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workspace_tab_${widget.projectId}', index);
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    // Reload providers from storage
    Provider.of<ProjectProvider>(context, listen: false).reload();
    Provider.of<TaskProvider>(context, listen: false).reload();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Strategic Registry Synchronized!'), behavior: SnackBarBehavior.floating)
      );
    }
  }

  final List<String> _tabNames = ['The Radar', 'Overview', 'Blueprint', 'Plans', 'Console Log', 'Financial Ledger', 'Data Vault', 'Settings'];
  final List<IconData> _tabIcons = [
    IconsaxPlusLinear.radar,
    IconsaxPlusLinear.personalcard,
    IconsaxPlusLinear.setting_2,
    IconsaxPlusLinear.task,
    IconsaxPlusLinear.setting_4,
    IconsaxPlusLinear.wallet_1,
    IconsaxPlusLinear.data,
    IconsaxPlusLinear.setting_3,
  ];

  @override
  Widget build(BuildContext context) {
    // Highly optimized project selection to prevent global rebuilds
    final project = context.select<ProjectProvider, Project?>((p) => 
      p.allProjects.isEmpty ? null : p.allProjects.firstWhere((p) => p.id == widget.projectId)
    );

    if (project == null) {
      return const Scaffold(body: Center(child: Text('Workspace closed or project missing.')));
    }

    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: !isLargeScreen
          ? AppBar(
              backgroundColor: project.brandColor.withValues(alpha: 0.1),
              elevation: 0,
              iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
              title: Text(project.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () async {
                  await _clearWorkspacePresence();
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(IconsaxPlusLinear.close_circle),
                tooltip: 'Exit Workspace',
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  icon: const Icon(IconsaxPlusLinear.setting_2),
                  tooltip: 'Configure Blueprint',
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      drawer: !isLargeScreen
          ? Drawer(
              backgroundColor: Colors.transparent,
              child: _buildSidebar(project, isDark, isDrawer: true),
            )
          : null,
      body: SafeArea(
        child: !isLargeScreen
            ? Container(
                margin: const EdgeInsets.all(16),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: _buildTabContent(project, isDark),
                ),
              )
            : Row(
                children: [
                   _buildSidebar(project, isDark),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: _buildTabContent(project, isDark),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSidebar(Project project, bool isDark, {bool isDrawer = false}) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      width: isDrawer ? double.infinity : 260,
      margin: EdgeInsets.all(isDrawer ? 0 : 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: isDrawer ? 0 : 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () async {
                  await _clearWorkspacePresence();
                  if (mounted) Navigator.pop(context);
                },
                icon: Icon(isDrawer ? IconsaxPlusLinear.close_circle : IconsaxPlusLinear.arrow_left, color: textColor),
                tooltip: isDrawer ? 'Close Menu' : 'Exit Workspace',
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: project.brandColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: project.brandColor.withValues(alpha: 0.5)),
                  boxShadow: [BoxShadow(color: project.brandColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(IconsaxPlusLinear.box, color: project.brandColor, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    project.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isSyncing ? null : _triggerSync,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(IconsaxPlusLinear.refresh, size: 16, color: project.brandColor)
                      .animate(target: _isSyncing ? 1 : 0)
                      .rotate(duration: 1.seconds),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Deep Workspace',
              textAlign: TextAlign.center,
              style: TextStyle(color: project.brandColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: List.generate(_tabNames.length, (index) {
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                             setState(() => _selectedIndex = index);
                             _saveSessionState(index);
                             if (isDrawer) {
                               Navigator.pop(context); // Close Drawer
                             }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? project.brandColor.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? project.brandColor.withValues(alpha: 0.3) : Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Icon(_tabIcons[index], color: isSelected ? project.brandColor : (isDark ? Colors.white54 : Colors.black54), size: 18),
                                const SizedBox(width: 12),
                                Text(
                                  _tabNames[index],
                                  style: TextStyle(
                                    color: isSelected ? project.brandColor : (isDark ? Colors.white70 : Colors.black54),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Divider(height: 32, thickness: 0.5),
            ElevatedButton.icon(
              onPressed: () {
                _showGlobalCreateDialog(context, isDark);
              },
              icon: const Icon(IconsaxPlusLinear.add_square, size: 18),
              label: const Text('New Strategic Registry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                foregroundColor: project.brandColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: project.brandColor.withOpacity(0.2))),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _showDeleteConfirm(context, project, isDark);
              },
              icon: const Icon(IconsaxPlusLinear.trash, size: 16, color: AppColors.error),
              label: const Text('Purge Registry', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGlobalCreateDialog(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(IconsaxPlusLinear.folder_add, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('New Strategic Registry', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18)),
        ]),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Registry Title',
            hintText: 'e.g. Life Eve Core',
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
                final newId = context.read<ProjectProvider>().deployProject(titleCtrl.text.trim());
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deployment Sequence Successful!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                
                // Navigate to the new workspace
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProjectWorkspaceScreen(projectId: newId)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Execute Deploy'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Project project, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('Purge Strategic Registry?'),
        content: Text('This action will permanently eradicate "${project.name}" and all linked deployment logs. THIS CANNOT BE REVERSED.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ProjectProvider>().deleteProject(project.id);
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(ctx); // Exit Workspace
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Confirm Eradicate'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Project project, bool isDark) {
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = _buildRadarTab(project, isDark);
        break;
      case 1:
        content = _buildOverviewTab(project, isDark);
        break;
      case 2:
        content = _ProjectSetupForm(project: project);
        break;
      case 3:
        content = _activePlan != null 
          ? _PlanConsoleBoard(
              project: project, 
              plan: _activePlan!,
              onBackPressed: () => setState(() => _activePlan = null),
            )
          : _PlansWorkspace(project: project, onOpenConsole: (p) => setState(() {
              _activePlan = p;
            }));
        break;
      case 4:
        content = _buildConsoleBoard(project, isDark);
        break;
      case 5:
        content = _buildFinancialLedger(project, isDark);
        break;
      case 6:
        content = _buildDataVault(project, isDark);
        break;
      case 7:
        content = SettingsScreen(currentProjectId: project.id);
        break;
      default:
        content = const SizedBox();
    }

    return KeyedSubtree(
      key: ValueKey('${_selectedIndex}_${_activePlan?.id}'),
      child: content,
    );
  }

  Widget _buildOverviewTab(Project project, bool isDark) {
    final color = project.brandColor;
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Project Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : () async {
                    setState(() => _isExporting = true);
                    try {
                      await ProjectExporter.exportToPdf(project);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Certificate Generated!'), behavior: SnackBarBehavior.floating));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⚠️ Export failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent));
                    } finally {
                      if (mounted) setState(() => _isExporting = false);
                    }
                  },
                  icon: _isExporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(IconsaxPlusLinear.document_download, size: 18),
                  label: Text(_isExporting ? 'Generating...' : 'Download Certificate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    shadowColor: color.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Optimized Cover Photo Header
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: project.coverPhotoUrl.isNotEmpty 
                      ? DecorationImage(image: NetworkImage(project.coverPhotoUrl), fit: BoxFit.cover)
                      : null,
                    gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
                  ),
                  child: project.coverPhotoUrl.isEmpty ? const Center(child: Icon(IconsaxPlusLinear.image, color: Colors.white24, size: 48)) : null,
                ),
                Positioned(
                  bottom: isTablet ? -50 : -40,
                  left: isTablet ? 40 : 20,
                  right: isTablet ? 40 : 20, // Added right constraint to prevent unbounded width
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: isTablet ? 120 : 100,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < (project.adminPhotos.isEmpty ? 3 : project.adminPhotos.length); i++)
                              Positioned(
                                left: i * (isTablet ? 40.0 : 30.0),
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : Colors.white, 
                                    shape: BoxShape.circle,
                                    border: Border.all(color: color.withOpacity(0.2), width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: CircleAvatar(
                                    radius: isTablet ? 55 : 45,
                                    backgroundColor: color.withOpacity(0.1),
                                    backgroundImage: project.adminPhotos.length > i ? NetworkImage(project.adminPhotos[i]) : null,
                                    child: project.adminPhotos.length <= i ? Icon(IconsaxPlusLinear.user, color: color, size: 30) : null,
                                  ),
                                ),
                              ),
                             SizedBox(width: ((project.adminPhotos.isEmpty ? 3 : project.adminPhotos.length) * (isTablet ? 40.0 : 30.0)) + (isTablet ? 110 : 90)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(project.name, style: TextStyle(fontSize: isTablet ? 26 : 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              Text(project.pid, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70),
            
            // Re-organized Registry Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 32 : 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconsaxPlusLinear.verify, color: color, size: 24),
                      const SizedBox(width: 12),
                      const Text('OFFICIAL PROJECT REGISTRY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                  
                  // Optimized Grid Layout for Info
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
                    childAspectRatio: isTablet ? 2.2 : 1.6,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    children: [
                      _overviewInfo('CATEGORY', project.category, IconsaxPlusLinear.category, color, isDark),
                      _overviewInfo('START DATE', project.startDate.toString().substring(0, 10), IconsaxPlusLinear.calendar, color, isDark),
                      _overviewInfo('BUDGET LIMIT', '\$${project.totalBudget.toStringAsFixed(0)}', IconsaxPlusLinear.wallet, color, isDark),
                      _overviewInfo('STATUS', project.status.name.toUpperCase(), IconsaxPlusLinear.status, color, isDark),
                      _overviewInfo('WEBSITE', project.website.isEmpty ? 'N/A' : project.website, IconsaxPlusLinear.global, color, isDark),
                      _overviewInfo('CONTACT', project.phoneNumber.isEmpty ? 'N/A' : project.phoneNumber, IconsaxPlusLinear.call, color, isDark),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: color.withOpacity(0.05), border: Border.all(color: color.withOpacity(0.1)), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: Text('STRATEGIC INSPIRATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2))),
                        const SizedBox(height: 16),
                        Text(project.inspirationText.isEmpty ? 'Standard operating protocol is currently guiding this deployment.' : project.inspirationText, 
                        textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: isTablet ? MainAxisAlignment.end : MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(project.managerSignature, style: TextStyle(fontFamily: 'DancingScript', fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                          const SizedBox(height: 4),
                          const Text('Authorized Project Manager', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _overviewInfo(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withOpacity(0.6), size: 16),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 2),
        Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  // --- TAB IMPLEMENTATIONS ---

  Widget _buildRadarTab(Project project, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Strategic Radar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                Text('Interactive Deployment Mapping', style: TextStyle(fontSize: 12, color: project.brandColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Interactive Radar Map View
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: project.brandColor.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _StrategicRadarMap(project: project),
          ),
        ),
        
        const SizedBox(height: 16),
        // Fixed Metric Cards for Mobile/Tablet
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = ResponsiveBreakpoints.of(context).largerThan(MOBILE) 
                ? (constraints.maxWidth - 16) / 2 
                : constraints.maxWidth;
                
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildMetricCard(
                  'System Health', 
                  'Operational',
                  AppColors.success,
                  IconsaxPlusLinear.shield_tick,
                  customWidth: cardWidth,
                ),
                _buildMetricCard(
                  'Deployment Scale', 
                  '${project.plans.length} Nodes Registered',
                  project.brandColor,
                  IconsaxPlusLinear.hierarchy,
                  customWidth: cardWidth,
                ),
              ],
            );
          }
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, dynamic val, Color color, IconData icon, {bool itp = false, Project? project, double? progressVal, double? customWidth}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: customWidth ?? (MediaQuery.of(context).size.width - 32) / (ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 2.5 : 1),
      padding: const EdgeInsets.all(16), // Slightly reduced padding for mobile
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: val is String 
                  ? Text(
                      val, 
                      style: TextStyle(
                        fontSize: ResponsiveBreakpoints.of(context).isMobile ? 18 : 22, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : val,
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 20),
            ],
          ),
          if (itp || progressVal != null) const SizedBox(height: 12),
          if (itp && project != null)
            Consumer<TaskProvider>(builder: (context, tp, _) {
              final linked = tp.allTasks.where((t) => project.taskIds.contains(t.id));
              final p = linked.isEmpty ? 0.0 : linked.where((t) => t.status == TaskStatus.done || t.status == TaskStatus.completed).length / linked.length;
              return LinearProgressIndicator(value: p, color: color, backgroundColor: color.withValues(alpha: 0.1), minHeight: 6, borderRadius: BorderRadius.circular(8));
            })
          else if (progressVal != null)
             LinearProgressIndicator(value: progressVal, color: color, backgroundColor: color.withValues(alpha: 0.1), minHeight: 6, borderRadius: BorderRadius.circular(8)),
        ],
      ),
    );
  }

 
  // Radar Map classes will be moved to the end of the file.


  Widget _buildTasksBoard(Project project, bool isDark) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              ElevatedButton.icon(
                onPressed: () => _showAddTaskDialog(project, isDark),
                icon: const Icon(IconsaxPlusLinear.add, size: 16),
                label: const Text('Add Task'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: isDesktop ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildKanbanColumn('To Do', TaskStatus.todo, project, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKanbanColumn('In Progress', TaskStatus.inProgress, project, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKanbanColumn('In Review', TaskStatus.review, project, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKanbanColumn('Done', TaskStatus.done, project, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKanbanColumn('Completed', TaskStatus.completed, project, isDark)),
                ],
            ) : DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: project.brandColor,
                    labelColor: project.brandColor,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'To Do'),
                      Tab(text: 'In Progress'),
                      Tab(text: 'Review'),
                      Tab(text: 'Done'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildKanbanColumn('To Do', TaskStatus.todo, project, isDark, isMobile: true),
                        _buildKanbanColumn('In Progress', TaskStatus.inProgress, project, isDark, isMobile: true),
                        _buildKanbanColumn('In Review', TaskStatus.review, project, isDark, isMobile: true),
                        _buildKanbanColumn('Done', TaskStatus.done, project, isDark, isMobile: true),
                        _buildKanbanColumn('Completed', TaskStatus.completed, project, isDark, isMobile: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildKanbanColumn(String title, TaskStatus status, Project project, bool isDark, {bool isMobile = false}) {
    final tasks = context.watch<TaskProvider>().allTasks.where((t) => project.taskIds.contains(t.id) && t.status == status).toList();
    
    return Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: project.brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('${tasks.length}', style: TextStyle(color: project.brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: tasks.isEmpty ? 1 : tasks.length,
              itemBuilder: (context, index) {
                if (tasks.isEmpty) {
                  return Container(
                     padding: const EdgeInsets.all(24),
                     decoration: DottedDecorationBuilder(isDark), // Basic dashed container look
                     child: const Center(child: Text('Drop tasks here', style: TextStyle(color: Colors.grey, fontSize: 12))),
                  );
                }
                final task = tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Flexible(
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(4)),
                               child: Text(task.taskNumber, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87), overflow: TextOverflow.ellipsis),
                             ),
                           ),
                           const SizedBox(width: 4),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(color: _getPriorityColor(task.priority).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                             child: Text(task.priority.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(task.priority))),
                           ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 12),
                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Icon(IconsaxPlusLinear.wallet_1, size: 12, color: project.brandColor),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text('\$${task.allocatedCost.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: project.brandColor), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                            if (task.dueDate != null) 
                               Row(
                                 children: [
                                    Icon(IconsaxPlusLinear.timer_1, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                                    const SizedBox(width: 4),
                                    Text('${task.dueDate!.day}/${task.dueDate!.month}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                                 ],
                               )
                         ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, thickness: 0.5)),
                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Flexible(
                              child: Row(
                                children: [
                                  const CircleAvatar(radius: 10, backgroundColor: Colors.indigo, child: Icon(Icons.person, size: 10, color: Colors.white)),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(task.author, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                            Icon(IconsaxPlusLinear.more, color: isDark ? Colors.white30 : Colors.black38, size: 16),
                         ],
                       )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.critical: return Colors.redAccent;
      case TaskPriority.high: return Colors.orangeAccent;
      case TaskPriority.low: return Colors.lightBlue;
      default: return Colors.blueGrey;
    }
  }

  BoxDecoration DottedDecorationBuilder(bool isDark) {
    return BoxDecoration(
      color: Colors.transparent,
      border: Border.all(color: isDark ? Colors.white10 : Colors.black12, style: BorderStyle.solid), // Simulating dash
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildFinancialLedger(Project project, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Financial Ledger', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(IconsaxPlusLinear.add, size: 16),
                label: const Text('Add Record'),
                style: ElevatedButton.styleFrom(backgroundColor: project.brandColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )
            ],
          ),
          const SizedBox(height: 24),
          // 3 Stat Cards
          Row(
            children: [
              _buildFinanceMetricCard('Total Budget', '\$${project.totalBudget.toStringAsFixed(0)}', IconsaxPlusLinear.bank, Colors.blueAccent, isDark),
              const SizedBox(width: 16),
              _buildFinanceMetricCard('Consumed Liability', '\$${project.consumedBudget.toStringAsFixed(0)}', IconsaxPlusLinear.wallet_minus, AppColors.error, isDark),
              const SizedBox(width: 16),
              _buildFinanceMetricCard('Generated Revenue', '\$${(project.generatedRevenue).toStringAsFixed(0)}', IconsaxPlusLinear.wallet_add_1, AppColors.success, isDark),
            ],
          ),
          const SizedBox(height: 32),
          // Ledger Log Builder
          Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          if (project.financialLogs.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No secure logs discovered.')))
          else
             ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: project.financialLogs.length,
               itemBuilder: (context, index) {
                  final log = project.financialLogs[project.financialLogs.length - 1 - index]; // reversed
                  final isIncome = log.type == LogType.revenue;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isIncome ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(isIncome ? IconsaxPlusLinear.arrow_down : IconsaxPlusLinear.arrow_up_3, color: isIncome ? AppColors.success : AppColors.error),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                           Text(log.description, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                           const SizedBox(height: 4),
                           Text('${log.category}  •  ${log.date.toString().substring(0, 10)}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                        ])),
                        Text(isIncome ? '+\$${log.amount}' : '-\$${log.amount}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isIncome ? AppColors.success : AppColors.error)),
                      ],
                    ),
                  );
               }
             )
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFinanceMetricCard(String title, String val, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataVault(Project project, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconsaxPlusLinear.data, size: 64, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 16),
          Text('Assets & Documents Vault', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        ],
      )
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showAddTaskDialog(Project project, bool isDark) {
    // Phase 2: This will be a Smart Importer dropdown looking over TaskProvider globals
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
           width: 400,
           padding: const EdgeInsets.all(32),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                Icon(IconsaxPlusLinear.link, size: 64, color: project.brandColor),
                const SizedBox(height: 16),
                Text('Link Global Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 16),
                const Text('Task creation is now centralized in the Global Tasks menu. Use this panel to bind pre-existing tasks to this project sprint.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: project.brandColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Close'),
                )
             ],
           )
        )
      )
    );
  }
}

// ── New Component: Project Setup Form ──
class _ProjectSetupForm extends StatefulWidget {
  final Project project;
  const _ProjectSetupForm({required this.project});

  @override
  State<_ProjectSetupForm> createState() => _ProjectSetupFormState();
}

class _ProjectSetupFormState extends State<_ProjectSetupForm> {
  late TextEditingController _nameCtrl, _catCtrl, _descCtrl, _minBCtrl, _maxBCtrl, _webCtrl, _phoneCtrl, _coverCtrl, _inspCtrl, _sigCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameCtrl = TextEditingController(text: p.name);
    _catCtrl = TextEditingController(text: p.category);
    _descCtrl = TextEditingController(text: p.description);
    _minBCtrl = TextEditingController(text: p.minBudget.toString());
    _maxBCtrl = TextEditingController(text: p.maxBudget.toString());
    _webCtrl = TextEditingController(text: p.website);
    _phoneCtrl = TextEditingController(text: p.phoneNumber);
    _coverCtrl = TextEditingController(text: p.coverPhotoUrl);
    _inspCtrl = TextEditingController(text: p.inspirationText);
    _sigCtrl = TextEditingController(text: p.managerSignature);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
    _minBCtrl.dispose();
    _maxBCtrl.dispose();
    _webCtrl.dispose();
    _phoneCtrl.dispose();
    _coverCtrl.dispose();
    _inspCtrl.dispose();
    _sigCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    
    final updated = widget.project.copyWith(
      name: _nameCtrl.text,
      category: _catCtrl.text,
      description: _descCtrl.text,
      minBudget: double.tryParse(_minBCtrl.text) ?? 0,
      maxBudget: double.tryParse(_maxBCtrl.text) ?? 0,
      website: _webCtrl.text,
      phoneNumber: _phoneCtrl.text,
      coverPhotoUrl: _coverCtrl.text,
      inspirationText: _inspCtrl.text,
      managerSignature: _sigCtrl.text,
    );

    if (mounted) {
      Provider.of<ProjectProvider>(context, listen: false).updateProject(updated);
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Project Blueprint Synchronized Successfully!'), backgroundColor: widget.project.brandColor, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.project.brandColor;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveRowColumn(
            layout: ResponsiveBreakpoints.of(context).largerThan(TABLET) ? ResponsiveRowColumnType.ROW : ResponsiveRowColumnType.COLUMN,
            rowMainAxisAlignment: MainAxisAlignment.spaceBetween,
            columnCrossAxisAlignment: CrossAxisAlignment.stretch,
            columnSpacing: 20,
            children: [
              ResponsiveRowColumnItem(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Project Blueprint', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
                    Text('Configure master parameters and deployment info', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                  ],
                ),
              ),
              ResponsiveRowColumnItem(
                child: Hero(
                  tag: 'blueprint_save',
                  child: SizedBox(
                    width: ResponsiveBreakpoints.of(context).largerThan(TABLET) ? null : double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(IconsaxPlusLinear.cloud_change, size: 18),
                      label: Text(_isSaving ? 'Saving...' : 'Deploy Updates', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color, 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: color.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // --- Core Identity ---
          _sectionHeader('Core Identity', IconsaxPlusLinear.personalcard),
          _inputRow([
            _inputField('Project Name', _nameCtrl, IconsaxPlusLinear.box, isDark),
            _inputField('Category', _catCtrl, IconsaxPlusLinear.category, isDark),
          ]),
          _inputField('Description', _descCtrl, IconsaxPlusLinear.document_text, isDark, maxLines: 3),
          
          const SizedBox(height: 32),
          
          // --- Financial Parameters ---
          _sectionHeader('Market Valuation (Budget Range)', IconsaxPlusLinear.wallet_3),
          _inputRow([
            _inputField('Minimum Budget (\$)', _minBCtrl, IconsaxPlusLinear.money_4, isDark, isNumber: true),
            _inputField('Maximum Budget (\$)', _maxBCtrl, IconsaxPlusLinear.money_send, isDark, isNumber: true),
          ]),
          
          const SizedBox(height: 32),
          
          // --- External Linkage ---
          _sectionHeader('External Linkage & Contact', IconsaxPlusLinear.global),
          _inputRow([
            _inputField('Official Website', _webCtrl, IconsaxPlusLinear.global, isDark),
            _inputField('Contact Number', _phoneCtrl, IconsaxPlusLinear.call, isDark),
          ]),
          
          Text('Project Cover Asset', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), style: BorderStyle.solid),
            ),
            child: InkWell(
              onTap: () {
                // Trigger file picker logic
              },
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconsaxPlusLinear.cloud_add, color: color, size: 32),
                  const SizedBox(height: 12),
                  const Text('DRAG & DROP ASSETS HERE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  Text('Supports JPG, PNG, WEBP (Max 5MB)', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _inputField('Or Paste Cover Photo URL', _coverCtrl, IconsaxPlusLinear.link, isDark),
          
          const SizedBox(height: 32),
          
          // --- Inspiration & Validation ---
          _sectionHeader('Strategic Inspiration', IconsaxPlusLinear.lamp_charge),
          _inputField('Inspiration Brief', _inspCtrl, IconsaxPlusLinear.edit_2, isDark, maxLines: 4),
          
          const SizedBox(height: 32),
          
          _sectionHeader('Digital Validation', IconsaxPlusLinear.verify),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project Manager Virtual Signature', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: _sigCtrl,
                  style: TextStyle(color: color, fontSize: 24, fontFamily: 'DancingScript', fontWeight: FontWeight.bold),
                  decoration: InputDecoration(hintText: 'Enter name for digital signature...', border: InputBorder.none, prefixIcon: Icon(IconsaxPlusLinear.edit_2, color: color)),
                ),
                const Divider(),
                const Text('By providing this virtual signature, you acknowledge the current project parameters as the source of truth for the workspace.', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(children: [Icon(icon, color: widget.project.brandColor, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _inputRow(List<Widget> children) {
    return ResponsiveRowColumn(
      layout: ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? ResponsiveRowColumnType.ROW : ResponsiveRowColumnType.COLUMN,
      rowSpacing: 16,
      columnSpacing: 0,
      rowPadding: const EdgeInsets.all(0),
      columnPadding: const EdgeInsets.all(0),
      children: children.map((c) => ResponsiveRowColumnItem(
        rowFlex: 1,
        child: c,
      )).toList(),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, bool isDark, {int maxLines = 1, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: widget.project.brandColor),
          filled: true,
          fillColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.project.brandColor)),
        ),
      ),
    );
  }
}

// ── New Component: Plans Workspace ──
class _PlansWorkspace extends StatefulWidget {
  final Project project;
  final Function(Plan) onOpenConsole;
  const _PlansWorkspace({required this.project, required this.onOpenConsole});

  @override
  State<_PlansWorkspace> createState() => _PlansWorkspaceState();
}

class _PlansWorkspaceState extends State<_PlansWorkspace> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.project.brandColor;
    final plans = widget.project.plans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Creation Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STRATEGIC CONSOLE LOGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2, color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleCtrl,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Plan Title...',
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_titleCtrl.text.isNotEmpty) {
                        context.read<ProjectProvider>().addPlanToProject(widget.project.id, _titleCtrl.text, _descCtrl.text);
                        _titleCtrl.clear();
                        _descCtrl.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
                    child: const Icon(IconsaxPlusLinear.add, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Brief objective...',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.white70,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: -0.1),

        const SizedBox(height: 32),

        // Plans Grid
        Expanded(
          child: plans.isEmpty 
          ? Center(child: Text('No plans active for this console. Create one to begin.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
          : ListView.builder(
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _buildPlanCard(plan, isDark, color);
              },
            ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(Plan plan, bool isDark, Color color) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        // Calculate cost from plan's tasks
        final tasksInPlan = taskProvider.allTasks.where((t) => t.planId == plan.id).toList();
        final cost = tasksInPlan.fold(0.0, (sum, t) => sum + t.grandTotal);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                      child: Icon(IconsaxPlusLinear.hierarchy, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: Text(plan.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1))),
                              // i-CODE on the Right Side
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: plan.icode));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('i-CODE Copied!'), behavior: SnackBarBehavior.floating));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(plan.icode, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                      const SizedBox(width: 6),
                                      Icon(Icons.copy, color: color, size: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(plan.description.isEmpty ? 'Deployment Console Root' : plan.description, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    _miniInfo(IconsaxPlusLinear.user, 'Auth', plan.author, isDark),
                    _miniInfo(IconsaxPlusLinear.user_edit, 'Agent', plan.assignedAuthor, isDark, 
                      onTap: () => _showAssignDialog(plan.id)),
                    _miniInfo(IconsaxPlusLinear.calendar_1, 'Launch', plan.createdAt.toString().substring(0, 10), isDark),
                    _miniInfo(IconsaxPlusLinear.dollar_square, 'Budget', '\$${cost.toInt()}', isDark, color: color),
                    _miniInfo(IconsaxPlusLinear.setting_4, 'Engine', '${tasksInPlan.length} Nodes', isDark),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.read<ProjectProvider>().removePlan(widget.project.id, plan.id),
                      icon: const Icon(IconsaxPlusLinear.trash, size: 16, color: Colors.redAccent),
                      label: const Text('PURGE PLAN', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onOpenConsole(plan),
                      style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('OPEN CONSOLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
      }
    );
  }

  Widget _statusBadge(ProjectStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _miniInfo(IconData icon, String label, String value, bool isDark, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? (isDark ? Colors.white38 : Colors.black38)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(fontSize: 8, color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 11, color: color ?? (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(String planId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Agent to Plan'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Enter Agent Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ProjectProvider>().assignAuthorToPlan(widget.project.id, planId, ctrl.text);
              Navigator.pop(context);
            }, 
            child: const Text('Assign')
          ),
        ],
      ),
    );
  }
}

Widget _buildConsoleBoard(Project project, bool isDark) {
  return _ConsoleLogAnalysis(project: project);
}

class _ConsoleLogAnalysis extends StatelessWidget {
  final Project project;
  const _ConsoleLogAnalysis({required this.project});

  @override
  Widget build(BuildContext context) {
    final color = project.brandColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plans = project.plans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(IconsaxPlusLinear.document_favorite, color: color, size: 28),
            const SizedBox(width: 16),
            const Text('CONSOLE LOG ANALYSIS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 24),
        if (plans.isEmpty)
          Expanded(child: Center(child: Text('No active consoles to analyze.', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26)))),
        if (plans.isNotEmpty)
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: plan.icode));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('i-CODE Copied!'), behavior: SnackBarBehavior.floating));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(plan.icode, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.copy, color: color, size: 12),
                                ],
                              ),
                            ),
                          ),
                          Text(plan.status.name.toUpperCase(), style: TextStyle(color: _getStatusColor(plan.status), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statItem(IconsaxPlusLinear.task, '${plan.taskIds.length} Nodes'),
                          _statItem(IconsaxPlusLinear.timer_1, '${plan.historyLogs.length} Events'),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _statItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed: return Colors.green;
      case ProjectStatus.inProgress: return Colors.blue;
      case ProjectStatus.delayed: return Colors.orange;
      default: return Colors.grey;
    }
  }
}

// ── New Component: Plan-Specific Kanban Console ──
class _PlanConsoleBoard extends StatefulWidget {
  final Project project;
  final Plan plan;
  final VoidCallback onBackPressed;
  const _PlanConsoleBoard({required this.project, required this.plan, required this.onBackPressed});

  @override
  State<_PlanConsoleBoard> createState() => _PlanConsoleBoardState();
}

class _PlanConsoleBoardState extends State<_PlanConsoleBoard> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.project.brandColor;
    final isDesktop = MediaQuery.of(context).size.width > 750;
    final allPlanTasks = context.watch<TaskProvider>().allTasks.where((t) => t.planId == widget.plan.id).toList();
    final tasks = allPlanTasks.where((t) => !t.isArchived).toList();
    final archivedCount = allPlanTasks.where((t) => t.isArchived).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBackPressed,
              icon: const Icon(IconsaxPlusLinear.arrow_left_1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isDesktop
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(widget.plan.title.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: widget.plan.icode));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('i-CODE Copied!'), behavior: SnackBarBehavior.floating));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
                                child: Row(
                                  children: [
                                    Text(widget.plan.icode, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.copy, color: color, size: 10),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text('ADVANCED TRACE & TRACK CONSOLE',
                          style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildActionButtons(isDesktop, color, isDark, tasks, archivedCount),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Builder(
            builder: (context) {
              if (!isDesktop) {
                return DefaultTabController(
                  length: 5,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: color,
                        labelColor: color,
                        unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                        tabs: const [
                          Tab(text: 'TO DO'),
                          Tab(text: 'ACTION'),
                          Tab(text: 'REVIEW'),
                          Tab(text: 'DONE'),
                          Tab(text: 'COMPLETED'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildColumnList(tasks.where((t) => t.status == TaskStatus.todo).toList(), color, isDark),
                            _buildColumnList(tasks.where((t) => t.status == TaskStatus.inProgress).toList(), Colors.blueAccent, isDark),
                            _buildColumnList(tasks.where((t) => t.status == TaskStatus.review).toList(), Colors.amberAccent, isDark),
                            _buildColumnList(tasks.where((t) => t.status == TaskStatus.done).toList(), Colors.greenAccent, isDark),
                            _buildColumnList(tasks.where((t) => t.status == TaskStatus.completed).toList(), Colors.tealAccent, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildColumn('TO DO', tasks.where((t) => t.status == TaskStatus.todo).toList(), color, isDark, onMove: (t) => _updateNodeStatus(t, TaskStatus.todo))),
                        Expanded(child: _buildColumn('ACTION', tasks.where((t) => t.status == TaskStatus.inProgress).toList(), Colors.blueAccent, isDark, onMove: (t) => _updateNodeStatus(t, TaskStatus.inProgress))),
                        Expanded(child: _buildColumn('REVIEW', tasks.where((t) => t.status == TaskStatus.review).toList(), Colors.amberAccent, isDark, onMove: (t) => _updateNodeStatus(t, TaskStatus.review))),
                        Expanded(child: _buildColumn('DONE', tasks.where((t) => t.status == TaskStatus.done).toList(), Colors.greenAccent, isDark, onMove: (t) => _updateNodeStatus(t, TaskStatus.done))),
                        Expanded(child: _buildColumn('COMPLETED', tasks.where((t) => t.status == TaskStatus.completed).toList(), Colors.tealAccent, isDark, isLast: true, onMove: (t) => _updateNodeStatus(t, TaskStatus.completed))),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildTraceabilityLog(Color color, bool isDark) {
    // We need to find the latest version of this plan from the provider for real-time logs
    final project = context.watch<ProjectProvider>().allProjects.firstWhere((p) => p.id == widget.project.id);
    final plan = project.plans.firstWhere((pl) => pl.id == widget.plan.id);
    final logs = plan.historyLogs.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(IconsaxPlusLinear.document_filter, size: 18, color: color),
                const SizedBox(width: 10),
                const Text('TRACEABILITY LOG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: logs.isEmpty ? 
            Center(child: Text('No trace logs recorded.', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10))) :
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: _getLogColor(log.actionType), shape: BoxShape.circle),
                          ),
                          if (index != logs.length - 1)
                            Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(log.message, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(log.timestamp.toString().substring(11, 16), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'INITIALIZATION': return Colors.teal;
      case 'STATUS_SHIFT': return Colors.blue;
      case 'UNIT_LINKED': return Colors.purple;
      case 'OPERATOR_ASSIGNED': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _updateNodeStatus(SystemTask task, TaskStatus newStatus) {
    // 1. Update Task Provider
    context.read<TaskProvider>().updateTaskStatus(task.id, newStatus);
    
    // 2. Add to Traceability Log in Project Provider
    context.read<ProjectProvider>().updatePlanStatus(
      widget.project.id, 
      widget.plan.id, 
      _mapTaskToProjectStatus(newStatus), 
      'Admin' // In production, this would be the actual logged-in user
    );
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Node ${task.taskNumber} shifted to ${newStatus.displayName}'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
  }

  ProjectStatus _mapTaskToProjectStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed: return ProjectStatus.completed;
      case TaskStatus.todo: return ProjectStatus.planned;
      default: return ProjectStatus.inProgress;
    }
  }

  void _exportConsoleData(List<SystemTask> tasks) {
    if (tasks.isEmpty) return;
    final encoded = json.encode(tasks.map((t) => t.toMap()).toList());
    final bytes = utf8.encode(encoded);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "Console_Bundle_${widget.plan.title}_${DateTime.now().millisecondsSinceEpoch}.json")
      ..click();
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Console bundle exported successfully.')));
  }

  Future<void> _importConsoleData(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null && result.files.first.bytes != null) {
        final content = utf8.decode(result.files.first.bytes!);
        final List decoded = json.decode(content);
        final tp = context.read<TaskProvider>();
        int count = 0;
        for (final m in decoded) {
          final oldId = m['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          final task = SystemTask.fromMap(m).copyWith(
            id: 'tsk_${DateTime.now().microsecondsSinceEpoch}_$oldId',
            planId: widget.plan.id
          );
          tp.addTask(task);
          count++;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registry imported successfully ($count nodes).'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing data: $e')));
    }
  }

  void _showAddNodeDialog(BuildContext context, Color color, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Link Console Node', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the UID of a node to link it to this plan.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'UID e.g. T-102...',
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final tp = context.read<TaskProvider>();
              final match = tp.allTasks.where((t) => t.taskNumber.toUpperCase() == _searchCtrl.text.trim().toUpperCase());
              if (match.isNotEmpty) {
                final task = match.first;
                // Link it via ProjectProvider to get the Log
                context.read<ProjectProvider>().linkTaskToPlan(widget.project.id, widget.plan.id, task.id, task.title, 'Admin');
                // Also update TaskProvider
                tp.updateTaskStatus(task.id, task.status, planId: widget.plan.id);
                
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Node ${task.taskNumber} attached to traceability flow.'), behavior: SnackBarBehavior.floating));
                _searchCtrl.clear();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UID not found in console registry.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            child: const Text('Link Node'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDesktop, Color color, bool isDark, List<SystemTask> tasks, int archivedCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionIconButton(
          onPressed: () => _showArchivedTasksDialog(context, color, isDark),
          icon: IconsaxPlusLinear.archive_tick,
          tooltip: 'Registry Archive ($archivedCount)',
          color: color,
          isDark: isDark,
          badge: archivedCount > 0 ? '$archivedCount' : null,
        ),
        _actionIconButton(
          onPressed: () => _exportConsoleData(tasks),
          icon: IconsaxPlusLinear.document_download,
          tooltip: 'Export Console Bundle',
          color: color,
          isDark: isDark,
        ),
        _actionIconButton(
          onPressed: () => _importConsoleData(context),
          icon: IconsaxPlusLinear.document_upload,
          tooltip: 'Import Cloud Registry',
          color: color,
          isDark: isDark,
        ),
        _actionIconButton(
          onPressed: () => _showAddNodeDialog(context, color, isDark),
          icon: IconsaxPlusLinear.search_status,
          tooltip: 'Search & Attach Node',
          color: color,
          isDark: isDark,
          isSpecial: true,
        ),
        const SizedBox(width: 8),
        _actionIconButton(
          onPressed: () => _showQuickAddDialog(context, color, isDark), 
          icon: IconsaxPlusLinear.add,
          tooltip: 'Generate New Node',
          color: color,
          isDark: isDark,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _actionIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool isDark,
    String? badge,
    bool isPrimary = false,
    bool isSpecial = false,
  }) {
    final bgColor = isPrimary 
        ? color 
        : (isSpecial ? color.withOpacity(0.15) : color.withOpacity(0.08));
    final iconColor = isPrimary ? Colors.white : color;

    Widget button = Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );

    if (badge != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Badge(
          label: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: color,
          offset: const Offset(4, -4),
          child: button,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: button,
    );
  }


  void _showArchivedTasksDialog(BuildContext context, Color color, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(IconsaxPlusLinear.archive_tick, color: color),
            const SizedBox(width: 12),
            const Text('Archived Tasks History', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Consumer<TaskProvider>(
            builder: (context, tp, _) {
              final archivedTasks = tp.allTasks.where((t) => t.planId == widget.plan.id && t.isArchived).toList();
              if (archivedTasks.isEmpty) {
                return Center(child: Text('No archived tasks.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
              }
              return ListView.builder(
                itemCount: archivedTasks.length,
                itemBuilder: (context, index) {
                  final task = archivedTasks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.taskNumber, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(IconsaxPlusLinear.rotate_left, color: Colors.green),
                          tooltip: 'Restore to Console',
                          onPressed: () {
                            tp.updateTask(task.copyWith(isArchived: false, status: TaskStatus.completed));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Restored!'), behavior: SnackBarBehavior.floating));
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showQuickAddDialog(BuildContext context, Color color, bool isDark) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('Fast Generate Task', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Task objective...',
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onSubmitted: (val) {
            _executeQuickAdd(val, ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _executeQuickAdd(titleCtrl.text, ctx),
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            child: const Text('Add to TO DO'),
          ),
        ],
      )
    );
  }

  void _executeQuickAdd(String title, BuildContext ctx) {
    if (title.trim().isEmpty) return;
    final tp = context.read<TaskProvider>();
    final newTask = SystemTask(
      id: 'tsk_${DateTime.now().millisecondsSinceEpoch}',
      taskNumber: 'T-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: title.trim(),
      status: TaskStatus.todo,
      planId: widget.plan.id,
    );
    tp.addTask(newTask);
    
    // Log the creation in ProjectProvider Traceability log
    context.read<ProjectProvider>().linkTaskToPlan(widget.project.id, widget.plan.id, newTask.id, newTask.title, 'Admin');
    
    Navigator.pop(ctx);
  }

  void _showManageTaskDialog(BuildContext context, SystemTask task, Color accent, bool isDark) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Consumer<TaskProvider>(
        builder: (context, tp, _) {
          final currentTask = tp.allTasks.firstWhere((t) => t.id == task.id, orElse: () => task);
          return Dialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(IconsaxPlusLinear.setting_4, color: accent),
                          const SizedBox(width: 8),
                          const Text('Manage Node', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(icon: const Icon(IconsaxPlusLinear.close_circle), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  Text(currentTask.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (currentTask.status == TaskStatus.done || currentTask.status == TaskStatus.completed)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(IconsaxPlusLinear.tick_circle, color: Colors.green, size: 16),
                              SizedBox(width: 6),
                              Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      const Spacer(),
                      if (currentTask.status != TaskStatus.todo)
                        InkWell(
                          onTap: () {
                            TaskStatus prevStatus = currentTask.status;
                            if (currentTask.status == TaskStatus.completed) prevStatus = TaskStatus.done;
                            else if (currentTask.status == TaskStatus.done) prevStatus = TaskStatus.review;
                            else if (currentTask.status == TaskStatus.review) prevStatus = TaskStatus.inProgress;
                            else if (currentTask.status == TaskStatus.inProgress) prevStatus = TaskStatus.todo;

                            final newComment = TaskComment(
                              id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
                              author: 'Admin',
                              content: 'Node Demoted Action: Moved to ${prevStatus.displayName}',
                              createdAt: DateTime.now()
                            );
                            context.read<TaskProvider>().updateTask(currentTask.copyWith(status: prevStatus, comments: [...currentTask.comments, newComment]));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Node Demoted to ${prevStatus.displayName}.'), behavior: SnackBarBehavior.floating));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              children: [
                                Icon(IconsaxPlusLinear.arrow_left_2, color: Colors.orangeAccent, size: 16),
                                SizedBox(width: 6),
                                Text('Demote (Prev)', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('Status: ${currentTask.status.displayName}', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Activity & Comments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
                    child: currentTask.comments.isEmpty
                        ? Center(child: Text('No activity yet. Be the first to comment.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: currentTask.comments.length,
                            itemBuilder: (c, i) {
                              final cmt = currentTask.comments[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(cmt.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        Text(cmt.createdAt.toString().substring(0, 16), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(cmt.content, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Add tactical observations or reply...',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(IconsaxPlusLinear.send_1, color: accent),
                        onPressed: () {
                          if (commentCtrl.text.trim().isNotEmpty) {
                            final newComment = TaskComment(
                                id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
                                author: 'Admin',
                                content: commentCtrl.text.trim(),
                                createdAt: DateTime.now()
                            );
                            tp.updateTask(currentTask.copyWith(comments: [...currentTask.comments, newComment]));
                            commentCtrl.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Update Node Integrity', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildColumn(String title, List<SystemTask> tasks, Color accent, bool isDark, {bool isLast = false, Function(SystemTask)? onMove}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(right: isLast ? 0 : 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: accent, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${tasks.length}', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<SystemTask>(
              onAcceptWithDetails: (details) {
                if (onMove != null) onMove(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                return _buildColumnList(tasks, accent, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnList(List<SystemTask> tasks, Color accent, bool isDark) {
    if (tasks.isEmpty) {
      return Center(child: Text('No active nodes', style: TextStyle(color: isDark ? Colors.white12 : Colors.black12, fontSize: 10)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      itemCount: tasks.length,
      itemBuilder: (context, idx) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _buildConsoleNode(context, tasks[idx], accent, isDark),
      ),
    );
  }

  Widget _buildConsoleNode(BuildContext context, SystemTask task, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: task.taskNumber));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('UID Copied: ${task.taskNumber}'), behavior: SnackBarBehavior.floating));
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(task.taskNumber, style: TextStyle(fontSize: 8, color: accent, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 4),
                          Icon(IconsaxPlusLinear.copy, size: 10, color: accent),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: _priorityColor(task.priority).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(task.priority.name.toUpperCase(), style: TextStyle(fontSize: 7, color: _priorityColor(task.priority), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.wallet, size: 10, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text('\$${task.grandTotal.toInt()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.user, size: 10, color: Colors.grey),
                    const SizedBox(width: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 70),
                      child: Text(task.assignee, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (task.comments.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconsaxPlusLinear.message, size: 10, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text('${task.comments.length}', style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    if (task.status == TaskStatus.completed) {
                      context.read<TaskProvider>().updateTask(task.copyWith(isArchived: true));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Archived to History!'), behavior: SnackBarBehavior.floating));
                      return;
                    }

                    TaskStatus nextStatus = task.status;
                    if (task.status == TaskStatus.todo) nextStatus = TaskStatus.inProgress;
                    else if (task.status == TaskStatus.inProgress) nextStatus = TaskStatus.review;
                    else if (task.status == TaskStatus.review) nextStatus = TaskStatus.done;
                    else if (task.status == TaskStatus.done) nextStatus = TaskStatus.completed;

                    if (nextStatus != task.status) {
                      final newComment = TaskComment(
                        id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
                        author: 'Admin',
                        content: 'Node Integrity Approved: Promoted to ${nextStatus.displayName}',
                        createdAt: DateTime.now()
                      );
                      context.read<TaskProvider>().updateTask(task.copyWith(status: nextStatus, comments: [...task.comments, newComment]));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task Promoted to ${nextStatus.displayName}!'), behavior: SnackBarBehavior.floating));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: task.status == TaskStatus.completed ? Colors.teal.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(task.status == TaskStatus.completed ? IconsaxPlusLinear.archive_tick : IconsaxPlusLinear.tick_circle, size: 10, color: task.status == TaskStatus.completed ? Colors.teal : Colors.green),
                        const SizedBox(width: 4),
                        Text(task.status == TaskStatus.completed ? 'ARCHIVE' : 'APPROVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: task.status == TaskStatus.completed ? Colors.teal : Colors.green)),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(IconsaxPlusLinear.eye, size: 14, color: accent),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TaskWorkspaceScreen(taskId: task.id)));
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(IconsaxPlusLinear.setting_4, size: 14, color: accent),
                      onPressed: () {
                        _showManageTaskDialog(context, task, accent, isDark);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.critical: return Colors.redAccent;
      case TaskPriority.high: return Colors.orangeAccent;
      case TaskPriority.medium: return Colors.indigoAccent;
      default: return Colors.blueAccent;
    }
  }
}

class _StrategicRadarMap extends StatefulWidget {
  final Project project;
  const _StrategicRadarMap({required this.project});

  @override
  State<_StrategicRadarMap> createState() => _StrategicRadarMapState();
}

class _StrategicRadarMapState extends State<_StrategicRadarMap> with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final double viewportWidth = context.size?.width ?? 1000;
        final double canvasWidth = (widget.project.plans.length * 400).toDouble().clamp(2500, 100000);
        
        _controller.value = Matrix4.identity()
          ..translate(
            -(canvasWidth / 2 - (viewportWidth / 2)), 
            -0.0 // Start at top
          );
      }
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double val) {
    final Matrix4 currentMatrix = _controller.value;
    final double scale = currentMatrix.getMaxScaleOnAxis();
    final double newScale = (scale + val).clamp(0.1, 2.5);
    _controller.value = Matrix4.identity()..scale(newScale);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().allTasks.where((t) => widget.project.taskIds.contains(t.id)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        RepaintBoundary(
          child: InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(2000), 
            minScale: 0.01, // Extreme zoom out for massive data
            maxScale: 2.0,
            child: Consumer<TaskProvider>(
              builder: (context, tp, _) {
                final double canvasWidth = (widget.project.plans.length * 400).toDouble().clamp(2500, 100000);
                final double canvasHeight = 5000; // Deep vertical space for tasks
                
                return Container(
                  width: canvasWidth,
                  height: canvasHeight,
                  color: Colors.transparent,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // High-Performance Painter
                      CustomPaint(
                        size: Size(canvasWidth, canvasHeight),
                        painter: _RadarLinkPainter(
                          project: widget.project,
                          tasks: tp.allTasks,
                          lineColor: widget.project.brandColor,
                          canvasWidth: canvasWidth,
                        ),
                      ),
                      
                      // Aggregated Nodes
                      ..._buildRadarNodes(context, widget.project, tp.allTasks, isDark, canvasWidth),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        
        // Zoom Controls
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              _zoomBtn(Icons.add, () => _zoom(0.2), widget.project.brandColor, isDark),
              const SizedBox(height: 8),
              _zoomBtn(Icons.remove, () => _zoom(-0.2), widget.project.brandColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap, Color color, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black54 : Colors.white70,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRadarNodes(BuildContext context, Project project, List<SystemTask> tasks, bool isDark, double canvasWidth) {
    List<Widget> nodes = [];
    final double startY = 100;
    final Offset centerTop = Offset(canvasWidth / 2, startY);
    
    // 1. Root Project Hub
    nodes.add(_radarNode(
      context: context,
      offset: centerTop,
      title: project.name,
      icon: IconsaxPlusLinear.box,
      color: project.brandColor,
      isCore: true,
      isDark: isDark,
    ));

    // Unified Coordinate System Constants
    final double planY = startY + 250;
    final double planSpacing = 400; // Consistent horizontal spacing
    final double taskStartY = planY + 180; // Start tasks after insight box
    final double taskSpacingY = 130; // Consistent vertical spacing

    final double totalPlansWidth = (project.plans.length - 1) * planSpacing;
    final double startX = (canvasWidth / 2) - (totalPlansWidth / 2);

    for (int i = 0; i < project.plans.length; i++) {
        final plan = project.plans[i];
        final Offset pNodePos = Offset(startX + (i * planSpacing), planY);
        final planTasks = tasks.where((t) => t.planId == plan.id).toList();

        // 3. Unified Real-Time Insight Hub
        nodes.add(_unifiedPlanHub(
          offset: pNodePos,
          plan: plan,
          tasks: planTasks,
          color: project.brandColor,
          isDark: isDark,
          context: context,
        ));

        // 4. Tasks (Pixel-Perfect Vertical Cascading)
        final displayTasks = planTasks.take(10).toList(); // Show more tasks per plan
        for (int j = 0; j < displayTasks.length; j++) {
            final task = displayTasks[j];
            final Offset tNodePos = Offset(pNodePos.dx, taskStartY + (j * taskSpacingY));

            nodes.add(_taskMicroNode(
              context: context,
              offset: tNodePos,
              task: task,
              color: _getStatusColor(task.status),
              isDark: isDark,
            ));
        }
    }
    return nodes;
  }

  Widget _unifiedPlanHub({
    required Offset offset, 
    required Plan plan, 
    required List<SystemTask> tasks, 
    required Color color, 
    required bool isDark,
    required BuildContext context,
  }) {
    final double totalAmount = tasks.fold(0, (sum, t) => sum + t.grandTotal);
    final todoCount = tasks.where((t) => t.status == TaskStatus.todo).length;
    final doneCount = tasks.where((t) => t.status == TaskStatus.done || t.status == TaskStatus.completed).length;

    return Positioned(
      left: offset.dx - 100,
      top: offset.dy - 40, 
      child: Column(
        children: [
          // Plan Header Tab (i-CODE)
          InkWell(
            onTap: () {
               Clipboard.setData(ClipboardData(text: plan.icode));
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('i-CODE Copied: ${plan.icode}'), behavior: SnackBarBehavior.floating, backgroundColor: color));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 220),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconsaxPlusLinear.status, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      plan.title, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(plan.icode, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          // Insights Body
          Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.9) : Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _insightItem('AMT', '\$${totalAmount.toInt()}', color),
                    _insightItem('TODO', '$todoCount', Colors.orangeAccent),
                    _insightItem('DONE', '$doneCount', Colors.greenAccent),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${tasks.length} Active Operations', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _insightItem(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 7, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(val, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo: return Colors.orangeAccent;
      case TaskStatus.inProgress: return Colors.blueAccent;
      case TaskStatus.review: return Colors.purpleAccent;
      case TaskStatus.done: return Colors.greenAccent;
      case TaskStatus.completed: return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _taskMicroNode({
    required BuildContext context,
    required Offset offset,
    required SystemTask task,
    required Color color,
    required bool isDark,
  }) {
    return Positioned(
      left: offset.dx - 35,
      top: offset.dy - 35,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
            ),
            child: Icon(IconsaxPlusLinear.task_square, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(task.taskNumber, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                Text('\$${task.grandTotal.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 6, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).scale(),
    );
  }

  Widget _radarNode({
    required BuildContext context,
    required Offset offset,
    required String title,
    required IconData icon,
    required Color color,
    bool isCore = false,
    String? subTitle,
    required bool isDark,
    bool isCopyable = false,
  }) {
    return Positioned(
      left: offset.dx - (isCore ? 60 : 50),
      top: offset.dy - (isCore ? 60 : 50),
      child: Column(
        children: [
          Container(
            width: isCore ? 120 : 100,
            height: isCore ? 120 : 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.8) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: isCore ? 4 : 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: isCore ? 5 : 2),
              ],
            ),
            child: Icon(icon, color: color, size: isCore ? 40 : 28),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: isCopyable && subTitle != null ? () {
              Clipboard.setData(ClipboardData(text: subTitle));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('i-CODE Copied: $subTitle'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: color,
              ));
            } : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
              ),
              child: Column(
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subTitle != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(subTitle, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600)),
                        if (isCopyable) ...[
                          const SizedBox(width: 4),
                          const Icon(IconsaxPlusLinear.copy, size: 8, color: Colors.white70),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}

class _RadarRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarRipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 120 + (progress * 200), paint);
    canvas.drawCircle(center, 120 + ((progress + 0.5) % 1.0 * 200), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RadarLinkPainter extends CustomPainter {
  final Project project;
  final List<SystemTask> tasks;
  final Color lineColor;
  final double canvasWidth;

  _RadarLinkPainter({required this.project, required this.tasks, required this.lineColor, required this.canvasWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.25)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double startY = 100;
    final Offset centerTop = Offset(canvasWidth / 2, startY);
    final double planY = startY + 250;
    final double planSpacing = 400;
    final double taskStartY = planY + 180;
    final double taskSpacingY = 130;

    final double totalPlansWidth = (project.plans.length - 1) * planSpacing;
    final double startX = (canvasWidth / 2) - (totalPlansWidth / 2);

    // Main Horizontal Bus Line (Correctly Offset)
    if (project.plans.length > 1) {
       canvas.drawLine(
         Offset(startX, planY - 110), 
         Offset(startX + totalPlansWidth, planY - 110), 
         paint
       );
    }

    // Line from Project to Drive Line
    canvas.drawLine(centerTop, Offset(canvasWidth / 2, planY - 110), paint);

    for (int i = 0; i < project.plans.length; i++) {
        final plan = project.plans[i];
        final Offset pNodePos = Offset(startX + (i * planSpacing), planY);

        // Vertical drop to Plan Hub
        canvas.drawLine(Offset(pNodePos.dx, planY - 110), Offset(pNodePos.dx, planY - 40), paint);

        final linkedTasks = tasks.where((t) => t.planId == plan.id).toList();
        final taskPaint = Paint()
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        // Cascade Tasks line
        if (linkedTasks.isNotEmpty) {
           final double lastTaskY = taskStartY + ((linkedTasks.take(10).length - 1) * taskSpacingY);
           // Line from bottom of Insight Box (appx planY + 120) to the last task
           canvas.drawLine(Offset(pNodePos.dx, planY + 120), Offset(pNodePos.dx, lastTaskY), taskPaint..color = lineColor.withValues(alpha: 0.1));
        }
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo: return Colors.orangeAccent;
      case TaskStatus.inProgress: return Colors.blueAccent;
      case TaskStatus.review: return Colors.purpleAccent;
      case TaskStatus.done: return Colors.greenAccent;
      case TaskStatus.completed: return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
