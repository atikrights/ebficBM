import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'package:ebficbm/widgets/ebm_image.dart';
import 'package:ebficbm/features/companies/models/company.dart';
import 'package:ebficbm/features/companies/providers/company_provider.dart';
import 'package:ebficbm/features/projects/providers/project_provider.dart';
import 'package:ebficbm/features/projects/screens/project_workspace_screen.dart';
import 'package:ebficbm/features/tasks/models/system_task.dart';
import 'package:ebficbm/features/tasks/providers/task_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ebficbm/features/assets/providers/asset_provider.dart';
import 'package:ebficbm/features/assets/models/asset_model.dart';
import 'package:ebficbm/features/assets/screens/asset_library_screen.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ebficbm/features/companies/screens/platform_doc_editor_screen.dart';
import 'package:ebficbm/features/companies/screens/platform_doc_view_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WordLimitFormatter extends TextInputFormatter {
  final int maxWords;

  WordLimitFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final words = newValue.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length > maxWords) {
      final truncatedText = words.take(maxWords).join(' ');
      return TextEditingValue(
        text: truncatedText,
        selection: TextSelection.collapsed(offset: truncatedText.length),
      );
    }
    
    return newValue;
  }
}

class CompanyManageScreen extends StatefulWidget {
  final String companyId;

  const CompanyManageScreen({super.key, required this.companyId});

  @override
  State<CompanyManageScreen> createState() => _CompanyManageScreenState();
}

class _CompanyManageScreenState extends State<CompanyManageScreen> {
  int _selectedIndex = 0;
  int _settingsTabIndex = 0;
  final List<String> _settingsTabs = ['General', 'Customize', 'Advanced'];

  final List<String> _tabNames = ['Overview', 'Blueprint', 'Records', 'Analytics', 'Project Hub', 'Settings'];
  final List<IconData> _tabIcons = [
    IconsaxPlusLinear.element_3,
    IconsaxPlusLinear.edit_2,
    IconsaxPlusLinear.document_text_1,
    IconsaxPlusLinear.chart_2,
    IconsaxPlusLinear.folder_open,
    IconsaxPlusLinear.setting_2
  ];

  // Controllers for Blueprint
  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _fullDescController;
  late TextEditingController _brandingController;
  late TextEditingController _agreementLinkController;
  late TextEditingController _agreementShortDescController;
  late TextEditingController _agreementFullDescController;
  late TextEditingController _roadmapExecutionController;
  late TextEditingController _targetRoadmapController;
  late TextEditingController _signatureController;

  bool _isBriefExpanded = false;
  bool _isDetailsExpanded = false;
  bool _isGovernanceExpanded = false;
  bool _platformsSeeMore = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final provider = context.read<CompanyProvider>();
    final company = provider.allCompanies.firstWhere((c) => c.id == widget.companyId);
    
