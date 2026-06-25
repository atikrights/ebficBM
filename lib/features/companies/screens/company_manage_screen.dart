import 'dart:async';
import 'dart:ui';
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
import 'package:ebficbm/features/projects/models/project.dart' as pmod;
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
import 'package:ebficbm/core/providers/auth_provider.dart';

// Newly added imports for Quota and Stock features
import 'package:ebficbm/features/companies/models/company_external_quota.dart';
import 'package:ebficbm/features/companies/models/company_stock.dart';
import 'package:ebficbm/features/companies/providers/company_external_quota_provider.dart';
import 'package:ebficbm/features/companies/providers/company_stock_provider.dart';
import 'package:ebficbm/features/companies/screens/widgets/quota_manage_dialog.dart';
import 'package:ebficbm/features/companies/screens/widgets/stock_manage_dialog.dart';
import 'package:ebficbm/features/companies/screens/widgets/attach_project_dialog.dart';
import 'package:ebficbm/features/companies/screens/quota_edit_screen.dart';
import 'package:ebficbm/features/companies/screens/stock_edit_screen.dart';
import 'package:ebficbm/core/providers/td_set_provider.dart';

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

  final List<String> _tabNames = ['Overview', 'Blueprint', 'Records', 'Radar', 'External', 'Stock', 'Settings'];
  final List<IconData> _tabIcons = [
    IconsaxPlusLinear.element_3,
    IconsaxPlusLinear.edit_2,
    IconsaxPlusLinear.document_text_1,
    IconsaxPlusLinear.radar,
    IconsaxPlusLinear.wallet_money,
    IconsaxPlusLinear.box,
    IconsaxPlusLinear.setting_2
  ];

  // Records Tab Expansion States
  bool _isBriefExpanded = false;
  bool _isDetailsExpanded = false;
  bool _isGovernanceExpanded = false;

  // Founder Authorization State
  int _lastTabIndex = -1; // Track tab changes for persistent prompts
  bool _isDialogVisible = false;

  // Configure Tab State
  final TextEditingController _attachedSearchController = TextEditingController();
  final Set<pmod.ProjectStatus> _selectedStatuses = {};

  // External Tab – Quota search & filter
  final TextEditingController _quotaSearchController = TextEditingController();
  String _quotaSearchQuery = '';
  String _quotaTagFilter = '';
  bool _showTrashedQuotas = false;

  // Stock Tab – Search & filter
  final TextEditingController _stockSearchController = TextEditingController();
  String _stockSearchQuery = '';
  bool _showTrashedStocks = false;

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
    
    _attachedSearchController.dispose();
    _quotaSearchController.dispose();
    _stockSearchController.dispose();
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

    // ── FOUNDER AUTHORIZATION & BACKGROUND PRE-FETCHING LOGIC ──────────────────
    if ((_selectedIndex == 1 || _selectedIndex == 2) && 
        (_lastTabIndex != 1 && _lastTabIndex != 2) &&
        company.managerSignature != null && 
        company.managerSignature!.isNotEmpty && 
        company.managerSignature != 'UNAUTHORIZED' &&
        (company.founderSignature == null || company.founderSignature == 'PENDING DEPLOYMENT' || company.founderSignature!.isEmpty) &&
        !_isDialogVisible) {
      
      _lastTabIndex = _selectedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFounderAuthDialog(context, company);
      });
    } else if (_selectedIndex == 4 && _lastTabIndex != 4) {
      _lastTabIndex = 4;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CompanyExternalQuotaProvider>().fetchQuotas(widget.companyId, showTrashed: _showTrashedQuotas);
      });
    } else if (_selectedIndex == 5 && _lastTabIndex != 5) {
      _lastTabIndex = 5;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CompanyStockProvider>().fetchStocks(widget.companyId, showTrashed: _showTrashedStocks);
      });
    } else if (_selectedIndex != 1 && _selectedIndex != 2 && _selectedIndex != 4 && _selectedIndex != 5) {
      _lastTabIndex = _selectedIndex;
    }

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
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(isDrawer ? IconsaxPlusLinear.close_circle : IconsaxPlusLinear.arrow_left, color: textColor),
                tooltip: isDrawer ? 'Close Menu' : 'Back to Registry',
              ),
            ),
            const SizedBox(height: 16),
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
                         Navigator.pop(context);
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
            ElevatedButton.icon(
              onPressed: () {
                if (company.website.isNotEmpty) {
                  _launchURL(company.website);
                }
              },
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
        content = KeyedSubtree(key: const ValueKey('radar'), child: _EbmStrategicCompanyRadar(company: company));
        break;
      case 4:
        content = KeyedSubtree(key: const ValueKey('external'), child: _buildExternalTab(company, isDark));
        break;
      case 5:
        content = KeyedSubtree(key: const ValueKey('stock'), child: _buildStockTab(company, isDark));
        break;
      case 6:
        content = KeyedSubtree(key: const ValueKey('settings'), child: _buildSettingsContainer(company, isDark));
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

  // ── Overview Tab (Glassmorphic Interface) ───────────────────────────────────

  Widget _buildOverviewTab(Company company, bool isDark) {
    final cs = context.watch<TdSetProvider>().currencySymbol;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1000;

    // 1. Live Assets valuation calculations
    final stocksProvider = context.watch<CompanyStockProvider>();
    final stocks = stocksProvider.stocks;
    double totalMinAssetPrice = 0.0;
    double totalMaxAssetPrice = 0.0;
    for (final stock in stocks) {
      for (final asset in stock.assets) {
        totalMinAssetPrice += asset.minPrice;
        totalMaxAssetPrice += asset.maxPrice;
      }
    }
    final hasAssets = stocks.any((s) => s.assets.isNotEmpty);

    // 2. Financial ledger / Quotas calculations
    final quotasProvider = context.watch<CompanyExternalQuotaProvider>();
    final quotas = quotasProvider.quotas;
    double totalEarn = 0.0;
    double totalExpense = 0.0;
    for (final quota in quotas) {
      totalEarn += quota.earn;
      totalExpense += quota.expense;
    }
    final netBalance = totalEarn - totalExpense;

    // 3. Projects execution calculations
    final projects = context.watch<ProjectProvider>().getProjectsForCompany(company.id);
    final totalProjects = projects.length;
    final activeProjects = projects.where((p) => p.status == pmod.ProjectStatus.inProgress).length;
    final planningProjects = projects.where((p) => p.status == pmod.ProjectStatus.planned).length;
    final completedProjects = projects.where((p) => p.status == pmod.ProjectStatus.completed).length;
    final otherProjects = totalProjects - activeProjects - planningProjects - completedProjects;
    final double completionRate = totalProjects > 0 ? (completedProjects / totalProjects) : 0.0;

    final mainDashboard = isMobile || isTablet
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoSection(company, isDark),
              const SizedBox(height: 20),
              _buildValuationSection(stocks, isDark),
              const SizedBox(height: 20),
              _buildQuotaLedgerSection(totalEarn, totalExpense, netBalance, isDark),
              const SizedBox(height: 20),
              _buildProjectsHubSection(totalProjects, activeProjects, planningProjects, completedProjects, otherProjects, completionRate, isDark),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildInfoSection(company, isDark),
                    const SizedBox(height: 20),
                    _buildValuationSection(stocks, isDark),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildQuotaLedgerSection(totalEarn, totalExpense, netBalance, isDark),
                    const SizedBox(height: 20),
                    _buildProjectsHubSection(totalProjects, activeProjects, planningProjects, completedProjects, otherProjects, completionRate, isDark),
                  ],
                ),
              ),
            ],
          );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 3.0 : 1.7,
            children: [
              _buildStatCard('Active Employees', company.activeEmployees.toString(), IconsaxPlusLinear.people, Colors.blue, isDark),
              _buildStatCard('Annual Revenue', '$cs${(company.annualRevenue / 1000000).toStringAsFixed(1)}M', IconsaxPlusLinear.money_send, Colors.green, isDark),
              _buildStatCard('Health Score', '${(company.healthScore * 100).toInt()}%', IconsaxPlusLinear.heart, Colors.red, isDark),
              _buildStatCard('Live Assets Valuation', hasAssets ? '$cs${(totalMinAssetPrice / 1000).toStringAsFixed(1)}K - $cs${(totalMaxAssetPrice / 1000).toStringAsFixed(1)}K' : '${cs}0', IconsaxPlusLinear.wallet_3, Colors.orange, isDark),
            ],
          ),
          const SizedBox(height: 24),
          mainDashboard,
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Manrope',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuationSection(List<CompanyStock> stocks, bool isDark) {
    final cs = context.watch<TdSetProvider>().currencySymbol;
    final activeStocks = stocks.where((s) => s.assets.isNotEmpty).toList();
    double grandTotalMax = activeStocks.fold(0.0, (sum, s) => sum + s.assets.fold(0.0, (sumA, a) => sumA + a.maxPrice));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Asset Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${activeStocks.length} Valuation Registries',
                  style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (activeStocks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 40, color: isDark ? Colors.white24 : Colors.black.withOpacity(0.24)),
                    const SizedBox(height: 12),
                    Text(
                      'No assets registered yet',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeStocks.length,
              itemBuilder: (context, idx) {
                final stock = activeStocks[idx];
                final minVal = stock.assets.fold(0.0, (sum, a) => sum + a.minPrice);
                final maxVal = stock.assets.fold(0.0, (sum, a) => sum + a.maxPrice);
                final percent = grandTotalMax > 0 ? (maxVal / grandTotalMax) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stock.stkCode,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                stock.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$cs${minVal.toStringAsFixed(0)} - $cs${maxVal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percent.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuotaLedgerSection(double totalEarn, double totalExpense, double netBalance, bool isDark) {
    final cs = context.watch<TdSetProvider>().currencySymbol;
    final double totalCombined = totalEarn + totalExpense;
    final double earnPercent = totalCombined > 0 ? (totalEarn / totalCombined) : 0.5;
    final isPositive = netBalance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Quota Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Icon(
                IconsaxPlusLinear.activity,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL EARNINGS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$cs${totalEarn.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.success, fontFamily: 'Manrope'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL EXPENSES',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$cs${totalExpense.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error, fontFamily: 'Manrope'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Balance Score',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black.withOpacity(0.7)),
                ),
                Text(
                  (isPositive ? '+' : '') + '$cs${netBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Earnings Ratio', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                  Text('${(earnPercent * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black.withOpacity(0.7))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: earnPercent,
                    backgroundColor: AppColors.error.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsHubSection(
    int total, 
    int active, 
    int planning, 
    int completed, 
    int other, 
    double completionRate, 
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attached Projects Hub',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$total Projects',
                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 40, color: isDark ? Colors.white24 : Colors.black.withOpacity(0.24)),
                    const SizedBox(height: 12),
                    Text(
                      'No projects linked to this workspace',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _projectBreakdownItem('PLANNING', planning, Colors.blue, isDark),
                _projectBreakdownItem('ACTIVE', active, Colors.orange, isDark),
                _projectBreakdownItem('COMPLETED', completed, AppColors.success, isDark),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Project Completion Rate',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black.withOpacity(0.7)),
                    ),
                    Text(
                      '${(completionRate * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: completionRate,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _projectBreakdownItem(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Company company, bool isDark) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organization Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Primary Category', company.categories.join(', '), isDark, isMobile),
          _buildInfoRow('Official Website', company.website, isDark, isMobile),
          _buildInfoRow('Corporate Email', company.primaryEmail, isDark, isMobile),
          _buildInfoRow('Direct Phone', company.phone, isDark, isMobile),
          _buildInfoRow('Global Location', company.location, isDark, isMobile),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, bool isMobile) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
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
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                                        const SizedBox(width: 16),
                                        Text(
                                          company.categories.isNotEmpty ? company.categories.first.toUpperCase() : "UNCATEGORIZED",
                                          style: TextStyle(
                                            color: isDark ? Colors.white38 : Colors.black38,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
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
                              wordLimit: 40,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                              isExpanded: _isBriefExpanded,
                              onToggle: () => setState(() => _isBriefExpanded = !_isBriefExpanded),
                            ),
                            if (company.fullDescription?.isNotEmpty == true) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(20),
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
                                      wordLimit: 120,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white60 : Colors.black87,
                                        height: 1.7,
                                      ),
                                      isExpanded: _isDetailsExpanded,
                                      onToggle: () => setState(() => _isDetailsExpanded = !_isDetailsExpanded),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        if (company.onlinePlatforms.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildOnlinePlatformRecordSection(company, isDark),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          


          _buildRecordCard('Strategy & Roadmaps', IconsaxPlusLinear.routing, isDark, [
            _buildRecordRow('Current Execution', company.roadmapExecution ?? 'Pending execution deployment', isDark, isMultiLine: true),
            _buildRecordRow('Future Target', company.targetRoadmap ?? 'Targets not established', isDark, isMultiLine: true),
          ]),

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
                    height: 1.7,
                  ),
                  isExpanded: _isGovernanceExpanded,
                  onToggle: () => setState(() => _isGovernanceExpanded = !_isGovernanceExpanded),
                ),
              ],
            ),
          ]),

          _buildRecordCard('Authority & Validation', IconsaxPlusLinear.verify, isDark, [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSignatureBlock(
                    'EXECUTIVE SIGNATURE',
                    company.managerSignature ?? 'UNAUTHORIZED',
                    company.managerSignatureTimestamp,
                    isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
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
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildOnlinePlatformRecordSection(Company company, bool isDark) {
    final platforms = company.onlinePlatforms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(IconsaxPlusLinear.global, color: AppColors.primary, size: 14),
            ),
            const SizedBox(width: 10),
            Text(
              'ONLINE PLATFORMS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${platforms.length}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 6 : (MediaQuery.of(context).size.width > 800 ? 4 : 2),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: platforms.length,
          itemBuilder: (context, i) => _buildPlatformRecordCard(company, platforms[i], isDark),
        ),
      ],
    );
  }

  Widget _buildPlatformRecordCard(Company company, Map<String, String> platform, bool isDark) {
    final iconSource = platform['icon'] ?? '';
    final title = platform['title'] ?? 'Untitled';
    final link = platform['link'] ?? '';
    final docId = platform['doc'] ?? '';
    final hasLink = link.isNotEmpty;
    final hasDoc = docId.isNotEmpty;

    Future<void> openLink() async {
      if (!hasLink) return;
      final uri = Uri.tryParse(link.startsWith('http') ? link : 'https://$link');
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return MouseRegion(
      cursor: hasLink ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.035) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.015),
                        shape: BoxShape.circle,
                      ),
                      child: iconSource.startsWith('asset://')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: EbmImage(source: iconSource, width: 24, height: 24, fit: BoxFit.contain),
                            )
                          : Icon(IconsaxPlusLinear.global, size: 20, color: isDark ? Colors.white30 : Colors.black26),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: hasLink ? openLink : null,
                      behavior: HitTestBehavior.opaque,
                      child: Tooltip(
                        message: hasLink ? 'Visit Platform' : 'No Link Provided',
                        child: Icon(
                          hasLink ? IconsaxPlusLinear.external_drive : IconsaxPlusLinear.lock_1,
                          size: 14,
                          color: hasLink ? AppColors.primary : (isDark ? Colors.white10 : Colors.black12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: hasDoc ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlatformDocViewScreen(
                              company: company,
                              platform: platform,
                            ),
                          ),
                        );
                      } : null,
                      behavior: HitTestBehavior.opaque,
                      child: Tooltip(
                        message: hasDoc ? 'View Document' : 'No Document Attached',
                        child: Icon(
                          IconsaxPlusLinear.document_text,
                          size: 14,
                          color: hasDoc ? const Color(0xFF8B5CF6) : (isDark ? Colors.white10 : Colors.black12),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
        const SizedBox(height: 12),
        GlassContainer(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows.expand((r) => [r, Divider(height: 30, color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))]).toList()..removeLast(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRecordRow(String label, String value, bool isDark, {bool isMultiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.6,
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
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.5),
            ),
            if (hasSignature) ...[
              const SizedBox(width: 6),
              Icon(IconsaxPlusBold.verify, size: 10, color: const Color(0xFF10B981).withValues(alpha: 0.7)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            signature,
            style: GoogleFonts.caveat(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: hasSignature 
                  ? (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.9))
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (hasSignature && timestamp != null)
          Text(
            'Digitally Verified: ${DateFormat('MMM dd, yyyy | hh:mm a').format(timestamp)}',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            isFounder ? 'Awaiting Founder Authorization' : 'Signature pending blueprint deployment',
            style: TextStyle(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
            ),
          ),
      ],
    );
  }

  void _showFounderAuthDialog(BuildContext context, Company company) {
    setState(() => _isDialogVisible = true);
    final TextEditingController signatureController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Founder Authorization',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              width: 500,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(IconsaxPlusBold.verify, color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'FOUNDER AUTHORIZATION',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Manager "${company.managerSignature}" has verified this blueprint. As the Founder/Admin, your authorization is required to finalize the organizational record.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: signatureController,
                    style: GoogleFonts.caveat(
                      fontSize: 28,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter Founder Signature',
                      hintStyle: GoogleFonts.caveat(fontSize: 20, color: isDark ? Colors.white24 : Colors.black26),
                      labelText: 'OFFICIAL SIGNATURE',
                      labelStyle: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                      prefixIcon: const Icon(IconsaxPlusLinear.edit_2, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() => _isDialogVisible = false);
                            Navigator.pop(ctx);
                          },
                          child: Text('AUTHORIZE LATER', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (signatureController.text.trim().isEmpty) return;
                            
                            final updatedCompany = company.copyWith(
                              founderSignature: signatureController.text.trim(),
                              founderSignatureTimestamp: DateTime.now(),
                            );
                            
                            await context.read<CompanyProvider>().updateCompany(updatedCompany);
                            
                            setState(() => _isDialogVisible = false);
                            if (context.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('FINALIZE RECORD', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── External Tab (Quota Management) ────────────────────────────────────────

  Map<String, List<CompanyExternalQuota>> _groupQuotasByDate(List<CompanyExternalQuota> quotas) {
    final Map<String, List<CompanyExternalQuota>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final quota in quotas) {
      final quotaDate = DateTime(quota.date.year, quota.date.month, quota.date.day);

      String header;
      if (quotaDate == today) {
        header = 'Today';
      } else if (quotaDate == yesterday) {
        header = 'Yesterday';
      } else {
        header = DateFormat('MMMM dd, yyyy').format(quotaDate);
      }

      if (!groups.containsKey(header)) {
        groups[header] = [];
      }
      groups[header]!.add(quota);
    }
    return groups;
  }

  Widget _buildExternalTab(Company company, bool isDark) {
    final quotaProvider = context.watch<CompanyExternalQuotaProvider>();
    final quotas = _showTrashedQuotas ? quotaProvider.trashedQuotas : quotaProvider.quotas;
    final trashedCount = quotaProvider.trashedQuotas.length;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    final filteredQuotas = quotas.where((quota) {
      final matchesSearch = quota.title.toLowerCase().contains(_quotaSearchQuery.toLowerCase()) ||
          quota.qid.toLowerCase().contains(_quotaSearchQuery.toLowerCase()) ||
          quota.tag.toLowerCase().contains(_quotaSearchQuery.toLowerCase());
      final matchesTag = _quotaTagFilter.isEmpty || quota.tag.toLowerCase() == _quotaTagFilter.toLowerCase();
      return matchesSearch && matchesTag;
    }).toList();

    final groupedQuotas = _groupQuotasByDate(filteredQuotas);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _showTrashedQuotas ? null : FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => QuotaManageDialog(
              onSave: (title, tag) async {
                try {
                  await quotaProvider.addQuota(company.id, title: title, tag: tag);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Quota added successfully'),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Failed to add quota: $e')),
                          ],
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Quota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  ),
                  child: TextField(
                    controller: _quotaSearchController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) {
                      setState(() {
                        _quotaSearchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search quotas (Title, QID, Tag)...',
                      hintStyle: TextStyle(color: hintColor, fontSize: 13),
                      prefixIcon: Icon(IconsaxPlusLinear.search_normal, size: 18, color: hintColor),
                      suffixIcon: _quotaSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              color: hintColor,
                              onPressed: () {
                                _quotaSearchController.clear();
                                setState(() {
                                  _quotaSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Filter by Tag',
                onSelected: (tag) {
                  setState(() {
                    if (_quotaTagFilter == tag) {
                      _quotaTagFilter = '';
                    } else {
                      _quotaTagFilter = tag;
                    }
                  });
                },
                itemBuilder: (context) {
                  final uniqueTags = quotas.map((q) => q.tag).toSet().toList();
                  if (!uniqueTags.contains('General')) uniqueTags.add('General');
                  if (!uniqueTags.contains('Marketing')) uniqueTags.add('Marketing');
                  if (!uniqueTags.contains('Development')) uniqueTags.add('Development');
                  if (!uniqueTags.contains('Operations')) uniqueTags.add('Operations');
                  
                  return [
                    PopupMenuItem<String>(
                      value: '',
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt_off_outlined,
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          const Text('All Tags', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    ...uniqueTags.map((tag) {
                      final isSelected = _quotaTagFilter.toLowerCase() == tag.toLowerCase();
                      return CheckedPopupMenuItem<String>(
                        value: tag,
                        checked: isSelected,
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      );
                    }),
                  ];
                },
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: _quotaTagFilter.isNotEmpty
                        ? AppColors.primary.withOpacity(0.15)
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _quotaTagFilter.isNotEmpty
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        IconsaxPlusLinear.filter,
                        size: 18,
                        color: _quotaTagFilter.isNotEmpty ? AppColors.primary : textColor,
                      ),
                      if (_quotaTagFilter.isNotEmpty)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Badge(
                label: Text(
                  '$trashedCount',
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                isLabelVisible: trashedCount > 0,
                backgroundColor: AppColors.error,
                child: IconButton(
                  tooltip: _showTrashedQuotas ? 'Show Active Quotas' : 'Show Recycle Bin',
                  icon: Icon(
                    _showTrashedQuotas ? Icons.delete_forever : Icons.delete_outline,
                    size: 18,
                    color: _showTrashedQuotas ? AppColors.error : textColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _showTrashedQuotas 
                        ? AppColors.error.withOpacity(0.1) 
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _showTrashedQuotas 
                            ? AppColors.error 
                            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () {
                    setState(() {
                      _showTrashedQuotas = !_showTrashedQuotas;
                    });
                    quotaProvider.fetchQuotas(company.id, showTrashed: _showTrashedQuotas);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: quotaProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredQuotas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_showTrashedQuotas ? Icons.delete_sweep_outlined : IconsaxPlusLinear.wallet_search, size: 64, color: hintColor),
                            const SizedBox(height: 16),
                            Text(
                              _showTrashedQuotas ? 'Recycle Bin is empty' : 'No quotas added yet', 
                              style: TextStyle(color: hintColor, fontSize: 16, fontWeight: FontWeight.w500)
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showTrashedQuotas ? 'Deleted items will appear here' : 'Click "Add Quota" to create your first entry', 
                              style: TextStyle(color: hintColor.withOpacity(0.8), fontSize: 12)
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: groupedQuotas.keys.length,
                        itemBuilder: (context, index) {
                          final dateHeader = groupedQuotas.keys.elementAt(index);
                          final quotasInDate = groupedQuotas[dateHeader]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        dateHeader,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Divider(
                                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: quotasInDate.length,
                                itemBuilder: (context, idx) {
                                  final quota = quotasInDate[idx];
                                  final formattedTime = DateFormat('hh:mm a').format(quota.date);
                                  final formattedDate = DateFormat('dd MMM yyyy').format(quota.date);
                                  final hasEarn = quota.earn > 0;
                                  final hasExpense = quota.expense > 0;

                                  Widget cardContent = Row(
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: hasEarn 
                                              ? AppColors.success 
                                              : (hasExpense ? AppColors.error : AppColors.primary),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              quota.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  quota.qid,
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  constraints: const BoxConstraints(maxWidth: 120),
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), width: 0.5),
                                                  ),
                                                  child: Text(
                                                    quota.tag,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? Colors.white70 : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text('•', style: TextStyle(fontSize: 10, color: hintColor)),
                                                const SizedBox(width: 8),
                                                Icon(Icons.access_time_rounded, size: 9, color: hintColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$formattedDate  •  $formattedTime',
                                                  style: TextStyle(fontSize: 9, color: hintColor, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: _buildEarnExpenseContainer(quota, hasEarn, hasExpense, isDark, hintColor),
                                      ),
                                      const SizedBox(width: 16),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _showTrashedQuotas
                                            ? [
                                                IconButton(
                                                  tooltip: 'Restore Quota',
                                                  icon: const Icon(Icons.restore_rounded, size: 16, color: AppColors.success),
                                                  onPressed: () async {
                                                    await quotaProvider.restoreQuota(company.id, quota.id);
                                                  },
                                                ),
                                                IconButton(
                                                  tooltip: 'Permanently Delete Quota',
                                                  icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.error),
                                                  onPressed: () => _showForceDeleteConfirmationDialog(context, company.id, quota, quotaProvider, isDark),
                                                ),
                                              ]
                                            : [
                                                IconButton(
                                                  tooltip: 'Edit Quota',
                                                  icon: Icon(Icons.edit_outlined, size: 16, color: hintColor),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => QuotaEditScreen(quota: quota),
                                                      ),
                                                    ).then((_) {
                                                      quotaProvider.fetchQuotas(company.id, showTrashed: false);
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  tooltip: 'Delete Quota',
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                                  onPressed: () => _showDeleteConfirmationDialog(context, company.id, quota, quotaProvider, isDark),
                                                ),
                                              ],
                                      ),
                                    ],
                                  );

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: cardContent,
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnExpenseContainer(CompanyExternalQuota quota, bool hasEarn, bool hasExpense, bool isDark, Color hintColor) {
    if (hasEarn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward_rounded, color: AppColors.success, size: 12),
            const SizedBox(width: 4),
            Text(
              '+\$${quota.earn.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      );
    } else if (hasExpense) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward_rounded, color: AppColors.error, size: 12),
            const SizedBox(width: 4),
            Text(
              '-\$${quota.expense.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return Text('No transaction', style: TextStyle(color: hintColor, fontSize: 11));
  }

  void _showDeleteConfirmationDialog(BuildContext context, String companyId, CompanyExternalQuota quota, CompanyExternalQuotaProvider provider, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quota'),
        content: Text('Are you sure you want to move quota "${quota.title}" to the Recycle Bin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteQuota(companyId, quota.id, isShowingTrashed: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForceDeleteConfirmationDialog(BuildContext context, String companyId, CompanyExternalQuota quota, CompanyExternalQuotaProvider provider, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete quota "${quota.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.forceDeleteQuota(companyId, quota.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Permanently Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Stock Tab (Valuation Registries) ───────────────────────────────────────

  Map<String, List<CompanyStock>> _groupStocksByDate(List<CompanyStock> stocks) {
    final Map<String, List<CompanyStock>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final stock in stocks) {
      final stockDate = DateTime(stock.date.year, stock.date.month, stock.date.day);

      String header;
      if (stockDate == today) {
        header = 'Today';
      } else if (stockDate == yesterday) {
        header = 'Yesterday';
      } else {
        header = DateFormat('MMMM dd, yyyy').format(stockDate);
      }

      if (!groups.containsKey(header)) {
        groups[header] = [];
      }
      groups[header]!.add(stock);
    }
    return groups;
  }

  Widget _buildStockTab(Company company, bool isDark) {
    final stockProvider = context.watch<CompanyStockProvider>();
    final stocks = _showTrashedStocks ? stockProvider.trashedStocks : stockProvider.stocks;
    final trashedCount = stockProvider.trashedStocks.length;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    final filteredStocks = stocks.where((stock) {
      return stock.title.toLowerCase().contains(_stockSearchQuery.toLowerCase()) ||
          stock.stkCode.toLowerCase().contains(_stockSearchQuery.toLowerCase());
    }).toList();

    final groupedStocks = _groupStocksByDate(filteredStocks);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _showTrashedStocks ? null : FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => StockManageDialog(
              onSave: (title) async {
                try {
                  await stockProvider.addStock(company.id, title: title);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Stock added successfully'),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Failed to add stock: $e')),
                          ],
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  ),
                  child: TextField(
                    controller: _stockSearchController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) {
                      setState(() {
                        _stockSearchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search stocks (Title, STK Code)...',
                      hintStyle: TextStyle(color: hintColor, fontSize: 13),
                      prefixIcon: Icon(IconsaxPlusLinear.search_normal, size: 18, color: hintColor),
                      suffixIcon: _stockSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              color: hintColor,
                              onPressed: () {
                                _stockSearchController.clear();
                                setState(() {
                                  _stockSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Badge(
                label: Text(
                  '$trashedCount',
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                isLabelVisible: trashedCount > 0,
                backgroundColor: AppColors.error,
                child: IconButton(
                  tooltip: _showTrashedStocks ? 'Show Active Stocks' : 'Show Recycle Bin',
                  icon: Icon(
                    _showTrashedStocks ? Icons.delete_forever : Icons.delete_outline,
                    size: 18,
                    color: _showTrashedStocks ? AppColors.error : textColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _showTrashedStocks 
                        ? AppColors.error.withOpacity(0.1) 
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _showTrashedStocks 
                            ? AppColors.error 
                            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () {
                    setState(() {
                      _showTrashedStocks = !_showTrashedStocks;
                    });
                    stockProvider.fetchStocks(company.id, showTrashed: _showTrashedStocks);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: stockProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStocks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_showTrashedStocks ? Icons.delete_sweep_outlined : IconsaxPlusLinear.box, size: 64, color: hintColor),
                            const SizedBox(height: 16),
                            Text(
                              _showTrashedStocks ? 'Recycle Bin is empty' : 'No stocks added yet', 
                              style: TextStyle(color: hintColor, fontSize: 16, fontWeight: FontWeight.w500)
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showTrashedStocks ? 'Deleted items will appear here' : 'Click "Add Stock" to create your first entry', 
                              style: TextStyle(color: hintColor.withOpacity(0.8), fontSize: 12)
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: groupedStocks.keys.length,
                        itemBuilder: (context, index) {
                          final dateHeader = groupedStocks.keys.elementAt(index);
                          final stocksInDate = groupedStocks[dateHeader]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        dateHeader,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Divider(
                                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: stocksInDate.length,
                                itemBuilder: (context, idx) {
                                  final stock = stocksInDate[idx];
                                  final totalMinPrice = stock.assets.fold(0.0, (sum, item) => sum + item.minPrice);
                                  final totalMaxPrice = stock.assets.fold(0.0, (sum, item) => sum + item.maxPrice);
                                  final hasAssets = stock.assets.isNotEmpty;

                                  final formattedTime = DateFormat('hh:mm a').format(stock.date);
                                  final formattedDate = DateFormat('dd MMM yyyy').format(stock.date);

                                  Widget cardContent = Row(
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              stock.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 0.5),
                                                  ),
                                                  child: Text(
                                                    stock.stkCode,
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.2),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text('•', style: TextStyle(fontSize: 10, color: hintColor)),
                                                const SizedBox(width: 8),
                                                Icon(Icons.access_time_rounded, size: 9, color: hintColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$formattedDate  •  $formattedTime',
                                                  style: TextStyle(fontSize: 9, color: hintColor, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildValuationBadge(totalMinPrice, totalMaxPrice, hasAssets, isDark),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _showTrashedStocks
                                            ? [
                                                IconButton(
                                                  tooltip: 'Restore Stock',
                                                  icon: const Icon(Icons.restore_rounded, size: 16, color: AppColors.success),
                                                  onPressed: () async {
                                                    await stockProvider.restoreStock(company.id, stock.id);
                                                  },
                                                ),
                                                IconButton(
                                                  tooltip: 'Permanently Delete Stock',
                                                  icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.error),
                                                  onPressed: () => _showStockForceDeleteConfirmationDialog(context, company.id, stock, stockProvider, isDark),
                                                ),
                                              ]
                                            : [
                                                IconButton(
                                                  tooltip: 'Edit Stock',
                                                  icon: Icon(Icons.edit_outlined, size: 16, color: hintColor),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => StockEditScreen(stock: stock),
                                                      ),
                                                    ).then((_) {
                                                      stockProvider.fetchStocks(company.id, showTrashed: false);
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  tooltip: 'Delete Stock',
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                                  onPressed: () => _showStockDeleteConfirmationDialog(context, company.id, stock, stockProvider, isDark),
                                                ),
                                              ],
                                      ),
                                    ],
                                  );

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: _showTrashedStocks
                                            ? null
                                            : () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => StockEditScreen(stock: stock),
                                                  ),
                                                ).then((_) {
                                                  stockProvider.fetchStocks(company.id, showTrashed: false);
                                                }),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          child: cardContent,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuationBadge(double min, double max, bool hasAssets, bool isDark) {
    if (!hasAssets) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Unvalued', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        '\$${min.toStringAsFixed(0)} - \$${max.toStringAsFixed(0)}',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  void _showStockDeleteConfirmationDialog(BuildContext context, String companyId, CompanyStock stock, CompanyStockProvider provider, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock'),
        content: Text('Are you sure you want to move stock "${stock.title}" to the Recycle Bin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteStock(companyId, stock.id, isShowingTrashed: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStockForceDeleteConfirmationDialog(BuildContext context, String companyId, CompanyStock stock, CompanyStockProvider provider, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete stock "${stock.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.forceDeleteStock(companyId, stock.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Permanently Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Settings Container & Subtabs ───────────────────────────────────────────

  Widget _buildSettingsContainer(Company company, bool isDark) {
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill('Configure', 0, AppColors.primary, textColor, isDark),
                const SizedBox(width: 8),
                _buildCategoryPill('General Settings', 1, AppColors.primary, textColor, isDark),
                const SizedBox(width: 8),
                _buildCategoryPill('Security', 2, AppColors.primary, textColor, isDark),
              ],
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              switch (_settingsTabIndex) {
                case 0: return _buildConfigureTab(company, isDark);
                case 1: return _buildPlaceholderTab('General Settings', IconsaxPlusLinear.setting_2, isDark);
                case 2: return _buildPlaceholderTab('Security', IconsaxPlusLinear.security_safe, isDark);
                default: return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill(String title, int index, Color primary, Color textCol, bool isDark) {
    final isSelected = _settingsTabIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _settingsTabIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? primary.withValues(alpha: isDark ? 0.2 : 0.1) 
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primary.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? primary : textCol,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigureTab(Company company, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white;

    final projectProvider = context.watch<ProjectProvider>();
    final allCompanyProjects = projectProvider.getProjectsForCompany(company.id);

    final filteredProjects = allCompanyProjects.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_quotaSearchQuery.toLowerCase()) || // Reuse stock/quota search or define separate if needed
          p.pid.toLowerCase().contains(_quotaSearchQuery.toLowerCase());
      final matchesStatus = _selectedStatuses.isEmpty || _selectedStatuses.contains(p.status);
      return matchesSearch && matchesStatus;
    }).toList();

    filteredProjects.sort((a, b) {
      final dateA = a.startDate;
      final dateB = b.startDate;
      return dateB.compareTo(dateA);
    });

    final groupedProjects = _groupProjectsByDate(filteredProjects);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 32,
          vertical: isMobile ? 16 : 24,
        ),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                    child: TextField(
                      style: TextStyle(color: textColor, fontSize: 14),
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (val) {
                        setState(() {
                          _quotaSearchQuery = val; // reusing quotaSearchQuery for simple search
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search attached projects...',
                        hintStyle: TextStyle(color: hintColor, fontSize: 13),
                        prefixIcon: Icon(IconsaxPlusLinear.search_normal, size: 18, color: hintColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<pmod.ProjectStatus>(
                  tooltip: 'Filter by Status',
                  onSelected: (status) {
                    setState(() {
                      if (_selectedStatuses.contains(status)) {
                        _selectedStatuses.remove(status);
                      } else {
                        _selectedStatuses.add(status);
                      }
                    });
                  },
                  itemBuilder: (context) {
                    return pmod.ProjectStatus.values.map((status) {
                      final isSelected = _selectedStatuses.contains(status);
                      return CheckedPopupMenuItem<pmod.ProjectStatus>(
                        value: status,
                        checked: isSelected,
                        child: Text(
                          _getStatusName(status),
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: _selectedStatuses.isNotEmpty
                          ? AppColors.primary.withOpacity(0.15)
                          : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedStatuses.isNotEmpty
                            ? AppColors.primary
                            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    child: Icon(
                      IconsaxPlusLinear.filter,
                      size: 18,
                      color: _selectedStatuses.isNotEmpty ? AppColors.primary : textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  width: isMobile ? 48 : null,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AttachProjectDialog(company: company),
                      ).then((_) {
                        projectProvider.reload();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: isMobile
                        ? const Icon(IconsaxPlusLinear.link_1, size: 18)
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconsaxPlusLinear.link_1, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Attach Project',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (filteredProjects.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconsaxPlusLinear.link_square, size: 64, color: hintColor),
                      const SizedBox(height: 16),
                      Text(
                        allCompanyProjects.isEmpty
                            ? 'No projects attached to this organization'
                            : 'No search results match filters',
                        style: TextStyle(color: hintColor, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        allCompanyProjects.isEmpty
                            ? 'Click "Attach Project" to link a project'
                            : 'Try adjusting your search query or filters',
                        style: TextStyle(color: hintColor.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedProjects.keys.length,
                itemBuilder: (context, index) {
                  final dateHeader = groupedProjects.keys.elementAt(index);
                  final projectsInDate = groupedProjects[dateHeader]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                dateHeader,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...projectsInDate.map((proj) {
                        final formattedTime = DateFormat('hh:mm a').format(proj.startDate);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProjectWorkspaceScreen(projectId: proj.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: proj.brandColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 12 : 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                proj.pid,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(proj.status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _getStatusName(proj.status).toUpperCase(),
                                                style: TextStyle(
                                                  color: _getStatusColor(proj.status),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 8,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (proj.isApproved ? AppColors.success : AppColors.warning).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                proj.isApproved ? 'LIVE' : 'PENDING',
                                                style: TextStyle(
                                                  color: proj.isApproved ? AppColors.success : AppColors.warning,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 8,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          proj.name,
                                          style: TextStyle(
                                            fontSize: isMobile ? 14 : 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (proj.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            proj.description,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: subTextColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 12 : 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () => _confirmDetach(proj),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              IconsaxPlusLinear.link_square,
                                              size: 15,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDetach(pmod.Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detach Project'),
        content: Text('Are you sure you want to detach project "${project.name}" (PID: ${project.pid})? It will return to the creator\'s private scope.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await Provider.of<ProjectProvider>(context, listen: false).detachFromCompany(project.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project detached successfully.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to detach project.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Detach', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white24 : Colors.black.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This module is currently being synchronized with the EBM blueprint system.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusName(pmod.ProjectStatus status) {
    switch (status) {
      case pmod.ProjectStatus.planned: return 'Planned';
      case pmod.ProjectStatus.inProgress: return 'In Progress';
      case pmod.ProjectStatus.delayed: return 'Delayed';
      case pmod.ProjectStatus.completed: return 'Completed';
      case pmod.ProjectStatus.archived: return 'Archived';
      case pmod.ProjectStatus.draft: return 'Draft';
    }
  }

  Color _getStatusColor(pmod.ProjectStatus status) {
    switch (status) {
      case pmod.ProjectStatus.planned: return Colors.purple;
      case pmod.ProjectStatus.inProgress: return Colors.blue;
      case pmod.ProjectStatus.delayed: return Colors.red;
      case pmod.ProjectStatus.completed: return AppColors.success;
      case pmod.ProjectStatus.archived: return Colors.grey;
      case pmod.ProjectStatus.draft: return Colors.grey;
    }
  }

  Map<String, List<pmod.Project>> _groupProjectsByDate(List<pmod.Project> projects) {
    final Map<String, List<pmod.Project>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final project in projects) {
      final projectDate = DateTime(project.startDate.year, project.startDate.month, project.startDate.day);

      String header;
      if (projectDate == today) {
        header = 'Today';
      } else if (projectDate == yesterday) {
        header = 'Yesterday';
      } else {
        header = DateFormat('MMMM dd, yyyy').format(projectDate);
      }

      if (!groups.containsKey(header)) {
        groups[header] = [];
      }
      groups[header]!.add(project);
    }
    return groups;
  }

  // ── Emblem Picker & Helpers ────────────────────────────────────────────────

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
                      Navigator.pop(ctx);
                      Navigator.pop(dialogCtx);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Emblem synced successfully!'),
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

// ── Strategic Company Radar (EBM – Provider Pattern) ─────────────────────────

class _EbmStrategicCompanyRadar extends StatefulWidget {
  final Company company;
  const _EbmStrategicCompanyRadar({required this.company});

  @override
  State<_EbmStrategicCompanyRadar> createState() => _EbmStrategicCompanyRadarState();
}

class _EbmStrategicCompanyRadarState extends State<_EbmStrategicCompanyRadar>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late AnimationController _rippleController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _rippleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncData();
        _controller.value = Matrix4.identity();
      }
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _syncData();
    });
  }

  void _syncData() {
    context.read<TaskProvider>().syncWithDatabase();
    context.read<ProjectProvider>().reload();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _rippleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double val) {
    final Matrix4 currentMatrix = _controller.value;
    final double scale = currentMatrix.getMaxScaleOnAxis();
    final double newScale = (scale + val).clamp(0.2, 2.0);
    _controller.value = Matrix4.identity()..scale(newScale, newScale, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = AppColors.primary;

    // Get all projects belonging to this company
    final companyProjects = context
        .watch<ProjectProvider>()
        .allProjects
        .where((p) => p.companyId == widget.company.id)
        .toList();

    final projectIds = companyProjects.map((p) => p.id).toSet();
    final realTasks = context
        .watch<TaskProvider>()
        .allTasks
        .where((t) => projectIds.contains(t.projectId))
        .toList();

    final List<SystemTask> tasks = [];
    if (realTasks.isNotEmpty) {
      tasks.addAll(realTasks);
    } else {
      for (var project in companyProjects) {
        for (var plan in project.plans) {
          final prefix = project.pid.substring(
              0, project.pid.length > 3 ? 3 : project.pid.length);
          tasks.addAll([
            SystemTask(
              id: '${plan.id}-t1',
              planId: plan.id,
              projectId: project.id,
              taskNumber: 'TSK-$prefix-01',
              title: 'Strategic Onboarding',
              allocatedCost: plan.budget * 0.20,
              status: TaskStatus.completed,
              assignee: 'Operations Lead',
              dueDate: DateTime.now().add(const Duration(days: 2)),
              description:
                  'Conduct foundational alignment session and initialize project blueprint.',
            ),
            SystemTask(
              id: '${plan.id}-t2',
              planId: plan.id,
              projectId: project.id,
              taskNumber: 'TSK-$prefix-02',
              title: 'Integrate Core Services',
              allocatedCost: plan.budget * 0.50,
              status: TaskStatus.inProgress,
              assignee: 'Development Team',
              dueDate: DateTime.now().add(const Duration(days: 7)),
              description:
                  'Build dynamic UI widgets and deploy service API layers.',
            ),
            SystemTask(
              id: '${plan.id}-t3',
              planId: plan.id,
              projectId: project.id,
              taskNumber: 'TSK-$prefix-03',
              title: 'Governance & Auditing',
              allocatedCost: plan.budget * 0.30,
              status: TaskStatus.todo,
              assignee: 'Quality Analyst',
              dueDate: DateTime.now().add(const Duration(days: 14)),
              description:
                  'Validate checklist, audit security, perform user acceptance tests.',
            ),
          ]);
        }
      }
    }

    // ── Canvas Layout Calculations ─────────────────────────────────────────
    const double verticalSpacing = 95.0;
    const double companyX = 50.0;
    const double projectX = 400.0;
    const double planX = 750.0;
    const double taskX = 1100.0;

    double currentY = 40.0;
    final Map<String, Offset> projectPositions = {};
    final Map<String, Offset> planPositions = {};
    final Map<String, Offset> taskPositions = {};

    for (final project in companyProjects) {
      final plans = project.plans;

      for (final plan in plans) {
        final planTasks = tasks.where((t) => t.planId == plan.id).toList();
        final int taskCount = planTasks.length;
        final double clusterHeight = (taskCount > 0 ? taskCount : 1) * verticalSpacing;
        final double planY = currentY + (clusterHeight / 2) - 40.0;
        planPositions[plan.id] = Offset(planX, planY);

        for (int j = 0; j < taskCount; j++) {
          final task = planTasks[j];
          final double taskY =
              currentY + (j * verticalSpacing) + (verticalSpacing / 2) - 40.0;
          taskPositions[task.id] = Offset(taskX, taskY);
        }
        currentY += clusterHeight + 40.0;
      }

      if (plans.isEmpty) {
        projectPositions[project.id] = Offset(projectX, currentY);
        currentY += verticalSpacing + 40.0;
      } else {
        final firstPlanY = planPositions[plans.first.id]!.dy;
        final lastPlanY = planPositions[plans.last.id]!.dy;
        projectPositions[project.id] = Offset(projectX, (firstPlanY + lastPlanY) / 2);
      }
      currentY += 20.0;
    }

    double companyY = 100.0;
    if (companyProjects.isNotEmpty &&
        projectPositions.containsKey(companyProjects.first.id) &&
        projectPositions.containsKey(companyProjects.last.id)) {
      final firstProjectY = projectPositions[companyProjects.first.id]!.dy;
      final lastProjectY = projectPositions[companyProjects.last.id]!.dy;
      companyY = (firstProjectY + lastProjectY) / 2;
    }
    final Offset companyPos = Offset(companyX, companyY);
    final double canvasHeight = currentY.clamp(650.0, 10000.0);
    const double canvasWidth = 1450.0;

    return Stack(
      children: [
        RepaintBoundary(
          child: InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.1,
            maxScale: 2.0,
            child: Container(
              width: canvasWidth,
              height: canvasHeight,
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Bezier flow paths with neon pulse animations
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size(canvasWidth, canvasHeight),
                        painter: _EbmCompanyMapLinkPainter(
                          projects: companyProjects,
                          tasks: tasks,
                          companyPos: companyPos,
                          projectPositions: projectPositions,
                          planPositions: planPositions,
                          taskPositions: taskPositions,
                          pulseValue: _rippleController.value,
                        ),
                      );
                    },
                  ),

                  // 1. Root Company Node
                  Positioned(
                    left: companyPos.dx,
                    top: companyPos.dy,
                    child: _EbmCompanyFlowNodeCard(
                      title: widget.company.name,
                      subtitle: 'COMPANY ROOT NODE',
                      dateText: 'Portal Node ID',
                      trackingId: widget.company.id
                          .substring(0, widget.company.id.length > 8 ? 8 : widget.company.id.length)
                          .toUpperCase(),
                      statusText: 'ACTIVE',
                      statusColor: Colors.green,
                      brandColor: brandColor,
                      icon: IconsaxPlusLinear.building_3,
                    ),
                  ),

                  // 2. Project Nodes
                  ...companyProjects.map((project) {
                    final pos = projectPositions[project.id];
                    if (pos == null) return const SizedBox.shrink();
                    return Positioned(
                      left: pos.dx,
                      top: pos.dy,
                      child: _EbmCompanyFlowNodeCard(
                        title: project.name,
                        subtitle: project.category.toUpperCase(),
                        dateText:
                            '${project.startDate.year}-${project.startDate.month.toString().padLeft(2, '0')}-${project.startDate.day.toString().padLeft(2, '0')}',
                        trackingId: project.pid,
                        statusText: project.status.name.toUpperCase(),
                        statusColor:
                            project.isApproved ? Colors.green : Colors.orangeAccent,
                        brandColor: project.brandColor,
                        icon: IconsaxPlusLinear.box,
                      ),
                    );
                  }),

                  // 3. Plan Hub Nodes
                  ...companyProjects.expand((p) => p.plans.map((plan) {
                        final planPos = planPositions[plan.id];
                        if (planPos == null) return const SizedBox.shrink();
                        final planTasks =
                            tasks.where((t) => t.planId == plan.id).toList();
                        final double totalAmount =
                            planTasks.fold(0.0, (sum, t) => sum + t.allocatedCost);
                        return Positioned(
                          left: planPos.dx,
                          top: planPos.dy,
                          child: _EbmCompanyFlowNodeCard(
                            title: plan.title,
                            subtitle: '\$${totalAmount.toInt()} BUDGETED',
                            dateText: 'i-CODE Hub Node',
                            trackingId: plan.icode,
                            statusText: plan.status.name.toUpperCase(),
                            statusColor: _ebmPlanStatusColor(plan.status),
                            brandColor: p.brandColor,
                            icon: IconsaxPlusLinear.hierarchy,
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => _buildEbmPlanModal(
                                context: context,
                                plan: plan,
                                color: p.brandColor,
                                isDark: isDark,
                                totalBudget: totalAmount,
                              ),
                            ),
                          ),
                        );
                      })),

                  // 4. Task Micro Nodes
                  ...tasks.map((task) {
                    final taskPos = taskPositions[task.id];
                    if (taskPos == null) return const SizedBox.shrink();
                    final project = companyProjects.firstWhere(
                        (p) => p.id == task.projectId,
                        orElse: () => companyProjects.first);
                    final formattedDate = task.dueDate != null
                        ? '${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-${task.dueDate!.day.toString().padLeft(2, '0')}'
                        : 'No Due Date';
                    return Positioned(
                      left: taskPos.dx,
                      top: taskPos.dy,
                      child: _EbmCompanyFlowNodeCard(
                        title: task.title,
                        subtitle: 'ASSIGNEE: ${task.assignee.toUpperCase()}',
                        dateText: 'DUE: $formattedDate',
                        trackingId: task.taskNumber,
                        statusText: task.status.displayName,
                        statusColor: _ebmTaskStatusColor(task.status),
                        brandColor: project.brandColor,
                        icon: IconsaxPlusLinear.task_square,
                        onTap: () {
                          final taskProv = context.read<TaskProvider>();
                          showDialog(
                            context: context,
                            builder: (ctx) => _buildEbmTaskModal(
                              context: ctx,
                              task: task,
                              color: project.brandColor,
                              isDark: isDark,
                              taskProvider: taskProv,
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        // Zoom Controls HUD
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E24).withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                _ebmZoomBtn(Icons.add, () => _zoom(0.15), brandColor, isDark),
                const SizedBox(height: 6),
                _ebmZoomBtn(Icons.remove, () => _zoom(-0.15), brandColor, isDark),
              ],
            ),
          ),
        ),

        // Header label
        Positioned(
          top: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E24).withOpacity(0.92)
                  : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(IconsaxPlusLinear.radar, size: 14, color: brandColor),
                const SizedBox(width: 6),
                Text(
                  'Strategic Radar  —  ${widget.company.name}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ebmZoomBtn(
      IconData icon, VoidCallback onTap, Color color, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ── Company Flow Graph Node Card ──────────────────────────────────────────────

class _EbmCompanyFlowNodeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String dateText;
  final String trackingId;
  final String statusText;
  final Color statusColor;
  final Color brandColor;
  final IconData icon;
  final VoidCallback? onTap;

  const _EbmCompanyFlowNodeCard({
    required this.title,
    required this.subtitle,
    required this.dateText,
    required this.trackingId,
    required this.statusText,
    required this.statusColor,
    required this.brandColor,
    required this.icon,
    this.onTap,
  });

  @override
  State<_EbmCompanyFlowNodeCard> createState() =>
      _EbmCompanyFlowNodeCardState();
}

class _EbmCompanyFlowNodeCardState extends State<_EbmCompanyFlowNodeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 240,
          height: 80,
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered
                    ? const Color(0xFF1E2230)
                    : const Color(0xFF11131A))
                : (_isHovered
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.brandColor.withOpacity(0.8)
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08)),
              width: _isHovered ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.brandColor.withOpacity(0.25)
                    : Colors.transparent,
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: widget.brandColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(widget.icon,
                                color: widget.brandColor, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: widget.statusColor.withOpacity(0.3),
                                  width: 0.8),
                            ),
                            child: Text(
                              widget.statusText,
                              style: TextStyle(
                                color: widget.statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Title with tooltip
                      Tooltip(
                        waitDuration: Duration.zero,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E2230) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: widget.brandColor.withOpacity(0.3),
                              width: 1.5),
                        ),
                        richMessage: TextSpan(
                          children: [
                            TextSpan(
                              text: '${widget.title}\n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Status: ${widget.statusText} • ID: ${widget.trackingId}\n',
                              style: TextStyle(
                                  fontSize: 10, color: widget.brandColor, height: 1.5),
                            ),
                            TextSpan(
                              text: widget.dateText,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Footer: date + copy UID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.dateText,
                            style: TextStyle(
                              fontSize: 8,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: widget.trackingId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Copied: ${widget.trackingId}'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: widget.brandColor,
                                    duration:
                                        const Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Text(
                                      widget.trackingId,
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: widget.brandColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.copy_rounded,
                                        size: 8, color: widget.brandColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Company Bezier Link Painter ───────────────────────────────────────────────

class _EbmCompanyMapLinkPainter extends CustomPainter {
  final List<dynamic> projects; // List<Project>
  final List<SystemTask> tasks;
  final Offset companyPos;
  final Map<String, Offset> projectPositions;
  final Map<String, Offset> planPositions;
  final Map<String, Offset> taskPositions;
  final double pulseValue;

  _EbmCompanyMapLinkPainter({
    required this.projects,
    required this.tasks,
    required this.companyPos,
    required this.projectPositions,
    required this.planPositions,
    required this.taskPositions,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startPort = Offset(companyPos.dx + 240.0, companyPos.dy + 40.0);

    for (final project in projects) {
      final projectPos = projectPositions[project.id];
      if (projectPos != null) {
        final endPort = Offset(projectPos.dx, projectPos.dy + 40.0);
        final path = Path()
          ..moveTo(startPort.dx, startPort.dy)
          ..cubicTo(startPort.dx + 80.0, startPort.dy,
              endPort.dx - 80.0, endPort.dy, endPort.dx, endPort.dy);
        canvas.drawPath(
            path,
            Paint()
              ..color = (project.brandColor as Color).withOpacity(0.18)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..strokeCap = StrokeCap.round);
        _drawPulse(canvas, path,
            Paint()..color = project.brandColor as Color, pulseValue);
      }
    }

    for (final project in projects) {
      final projectPos = projectPositions[project.id];
      if (projectPos != null) {
        final projectStartPort =
            Offset(projectPos.dx + 240.0, projectPos.dy + 40.0);
        for (final plan in project.plans) {
          final planPos = planPositions[plan.id];
          if (planPos != null) {
            final endPort = Offset(planPos.dx, planPos.dy + 40.0);
            final path = Path()
              ..moveTo(projectStartPort.dx, projectStartPort.dy)
              ..cubicTo(
                  projectStartPort.dx + 80.0,
                  projectStartPort.dy,
                  endPort.dx - 80.0,
                  endPort.dy,
                  endPort.dx,
                  endPort.dy);
            canvas.drawPath(
                path,
                Paint()
                  ..color = (project.brandColor as Color).withOpacity(0.15)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.8
                  ..strokeCap = StrokeCap.round);
            _drawPulse(canvas, path,
                Paint()..color = project.brandColor as Color, pulseValue);
          }
        }
      }
    }

    for (final project in projects) {
      for (final plan in project.plans) {
        final planPos = planPositions[plan.id];
        if (planPos != null) {
          final planTasks =
              tasks.where((t) => t.planId == plan.id).toList();
          final planStartPort =
              Offset(planPos.dx + 240.0, planPos.dy + 40.0);
          for (final task in planTasks) {
            final taskPos = taskPositions[task.id];
            if (taskPos != null) {
              final endPort = Offset(taskPos.dx, taskPos.dy + 40.0);
              final path = Path()
                ..moveTo(planStartPort.dx, planStartPort.dy)
                ..cubicTo(
                    planStartPort.dx + 80.0,
                    planStartPort.dy,
                    endPort.dx - 80.0,
                    endPort.dy,
                    endPort.dx,
                    endPort.dy);
              final taskColor = _ebmTaskStatusColor(task.status);
              canvas.drawPath(
                  path,
                  Paint()
                    ..color = taskColor.withOpacity(0.12)
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.5
                    ..strokeCap = StrokeCap.round);
              _drawPulse(canvas, path, Paint()..color = taskColor, pulseValue);
            }
          }
        }
      }
    }
  }

  void _drawPulse(Canvas canvas, Path path, Paint paint, double t) {
    for (final metric in path.computeMetrics()) {
      final tangent =
          metric.getTangentForOffset(metric.length * t);
      if (tangent != null) {
        canvas.drawCircle(
            tangent.position,
            7.0,
            Paint()
              ..color = paint.color.withOpacity(0.6)
              ..style = PaintingStyle.fill
              ..maskFilter =
                  const MaskFilter.blur(BlurStyle.normal, 5.0));
        canvas.drawCircle(
            tangent.position,
            2.5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Shared Radar Helpers (EBM) ────────────────────────────────────────────────

Color _ebmPlanStatusColor(pmod.ProjectStatus s) {
  switch (s) {
    case pmod.ProjectStatus.completed: return Colors.green;
    case pmod.ProjectStatus.inProgress: return Colors.blueAccent;
    case pmod.ProjectStatus.delayed: return Colors.orange;
    case pmod.ProjectStatus.archived: return Colors.grey;
    default: return Colors.grey;
  }
}

Color _ebmTaskStatusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo: return Colors.orangeAccent;
    case TaskStatus.inProgress: return Colors.blueAccent;
    case TaskStatus.completed: return Colors.green;
    case TaskStatus.review: return Colors.amberAccent;
    case TaskStatus.done: return Colors.tealAccent;
  }
}

Color _ebmPriorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low: return Colors.blueGrey;
    case TaskPriority.medium: return Colors.blueAccent;
    case TaskPriority.high: return Colors.orangeAccent;
    case TaskPriority.critical: return Colors.redAccent;
  }
}

Widget _buildEbmPlanModal({
  required BuildContext context,
  required pmod.Plan plan,
  required Color color,
  required bool isDark,
  double totalBudget = 0.0,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    child: GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(plan.icode,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ),
                IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text(plan.title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text(
              'A critical programmatic node mapping system goals to resource allocation and active development phases.',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _ebmModalItem(
                        'STATUS',
                        plan.status.name.toUpperCase(),
                        plan.status == pmod.ProjectStatus.completed
                            ? Colors.green
                            : Colors.blueAccent,
                        isDark)),
                Expanded(
                    child: _ebmModalItem(
                        'TASKS BUDGETED',
                        '\$${totalBudget.toStringAsFixed(2)}',
                        Colors.blueAccent,
                        isDark)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _ebmModalItem(
                        'TASKS LINKED',
                        '${plan.taskIds.length}',
                        color,
                        isDark)),
                Expanded(
                    child: _ebmModalItem(
                        'CREATED',
                        '${plan.createdAt.year}-${plan.createdAt.month.toString().padLeft(2, '0')}-${plan.createdAt.day.toString().padLeft(2, '0')}',
                        isDark ? Colors.white70 : Colors.black87,
                        isDark)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('CLOSE BRIEF',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildEbmTaskModal({
  required BuildContext context,
  required SystemTask task,
  required Color color,
  required bool isDark,
  required TaskProvider taskProvider,
}) {
  final auth = context.watch<AuthProvider>();
  final canApprove = canUserApproveTask(task, auth);
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    child: GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(task.taskNumber,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ),
                IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text(task.title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description,
                  style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark ? Colors.white70 : Colors.black54,
                      height: 1.5)),
            ],
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _ebmModalItem(
                        'STATUS',
                        task.status.displayName,
                        _ebmTaskStatusColor(task.status),
                        isDark)),
                Expanded(
                    child: _ebmModalItem(
                        'PRIORITY',
                        task.priority.name.toUpperCase(),
                        _ebmPriorityColor(task.priority),
                        isDark)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _ebmModalItem(
                        'ALLOCATED BUDGET',
                        '\$${task.allocatedCost.toStringAsFixed(2)}',
                        color,
                        isDark)),
                Expanded(
                    child: _ebmModalItem(
                        'ASSIGNEE',
                        task.assignee,
                        isDark ? Colors.white70 : Colors.black87,
                        isDark)),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<TaskStatus>(
              value: task.status,
              decoration: InputDecoration(
                labelText: canApprove ? 'CHANGE STATUS' : 'CHANGE STATUS (LOCKED - READ ONLY)',
                labelStyle: TextStyle(
                    color: canApprove ? color : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              items: TaskStatus.values
                  .map((s) => DropdownMenuItem<TaskStatus>(
                      value: s,
                      child: Text(s.displayName,
                          style: const TextStyle(fontSize: 12))))
                  .toList(),
              onChanged: canApprove ? (newStatus) {
                if (newStatus != null && newStatus != task.status) {
                  taskProvider.updateTaskStatus(task.id, newStatus);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Status updated to ${newStatus.displayName}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: color,
                  ));
                }
              } : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('CLOSE BRIEF',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _ebmModalItem(
    String label, String value, Color valColor, bool isDark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1.2)),
      const SizedBox(height: 6),
      Text(value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valColor)),
    ],
  );
}

bool canUserApproveTask(SystemTask task, AuthProvider auth) {
  switch (task.status) {
    case TaskStatus.todo:
      return auth.isAdmin || auth.isSubAdmin || auth.isManager;
    case TaskStatus.inProgress: // ACTION
      return auth.isManager;
    case TaskStatus.review: // REVIEW
      return auth.isAdmin || auth.isSubAdmin;
    case TaskStatus.done: // DONE
      return auth.isManager;
    case TaskStatus.completed: // COMPLETED
      return auth.isAdmin || auth.isSubAdmin;
    default:
      return false;
  }
}
