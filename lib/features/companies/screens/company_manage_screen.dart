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
import 'package:ebficbm/core/config/app_config.dart';

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

  final List<String> _tabNames = ['Overview', 'Analytics', 'Project Hub', 'Settings'];
  final List<IconData> _tabIcons = [
    IconsaxPlusLinear.element_3,
    IconsaxPlusLinear.chart_2,
    IconsaxPlusLinear.folder_open,
    IconsaxPlusLinear.setting_2
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProvider>();
    // If we're updating categories, the company might update too. 
    // We use allCompanies to ensure we find it even if filter excludes it.
    final match = provider.allCompanies.where((c) => c.id == widget.companyId);
    if (match.isEmpty) {
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
              iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
              title: Text(company.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(IconsaxPlusLinear.close_circle),
                  tooltip: 'Back to Companies',
                ),
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
            ? Container(
                margin: const EdgeInsets.all(16),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: _buildTabContent(company, isDark),
                ),
              )
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
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = _buildOverviewTab(company, isDark);
        break;
      case 1:
        content = _buildAnalyticsTab(company, isDark);
        break;
      case 2:
        content = _buildProjectHubTab(company, isDark);
        break;
      case 3:
        content = _buildSettingsTab(company, isDark);
        break;
      default:
        content = const SizedBox();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Project Deployments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ElevatedButton.icon(
              onPressed: () {
                // Future Implementation: Add/Deploy Project Popup matching Deep Workspace idea
              },
              icon: const Icon(IconsaxPlusLinear.add, size: 16),
              label: const Text('Deploy Network'),
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
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: projects.length,
            itemBuilder: (context, index) {
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
                                Text(proj.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                                const SizedBox(height: 4),
                                Text(proj.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          // View Workspace Button
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
                             child: const Text('Open Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        ],
                     ),
                     const SizedBox(height: 24),
                     Row(
                        children: [
                           Expanded(
                              child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Text('Budget Trajectory', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: proj.totalBudget == 0 ? 0 : proj.consumedBudget / proj.totalBudget,
                                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                      color: proj.brandColor,
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    const SizedBox(height: 8),
                                    Text('\$${proj.consumedBudget.toStringAsFixed(0)} / \$${proj.totalBudget.toStringAsFixed(0)}', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                        Text('Task Completion Engine', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                          color: AppColors.success,
                                          minHeight: 6,
                                          borderRadius: BorderRadius.circular(4)
                                        ),
                                        const SizedBox(height: 8),
                                        Text('${(progress * 100).toInt()}% Built', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
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
          ),
        )
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSettingsTab(Company company, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Tabs Panel - scrollable natively using devices scroll mechanisms
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
                    onTap: () {
                      setState(() => _settingsTabIndex = index);
                    },
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
        // Tab Pages
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _buildSettingsTabContent(company, isDark, _settingsTabIndex),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
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
}