    _nameController = TextEditingController(text: company.name);
    _shortDescController = TextEditingController(text: company.shortDescription ?? '');
    _fullDescController = TextEditingController(text: company.fullDescription ?? '');
    _brandingController = TextEditingController(text: company.brandingInfo ?? '');
    _agreementLinkController = TextEditingController(text: company.agreementLink ?? '');
    _agreementShortDescController = TextEditingController(text: company.agreementShortDesc ?? '');
    _agreementFullDescController = TextEditingController(text: company.agreementFullDesc ?? '');
    _roadmapExecutionController = TextEditingController(text: company.roadmapExecution ?? '');
    _targetRoadmapController = TextEditingController(text: company.targetRoadmap ?? '');
    _signatureController = TextEditingController(text: company.managerSignature ?? '');
  }

  @override
  void didUpdateWidget(covariant CompanyManageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _fullDescController.dispose();
    _brandingController.dispose();
    _agreementLinkController.dispose();
    _agreementShortDescController.dispose();
    _agreementFullDescController.dispose();
    _roadmapExecutionController.dispose();
    _targetRoadmapController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProvider>();
    final match = provider.allCompanies.where((c) => c.id == widget.companyId);
    
    if (match.isEmpty) {
      if (provider.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const Scaffold(body: Center(child: Text('Organization data lost or removed.')));
    }
    final company = match.first;

    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: !isLargeScreen
          ? AppBar(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(IconsaxPlusLinear.arrow_left, color: isDark ? Colors.white : Colors.black),
              ),
              title: Text(company.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                Builder(builder: (ctx) => IconButton(
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  icon: Icon(IconsaxPlusLinear.element_3, color: isDark ? Colors.white : Colors.black),
                  tooltip: 'Menu',
                )),
                const SizedBox(width: 8),
              ],
            )
          : null,
      drawer: !isLargeScreen
          ? Drawer(
              backgroundColor: Colors.transparent,
              child: _buildSidebar(company, isDark, isDrawer: true),
            )
          : null,
      body: SafeArea(
        child: !isLargeScreen
            ? _buildTabContent(company, isDark)
            : Row(
                children: [
                  _buildSidebar(company, isDark),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        child: _buildTabContent(company, isDark),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSidebar(Company company, bool isDark, {bool isDrawer = false}) {
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
            // Back Button or Drawer Close
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(isDrawer ? IconsaxPlusLinear.close_circle : IconsaxPlusLinear.arrow_left, color: textColor),
                tooltip: isDrawer ? 'Close Menu' : 'Back to Registry',
              ),
            ),
            const SizedBox(height: 16),
            // Company Profile Snippet
            Center(
              child: _buildCompanyLogo(company, 64),
            ),
            const SizedBox(height: 16),
            Text(
              company.name,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              company.categories.join(', ').toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // Navigation Links
            ...List.generate(_tabNames.length, (index) {
              final isSelected = _selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                       setState(() => _selectedIndex = index);
                       if (isDrawer) {
                         Navigator.pop(context); // Close Drawer
                       }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(_tabIcons[index], color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54), size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _tabNames[index],
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
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
            const Spacer(),
            // View / Website Shortcut
            ElevatedButton.icon(
              onPressed: () {}, // Open web
              icon: const Icon(IconsaxPlusLinear.global, size: 16),
              label: const Text('Open Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                foregroundColor: textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Company company, bool isDark) {
    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = KeyedSubtree(key: const ValueKey('overview'), child: _buildOverviewTab(company, isDark));
        break;
      case 1:
        content = KeyedSubtree(key: const ValueKey('blueprint'), child: _buildBlueprintTab(company, isDark));
        break;
      case 2:
        content = KeyedSubtree(key: const ValueKey('records'), child: _buildRecordsTab(company, isDark));
        break;
      case 3:
        content = KeyedSubtree(key: const ValueKey('analytics'), child: _buildAnalyticsTab(company, isDark));
        break;
      case 4:
        content = KeyedSubtree(key: const ValueKey('projects'), child: _buildProjectHubTab(company, isDark));
        break;
      case 5:
        content = KeyedSubtree(key: const ValueKey('settings'), child: _buildSettingsTab(company, isDark));
        break;
      default:
        content = const SizedBox(key: ValueKey('empty'));
    }

    if (!isLargeScreen) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: Container(
          key: ValueKey(_selectedIndex),
          margin: const EdgeInsets.all(12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            child: content,
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: content,
    );
  }

  // ============== TABS ==============

  Widget _buildOverviewTab(Company company, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Executive Intelligence', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('High-level overview of resources, health, and recent operations.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 24),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Health Rating', '${(company.healthScore * 100).toInt()}%', IconsaxPlusLinear.health, company.healthScore > 0.8 ? AppColors.success : AppColors.warning, isDark),
              _buildStatCard('Staff Allocated', '${company.activeEmployees}', IconsaxPlusLinear.profile_2user, Colors.blue, isDark),
              _buildStatCard('Active Deployments', '${company.projectIds.length}', IconsaxPlusLinear.folder_2, Colors.orange, isDark),
              _buildStatCard('Annual Logistics', '\$${(company.annualRevenue / 1000000).toStringAsFixed(1)}M', IconsaxPlusLinear.money_2, AppColors.primary, isDark),
            ],
          ),
          
          const SizedBox(height: 32),
          // Deep Starter Analytics Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget Utilization Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    const Icon(IconsaxPlusLinear.chart, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Consumed Resources', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('\$${(company.budgetUtilized / 1000000).toStringAsFixed(2)}M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: isDark ? Colors.white : Colors.black)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Allocated Target', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('\$${(company.annualRevenue / 1000000).toStringAsFixed(2)}M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: company.annualRevenue == 0 ? 0 : company.budgetUtilized / company.annualRevenue,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  color: (company.budgetUtilized / company.annualRevenue) > 0.9 ? AppColors.error : AppColors.primary,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Text('Action Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          _buildActivityLog('Budget optimization algorithm executed successfully.', '2 hours ago', isDark),
          _buildActivityLog('3 senior developers transferred to Core Infrastructure.', 'Yesterday', isDark),
          _buildActivityLog('Automated System Security Audit passed with 99.9% uptime.', '3 days ago', isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActivityLog(String log, String time, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 12),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(Company company, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconsaxPlusLinear.chart_2, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text('Financial Engine & Real-time Charts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('Advanced Fl_chart implementations going here soon.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildProjectHubTab(Company company, bool isDark) {
    final projectProvider = context.watch<ProjectProvider>();
    final projects = projectProvider.getProjectsForCompany(company.id);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Project Deployments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showDeployProjectDialog(context, company, isDark),
                    icon: const Icon(IconsaxPlusLinear.add, size: 16),
                    label: const Text('Deploy'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )
                ],
              ),
              const SizedBox(height: 24),
              if (projects.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(IconsaxPlusLinear.folder_cross, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                        const SizedBox(height: 16),
                        Text('No projects deployed yet.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                      ]
                    ),
                  ),
                ),
            ],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final proj = projects[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: proj.brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(IconsaxPlusLinear.folder, color: proj.brandColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(proj.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                              const SizedBox(height: 4),
                              Text(proj.description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectWorkspaceScreen(projectId: proj.id)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            foregroundColor: proj.brandColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0
                          ),
                          child: const Text('Open', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Budget', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: proj.totalBudget == 0 ? 0 : proj.consumedBudget / proj.totalBudget,
                                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                color: proj.brandColor,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4)
                              ),
                              const SizedBox(height: 6),
                              Text('\$${proj.consumedBudget.toStringAsFixed(0)} / \$${proj.totalBudget.toStringAsFixed(0)}', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          )
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Consumer<TaskProvider>(
                            builder: (context, tp, _) {
                              final linked = tp.allTasks.where((t) => proj.taskIds.contains(t.id));
                              final progress = linked.isEmpty ? 0.0 : linked.where((t) => t.status == TaskStatus.done).length / linked.length;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tasks', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                    color: AppColors.success,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${(progress * 100).toInt()}% Done', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              );
                            }
                          )
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
            childCount: projects.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildSettingsTab(Company company, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_settingsTabs.length, (index) {
                final isSelected = _settingsTabIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _settingsTabIndex = index),
                      borderRadius: BorderRadius.circular(30),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12)),
                        ),
                        child: Text(
                          _settingsTabs[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _buildSettingsTabContent(company, isDark, _settingsTabIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTabContent(Company company, bool isDark, int index) {
    if (index == 0) {
      // General Tab
      return SizedBox(
        key: const ValueKey('general'),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('General Configuration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
             const SizedBox(height: 8),
             Text('Manage structural organizational parameters.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
             // (Blank placeholder as requested)
          ]
        ),
      );
    } else if (index == 1) {
      // Customize Tab
      return SingleChildScrollView(
        key: const ValueKey('customize'),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customize Identity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text('Manage organizational identity and corporate parameters.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
            const SizedBox(height: 32),
            
            GlassContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 20,
              child: ResponsiveBreakpoints.of(context).isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                       _buildCompanyLogo(company, 80),
                       const SizedBox(height: 24),
                       Text('Corporate Emblem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), textAlign: TextAlign.center),
                       const SizedBox(height: 6),
                       Text('This identifier is globally distributed across systems. The engine will automatically execute an optimized center-crop. Use PNG/JPG (local) or any active URL endpoint.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54, height: 1.4), textAlign: TextAlign.center),
                       const SizedBox(height: 24),
                       SizedBox(
                         width: double.infinity,
                         child: ElevatedButton.icon(
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primary,
                             foregroundColor: Colors.white,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             padding: const EdgeInsets.symmetric(vertical: 16)
                           ),
                           onPressed: () => _openLogoEditor(context, company, isDark),
                           icon: const Icon(IconsaxPlusLinear.gallery_edit, size: 16),
                           label: const Text('Update Asset', style: TextStyle(fontWeight: FontWeight.bold))
                         ),
                       )
                    ]
                  )
                : Row(
                   children: [
                      _buildCompanyLogo(company, 80),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text('Corporate Emblem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                             const SizedBox(height: 6),
                             Text('This identifier is globally distributed across systems. The engine will automatically execute an optimized center-crop. Use PNG/JPG (local) or any active URL endpoint.', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54, height: 1.4)),
                          ]
                        )
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                        ),
                        onPressed: () => _openLogoEditor(context, company, isDark),
                        icon: const Icon(IconsaxPlusLinear.gallery_edit, size: 16),
                        label: const Text('Update Asset')
                      )
                   ]
                )
            )
          ],
        )
      );
    } else {
      // Advanced Tab
      return SizedBox(
        key: const ValueKey('advanced'),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Advanced Configurations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
             const SizedBox(height: 8),
             Text('Danger zone and low-level API mechanics.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
          ]
        ),
      );
    }
  }

  void _openLogoEditor(BuildContext context, Company company, bool isDark) {
    final TextEditingController linkController = TextEditingController(
        text: company.logoUrl?.startsWith('http') == true ? company.logoUrl : '');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Upload Logo',
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              width: 460,
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Branding Identity',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black)),
                        IconButton(
                          icon: Icon(IconsaxPlusLinear.close_circle,
                              color: isDark ? Colors.white : Colors.black),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Option 1: File Upload
                    Text('Direct System Upload',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        try {
                          final result = await FilePicker.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            final provider = ctx.read<AssetProvider>();
                            final assetId = await provider.syncFileToLibrary(
                              result.files.single.path!,
                              name: 'Company Logo: ${company.name}',
                            );

                            if (assetId != null && ctx.mounted) {
                              ctx.read<CompanyProvider>().updateCompanyLogo(
                                  company.id, 'asset://$assetId');

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      const Text('Emblem synced successfully!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        } catch (_) {}
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(IconsaxPlusLinear.document_upload,
                                size: 28,
                                color: AppColors.primary.withValues(alpha: 0.8)),
                            const SizedBox(height: 6),
                            Text('Inject PNG, JPG, WEBP',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildDivider('OR EXTERNAL ENDPOINT', isDark),
                    const SizedBox(height: 16),

                    // ── Option 2: URL
                    Text('Hyperlink Pipeline',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: linkController,
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'https://cdn.brand.com/logo.png',
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 11),
                                prefixIcon: Icon(IconsaxPlusLinear.link,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    size: 16),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                isDense: true,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                if (linkController.text.isNotEmpty) {
                                  ctx.read<CompanyProvider>().updateCompanyLogo(
                                      company.id, linkController.text);
                                  // ✅ Auto-sync to Asset Library
                                  ctx.read<AssetProvider>().syncUrlToLibrary(
                                      linkController.text,
                                      name: 'Logo Link: ${company.name}');
                                  
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Apply',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildDivider('OR PICK FROM ASSET LIBRARY', isDark),
                    const SizedBox(height: 16),

                    // ── Option 3: Asset Library Picker
                    Text('Asset Library',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    Consumer<AssetProvider>(
                      builder: (context, assetProvider, _) {
                        final imageAssets = assetProvider.allAssets
                            .where((a) => a.type == AssetType.image)
                            .toList();

                        if (imageAssets.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(IconsaxPlusLinear.gallery_slash,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black26),
                                const SizedBox(width: 8),
                                Text('No images in library yet',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38)),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            SizedBox(
                              height: 160,
                              child: GridView.builder(
                                scrollDirection: Axis.horizontal,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                                itemCount: imageAssets.length > 10 ? 10 : imageAssets.length,
                                itemBuilder: (context, index) {
                                  final asset = imageAssets[index];
                                  return _buildAssetPickerTile(
                                      asset, company, isDark, ctx);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                ),
                                onPressed: () => _openFullLibraryPicker(context, company, isDark, ctx),
                                icon: const Icon(IconsaxPlusLinear.grid_9, size: 16),
                                label: const Text('Browse Full Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                              ),
                            )
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    Text(
                      '✦ Selecting an asset auto-syncs the company emblem and updates all linked views instantly.',
                      style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyLogo(Company company, double size) {
    if (company.logoUrl != null && company.logoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipOval(
          child: EbmImage(
            source: company.logoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: _defaultIcon(size),
          ),
        ),
      );
    }
    return _defaultIcon(size);
  }

  Widget _defaultIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Icon(IconsaxPlusLinear.building_3,
          color: Colors.white, size: size * 0.5),
    );
  }

  Widget _buildDivider(String label, bool isDark) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: isDark ? Colors.white12 : Colors.black12, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
            child: Divider(
                color: isDark ? Colors.white12 : Colors.black12, height: 1)),
      ],
    );
  }

  Widget _buildAssetPickerTile(
      AssetModel asset, Company company, bool isDark, BuildContext ctx) {
    return InkWell(
      onTap: () {
        ctx.read<CompanyProvider>().updateCompanyLogo(company.id, 'asset://${asset.id}');
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${asset.name}" synced as company emblem'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildAssetThumb(asset),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Text(
                    asset.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetThumb(AssetModel asset) {
    return EbmImage(
      source: 'asset://${asset.id}',
      fit: BoxFit.cover,
      cacheWidth: 200,
      errorWidget: _thumbFallback(),
    );
  }

  Widget _thumbFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Center(
        child:
            Icon(IconsaxPlusLinear.gallery, size: 20, color: AppColors.primary),
      ),
    );
  }
  void _openFullLibraryPicker(BuildContext context, Company company, bool isDark, BuildContext dialogCtx) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Asset Library Picker',
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              width: MediaQuery.of(ctx).size.width * 0.85,
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: const EdgeInsets.all(0),
              borderRadius: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pick Organizational Asset', 
                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Search and select from your corporate library',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                      ],
                    ),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(IconsaxPlusLinear.close_circle, color: isDark ? Colors.white : Colors.black),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: AssetLibraryScreen(
                    isPickerMode: true,
                    onAssetSelected: (asset) {
                      context.read<CompanyProvider>().updateCompanyLogo(company.id, 'asset://${asset.id}');
                      Navigator.pop(ctx); // Close library
                      Navigator.pop(dialogCtx); // Close logo selection dialog
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(IconsaxPlusLinear.tick_circle, color: Colors.white, size: 18),
                              const SizedBox(width: 12),
                              Text('Corporate identity updated with "${asset.name}"'),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Blueprint Tab (Editing Engine) ──────────────────────────────────────────

  Widget _buildBlueprintTab(Company company, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Architect Blueprint', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text('Configure organizational identity and strategic roadmaps.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _saveBlueprint(company),
                icon: const Icon(IconsaxPlusLinear.save_2, size: 18),
                label: const Text('Save Blueprint', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          _buildBlueprintSection(
            'Core Identity',
            IconsaxPlusLinear.info_circle,
            isDark,
            [
              _buildBlueprintField('Company Name', _nameController, IconsaxPlusLinear.building, isDark),
              _buildBlueprintField('Brief (Max 100 words)', _shortDescController, IconsaxPlusLinear.text, isDark, maxLines: 2, inputFormatters: [WordLimitFormatter(100)]),
              _buildBlueprintField('Details (Max 50k words)', _fullDescController, IconsaxPlusLinear.document_text, isDark, maxLines: 5, inputFormatters: [WordLimitFormatter(50000)]),
            ],
          ),
          
          _buildOnlinePlatformBlueprintSection(company, isDark),
          
          _buildBlueprintSection(
            'Execution Roadmap',
            IconsaxPlusLinear.routing,
            isDark,
            [
              _buildBlueprintField('Current Execution State', _roadmapExecutionController, IconsaxPlusLinear.activity, isDark, maxLines: 3),
              _buildBlueprintField('Target Roadmap / Goals', _targetRoadmapController, IconsaxPlusLinear.flag, isDark, maxLines: 3),
            ],
          ),
          
          _buildBlueprintSection(
            'Governance & Agreements',
            IconsaxPlusLinear.judge,
            isDark,
            [
              _buildBlueprintField('Governance Title', _agreementShortDescController, IconsaxPlusLinear.text_block, isDark),
              _buildBlueprintField('Governance Description (150 words target)', _agreementFullDescController, IconsaxPlusLinear.document_text, isDark, maxLines: 4),
              _buildBlueprintField('Agreement Link / Document', _agreementLinkController, IconsaxPlusLinear.link, isDark),
            ],
          ),
          
          _buildBlueprintSection(
            'Authority',
            IconsaxPlusLinear.verify,
            isDark,
            [
              _buildBlueprintField('Executive Signature (Manager)', _signatureController, IconsaxPlusLinear.edit_2, isDark),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBlueprintSection(String title, IconData icon, bool isDark, List<Widget> fields) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 16),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: fields.expand((f) => [f, const SizedBox(height: 16)]).toList()..removeLast(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintField(String label, TextEditingController controller, IconData icon, bool isDark, {int maxLines = 1, List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: isDark ? Colors.white24 : Colors.black26),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  void _saveBlueprint(Company company) {
    DateTime? managerTimestamp = company.managerSignatureTimestamp;
    
    // Auto-update timestamp if manager signature changed
    if (_signatureController.text != company.managerSignature && _signatureController.text.isNotEmpty) {
      managerTimestamp = DateTime.now();
    }

    final updatedCompany = company.copyWith(
      name: _nameController.text,
      shortDescription: _shortDescController.text,
      fullDescription: _fullDescController.text,
      brandingInfo: _brandingController.text,
      agreementLink: _agreementLinkController.text,
      agreementShortDesc: _agreementShortDescController.text,
      agreementFullDesc: _agreementFullDescController.text,
      roadmapExecution: _roadmapExecutionController.text,
      targetRoadmap: _targetRoadmapController.text,
      managerSignature: _signatureController.text,
      managerSignatureTimestamp: managerTimestamp,
    );

    context.read<CompanyProvider>().updateCompany(updatedCompany);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Architecture Blueprint saved successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Online Platform Blueprint Section ─────────────────────────────────────

  Widget _buildOnlinePlatformBlueprintSection(Company company, bool isDark) {
    final platforms = List<Map<String, String>>.from(company.onlinePlatforms);

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(IconsaxPlusLinear.global, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Online Platform',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black)),
                  ),
                  _buildAddPlatformButton(context, company, platforms, isDark, setInnerState),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Websites and agents under this company. Add title, icon and link.',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: platforms.isEmpty
                    ? _buildPlatformEmptyState(isDark)
                    : Column(
                        children: List.generate(platforms.length, (i) {
                          final p = platforms[i];
                          return _buildPlatformListTile(
                              context, company, platforms, i, p, isDark, setInnerState);
                        }),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlatformEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(IconsaxPlusLinear.link, size: 32,
                color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 8),
            Text('No platforms added yet',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 4),
            Text('Tap + to add websites or agents',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white24 : Colors.black26)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformListTile(
      BuildContext context,
      Company company,
      List<Map<String, String>> platforms,
      int index,
      Map<String, String> platform,
      bool isDark,
      StateSetter setInnerState) {
    final iconName = platform['icon'] ?? '';
    final title = platform['title'] ?? 'Untitled';
    final link = platform['link'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          // Icon preview
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: iconName.startsWith('asset://')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: EbmImage(
                      source: iconName,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorWidget: Icon(IconsaxPlusLinear.global,
                          size: 18, color: AppColors.primary),
                    ),
                  )
                : Icon(IconsaxPlusLinear.global,
                    size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          // Title + Link
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (link.isNotEmpty)
                  Text(
                    link,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Docs button
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(IconsaxPlusLinear.document_text_1,
                    size: 16,
                    color: (platform['doc']?.isNotEmpty == true)
                        ? AppColors.primary
                        : (isDark ? Colors.white38 : Colors.black38)),
                if (platform['doc']?.isNotEmpty == true)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: platform['doc']?.isNotEmpty == true
                ? 'Edit Doc'
                : 'Create Doc',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => PlatformDocEditorScreen(
                    platformTitle: title,
                    initialContent: platform['doc'] ?? '',
                    onSave: (newContent) {
                      final List<Map<String, String>> updatedPlatforms =
                          List.from(platforms);
                      updatedPlatforms[index] = {
                        ...updatedPlatforms[index],
                        'doc': newContent,
                      };
                      context
                          .read<CompanyProvider>()
                          .updateOnlinePlatforms(company.id, updatedPlatforms);
                    },
                  ),
                ),
              );
            },
          ),
          // Edit button
          IconButton(
            icon: Icon(IconsaxPlusLinear.edit_2,
                size: 16,
                color: isDark ? Colors.white54 : Colors.black45),
            tooltip: 'Edit',
            onPressed: () => _openPlatformDialog(
                context, company, platforms, isDark, setInnerState,
                editIndex: index),
          ),
          // Remove button
          IconButton(
            icon: Icon(IconsaxPlusLinear.minus_square,
                size: 16, color: AppColors.error.withValues(alpha: 0.7)),
            tooltip: 'Remove',
            onPressed: () {
              setInnerState(() => platforms.removeAt(index));
              context
                  .read<CompanyProvider>()
                  .updateOnlinePlatforms(company.id, List.from(platforms));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddPlatformButton(
      BuildContext context,
      Company company,
      List<Map<String, String>> platforms,
      bool isDark,
      StateSetter setInnerState) {
    return GestureDetector(
      onTap: () => _openPlatformDialog(
          context, company, platforms, isDark, setInnerState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(IconsaxPlusLinear.add, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text('Add',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _openPlatformDialog(
      BuildContext context,
      Company company,
      List<Map<String, String>> platforms,
      bool isDark,
      StateSetter setInnerState,
      {int? editIndex}) {
    final isEdit = editIndex != null;
    final existing = isEdit ? platforms[editIndex] : null;
    final titleCtrl =
        TextEditingController(text: existing?['title'] ?? '');
    final linkCtrl =
        TextEditingController(text: existing?['link'] ?? '');
    String iconSource = existing?['icon'] ?? '';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Platform Dialog',
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (ctx, setDialogState) {
                return GlassContainer(
                  width: 460,
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEdit ? 'Edit Platform' : 'Add Platform',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            IconButton(
                              icon: Icon(IconsaxPlusLinear.close_circle,
                                  color:
                                      isDark ? Colors.white : Colors.black),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Title Field
                        Text('Platform Title',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleCtrl,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. Main Website, Support Agent...',
                            hintStyle: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38),
                            prefixIcon: Icon(IconsaxPlusLinear.text,
                                size: 16,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.black26),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Link Field
                        Text('URL / Link',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: linkCtrl,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'https://...',
                            hintStyle: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38),
                            prefixIcon: Icon(IconsaxPlusLinear.link,
                                size: 16,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.black26),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Icon Picker
                        Text('Icon (from Asset Library)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: 'Icon Picker',
                              pageBuilder: (ictx, _, __) => Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: GlassContainer(
                                    width: MediaQuery.of(context).size.width *
                                        0.85,
                                    height:
                                        MediaQuery.of(context).size.height *
                                            0.85,
                                    padding: EdgeInsets.zero,
                                    borderRadius: 24,
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(24),
                                      child: Scaffold(
                                        backgroundColor: Colors.transparent,
                                        appBar: AppBar(
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                          title: Text(
                                              'Select Platform Icon',
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          automaticallyImplyLeading: false,
                                          actions: [
                                            IconButton(
                                              onPressed: () =>
                                                  Navigator.pop(ictx),
                                              icon: Icon(
                                                  IconsaxPlusLinear
                                                      .close_circle,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                        body: AssetLibraryScreen(
                                          isPickerMode: true,
                                          onAssetSelected: (asset) {
                                            setDialogState(() {
                                              iconSource =
                                                  'asset://${asset.id}';
                                            });
                                            Navigator.pop(ictx);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: iconSource.isNotEmpty &&
                                          iconSource.startsWith('asset://')
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: EbmImage(
                                            source: iconSource,
                                            fit: BoxFit.cover,
                                            errorWidget: Icon(
                                                IconsaxPlusLinear.gallery,
                                                size: 18,
                                                color: AppColors.primary),
                                          ),
                                        )
                                      : Icon(IconsaxPlusLinear.gallery_add,
                                          size: 20, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    iconSource.isNotEmpty
                                        ? 'Icon selected ✓ (tap to change)'
                                        : 'Tap to pick icon from asset library',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54),
                                  ),
                                ),
                                Icon(IconsaxPlusLinear.arrow_right_3,
                                    size: 14,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final t = titleCtrl.text.trim();
                              if (t.isEmpty) return;
                              final entry = {
                                'title': t,
                                'link': linkCtrl.text.trim(),
                                'icon': iconSource,
                              };
                              setInnerState(() {
                                if (isEdit) {
                                  platforms[editIndex] = entry;
                                } else {
                                  platforms.add(entry);
                                }
                              });
                              context
                                  .read<CompanyProvider>()
                                  .updateOnlinePlatforms(
                                      company.id, List.from(platforms));
                              Navigator.pop(ctx);
                            },
                            icon: Icon(
                                isEdit
                                    ? IconsaxPlusLinear.save_2
                                    : IconsaxPlusLinear.add,
                                size: 16),
                            label: Text(
                              isEdit ? 'Update Platform' : 'Add Platform',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Records Tab (Premium Display) ──────────────────────────────────────────

  Widget _buildExpandableText({
    required String text,
    required int wordLimit,
    required TextStyle style,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= wordLimit) {
      return Text(text, style: style);
    }

    final displayText = isExpanded ? text : '${words.take(wordLimit).join(' ')}...';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayText, style: style),
        const SizedBox(height: 4),
        InkWell(
          onTap: onToggle,
          child: Text(
            isExpanded ? 'Collapse' : 'See more',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: (style.fontSize ?? 14) - 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsTab(Company company, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // ── HERO: Company Identity Banner (Premium Profile Layout) ──────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Photo Gradient ──────────────────────────────────
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [AppColors.primary.withValues(alpha: 0.5), AppColors.secondary.withValues(alpha: 0.2)]
                        : [AppColors.primary.withValues(alpha: 0.15), AppColors.secondary.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(IconsaxPlusLinear.building_3, size: 150, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)),
                      ),
                    ],
                  ),
                ),
                
                // ── Profile Identity Row ──────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isVerySmall = constraints.maxWidth < 400;
                            return Wrap(
                              crossAxisAlignment: WrapCrossAlignment.end,
                              spacing: 20,
                              runSpacing: 12,
                              children: [
                                // Logo (Profile Pic)
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: _buildCompanyLogo(company, isVerySmall ? 80 : 100),
                                ),
                                
                                // Identity Details
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      company.name,
                                      style: TextStyle(
                                        fontSize: isVerySmall ? 22 : 28,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // CID Chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(IconsaxPlusLinear.copy, size: 12, color: AppColors.primary),
                                              const SizedBox(width: 6),
                                              Text(
                                                company.id,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Category
                                        Text(
                                          company.categories.isNotEmpty ? company.categories.first.toUpperCase() : "UNCATEGORIZED",
                                          style: TextStyle(
                                            color: isDark ? Colors.white38 : Colors.black38,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        
                                        // Facebook Link
                                        if (company.socialLinks?.containsKey('facebook') == true || company.socialLinks?.containsKey('Facebook') == true) ...[
                                          const SizedBox(width: 12),
                                          const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 20),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // ── Description / Motto ─────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BRIEF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: AppColors.primary.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildExpandableText(
                              text: company.shortDescription?.isNotEmpty == true
                                  ? company.shortDescription!
                                  : 'Strategic organization identity pending brief deployment.',
                              wordLimit: 25,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                              isExpanded: _isBriefExpanded,
                              onToggle: () {
                                setState(() {
                                  _isBriefExpanded = !_isBriefExpanded;
                                });
                              },
                            ),
                            if (company.fullDescription?.isNotEmpty == true) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(IconsaxPlusLinear.document_text, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                                        const SizedBox(width: 8),
                                        Text('DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: isDark ? Colors.white38 : Colors.black38)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildExpandableText(
                                      text: company.fullDescription!,
                                      wordLimit: 100,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white60 : Colors.black87,
                                        height: 1.6,
                                      ),
                                      isExpanded: _isDetailsExpanded,
                                      onToggle: () {
                                        setState(() {
                                          _isDetailsExpanded = !_isDetailsExpanded;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        // ── Online Platform (below Details) ─────────────────
                        if (company.onlinePlatforms.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildOnlinePlatformRecordSection(company, isDark),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Strategy & Roadmaps ─────────────────────────────────────────
          _buildRecordCard('Strategy & Roadmaps', IconsaxPlusLinear.routing, isDark, [
            _buildRecordRow('Current Execution', company.roadmapExecution ?? 'Pending execution deployment', isDark, isMultiLine: true),
            _buildRecordRow('Future Target', company.targetRoadmap ?? 'Targets not established', isDark, isMultiLine: true),
          ]),

          // ── Governance & Agreements (Full Width) ────────────────────────
          _buildRecordCard('Governance & Agreements', IconsaxPlusLinear.judge, isDark, [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: company.agreementLink != null && company.agreementLink!.isNotEmpty 
                    ? () => _launchURL(company.agreementLink!) 
                    : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          company.agreementShortDesc?.isNotEmpty == true 
                            ? company.agreementShortDesc! 
                            : 'Governance Title Pending',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            decoration: company.agreementLink != null && company.agreementLink!.isNotEmpty 
                                ? TextDecoration.underline 
                                : null,
                          ),
                        ),
                        if (company.agreementLink != null && company.agreementLink!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(IconsaxPlusLinear.link, size: 14, color: AppColors.primary),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildExpandableText(
                  text: company.agreementFullDesc?.isNotEmpty == true 
                      ? company.agreementFullDesc! 
                      : 'Organizational governance and agreement context has not been deployed yet for this blueprint.',
                  wordLimit: 150,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.6,
                  ),
                  isExpanded: _isGovernanceExpanded,
                  onToggle: () {
                    setState(() {
                      _isGovernanceExpanded = !_isGovernanceExpanded;
                    });
                  },
                ),
              ],
            ),
          ]),

          // ── Authority & Validation (Full Width Dual Signature) ───────────
          _buildRecordCard('Authority & Validation', IconsaxPlusLinear.verify, isDark, [
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Executive Signature
                  Expanded(
                    child: _buildSignatureBlock(
                      'EXECUTIVE SIGNATURE',
                      company.managerSignature ?? 'UNAUTHORIZED',
                      company.managerSignatureTimestamp,
                      isDark,
                    ),
                  ),
                  
                  // Divider
                  if (isWide)
                    Container(
                      width: 1,
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    )
                  else
                    const SizedBox(width: 16),

                  // Right: Founder Signature
                  Expanded(
                    child: _buildSignatureBlock(
                      'FOUNDER SIGNATURE',
                      company.founderSignature ?? 'PENDING DEPLOYMENT',
                      company.founderSignatureTimestamp,
                      isDark,
                      isFounder: true,
                    ),
                  ),
                ],
              );
            }),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOnlinePlatformRecordSection(Company company, bool isDark) {
    final platforms = company.onlinePlatforms;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(IconsaxPlusLinear.global,
                    color: AppColors.primary, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'ONLINE PLATFORM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${platforms.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount;
              if (width >= 1000) {
                crossAxisCount = 8;
              } else if (width >= 700) {
                crossAxisCount = 6;
              } else if (width >= 400) {
                crossAxisCount = 4;
              } else {
                crossAxisCount = 3;
              }
              final visiblePlatforms = platforms;

              return Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: visiblePlatforms.length,
                    itemBuilder: (context, i) {
                      return _buildPlatformRecordCard(
                          company, visiblePlatforms[i], isDark);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformRecordCard(
      Company company, Map<String, String> platform, bool isDark) {
    final iconSource = platform['icon'] ?? '';
    final title = platform['title'] ?? 'Untitled';
    final link = platform['link'] ?? '';
    final hasLink = link.isNotEmpty;
    final hasDoc = platform['doc']?.isNotEmpty == true;

    Future<void> openLink() async {
      if (!hasLink) return;
      final uri = Uri.tryParse(
          link.startsWith('http') ? link : 'https://$link');
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return MouseRegion(
      cursor: hasLink
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.035)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            // ── Main Body (Icon + Title) ──
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.03) 
                            : Colors.black.withValues(alpha: 0.015),
                        shape: BoxShape.circle,
                      ),
                      child: iconSource.startsWith('asset://')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: EbmImage(
                                source: iconSource,
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                errorWidget: Icon(
                                  IconsaxPlusLinear.global,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            )
                          : Icon(
                              IconsaxPlusLinear.global,
                              size: 18,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ── Action Bar (Visit & Docs Icons) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.06) 
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(13),
                  bottomRight: Radius.circular(13),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Visit Button (Link or Lock)
                  Expanded(
                    child: GestureDetector(
                      onTap: hasLink ? openLink : null,
                      behavior: HitTestBehavior.opaque,
                      child: Tooltip(
                        message: hasLink ? 'Visit Platform' : 'Access Restricted',
                        child: Icon(
                          hasLink ? IconsaxPlusLinear.export_1 : IconsaxPlusLinear.lock,
                          size: 11,
                          color: hasLink 
                              ? AppColors.success 
                              : (isDark ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.25)),
                        ),
                      ),
                    ),
                  ),
                  // Divider
                  Container(
                    width: 0.8,
                    height: 12,
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                  ),
                  // Docs View Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => PlatformDocViewScreen(
                              company: company,
                              platform: platform,
                            ),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Tooltip(
                        message: hasDoc ? 'Review Documentation' : 'No documentation',
                        child: Icon(
                          IconsaxPlusLinear.document_text_1,
                          size: 11,
                          color: hasDoc 
                              ? AppColors.primary 
                              : (isDark ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.25)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );


  }

  Widget _buildRecordCard(String title, IconData icon, bool isDark, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 16),
          GlassContainer(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows.expand((r) => [r, Divider(height: 32, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))]).toList()..removeLast(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String label, String value, bool isDark, {bool isMultiLine = false, bool isLink = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color ?? (isLink ? AppColors.primary : (isDark ? Colors.white : Colors.black)),
            fontWeight: isLink ? FontWeight.bold : FontWeight.normal,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureBlock(String label, String signature, DateTime? timestamp, bool isDark, {bool isFounder = false}) {
    final bool hasSignature = signature != 'UNAUTHORIZED' && signature != 'PENDING DEPLOYMENT' && signature.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 6),
            if (hasSignature)
              Icon(IconsaxPlusBold.verify, size: 10, color: AppColors.success.withValues(alpha: 0.6)),
          ],
        ),
        const SizedBox(height: 12),
        
        // Handwriting Signature View
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            signature,
            style: GoogleFonts.caveat(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: hasSignature 
                  ? (isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.85))
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Timestamp / Date
        if (hasSignature && timestamp != null)
          Text(
            'Digitally Verified: ${DateFormat('MMM dd, yyyy | hh:mm a').format(timestamp)}',
            style: TextStyle(
              fontSize: 8,
              color: isDark ? Colors.white24 : Colors.black26,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            isFounder ? 'Awaiting Founder Authorization' : 'Signature pending blueprint deployment',
            style: TextStyle(
              fontSize: 8,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
            ),
          ),
      ],
    );
  }

  void _showDeployProjectDialog(BuildContext context, Company company, bool isDark) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(IconsaxPlusLinear.folder_add, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('Deploy Project', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Project Name',
                hintText: 'e.g. Infrastructure Overhaul',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Brief Description',
                hintText: 'High-level objective...',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final pp = context.read<ProjectProvider>();
                final projectId = await pp.deployProject(
                  name: nameCtrl.text.trim(),
                  companyId: company.id,
                  description: descCtrl.text.trim(),
                );
                
                if (ctx.mounted) Navigator.pop(ctx);
                
                if (projectId != null && context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deployment Sequence Successful!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Execute Deploy', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }
}
