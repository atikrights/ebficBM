import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ebficBM/features/companies/providers/company_provider.dart';
import 'package:ebficBM/features/companies/models/company.dart';
import 'package:ebficBM/features/projects/providers/project_provider.dart';
import 'package:ebficBM/features/projects/models/project.dart';

class SettingsScreen extends StatefulWidget {
  final String currentProjectId;

  const SettingsScreen({
    super.key,
    this.currentProjectId = 'proj_1', // Dynamic default fallback
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _cidSearchController = TextEditingController();
  final TextEditingController _listSearchController = TextEditingController();
  late TabController _tabController;
  String? _selectedDropdownCid;
  bool _isProcessing = false;
  String _listSearchQuery = '';
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
    
    _listSearchController.addListener(() {
      setState(() {
        _listSearchQuery = _listSearchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentConnection();
    });
  }

  void _loadCurrentConnection() {
    final projProvider = Provider.of<ProjectProvider>(context, listen: false);
    try {
      final proj = projProvider.allProjects.firstWhere((p) => p.id == widget.currentProjectId);
      if (proj.companyId != null) {
        setState(() {
          _selectedDropdownCid = proj.companyId;
        });
      }
    } catch (e) {
      debugPrint("Project not found yet for settings");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cidSearchController.dispose();
    _listSearchController.dispose();
    super.dispose();
  }

  Future<void> _processLinking(String targetCid) async {
    setState(() => _isProcessing = true);
    final compProvider = Provider.of<CompanyProvider>(context, listen: false);
    final projProvider = Provider.of<ProjectProvider>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 1200));

    final targetComp = compProvider.allCompanies.where((c) => c.id == targetCid).firstOrNull;

    if (targetComp == null) {
      if (mounted) {
        _showSnackBar('Company with CID [$targetCid] not found in Registry.', isError: true);
        setState(() => _isProcessing = false);
      }
      return;
    }

    try {
      final proj = projProvider.allProjects.firstWhere((p) => p.id == widget.currentProjectId);
      
      final log = HistoryLog(
        id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Established secure link with: ${targetComp.name} [CID: $targetCid]',
        timestamp: DateTime.now(),
        author: 'System Root',
        actionType: 'SYNC_ATTACH',
      );

      projProvider.updateProject(proj.copyWith(
        companyId: targetCid,
        syncLogs: [log, ...proj.syncLogs].take(50).toList(),
      ));
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedDropdownCid = targetCid;
          _cidSearchController.clear();
        });
        _showSnackBar('Successfully connected to company: ${targetComp.name}', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnackBar('Failed to synchronize securely with Workspace Data.', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final subSurfaceColor = isDark ? const Color(0xFF16161A) : const Color(0xFFF8F9FA);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFFAFAFA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1000;
          
          return Column(
            children: [
              _buildHeader(isDesktop, isDark, primaryTextColor, surfaceColor, borderColor),
              Expanded(
                child: isDesktop 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSidebar(isDark, primaryTextColor, surfaceColor, borderColor),
                        Expanded(
                          child: _buildMainContent(isDesktop, isDark, primaryTextColor, secondaryTextColor, surfaceColor, subSurfaceColor, borderColor),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMobileTabBar(isDark, primaryTextColor, surfaceColor, borderColor),
                        Expanded(
                          child: _buildMainContent(isDesktop, isDark, primaryTextColor, secondaryTextColor, surfaceColor, subSurfaceColor, borderColor),
                        ),
                      ],
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isDark, Color primaryText, Color surface, Color border) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
             IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, color: primaryText),
              splashRadius: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'System Settings',
              style: TextStyle(
                color: primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            if (_isProcessing)
              const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isDark, Color primaryText, Color surface, Color border) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSidebarItem(0, Icons.hub_outlined, 'Attach Hub', _activeTabIndex == 0, primaryText),
          _buildSidebarItem(1, Icons.tune_rounded, 'General Config', _activeTabIndex == 1, primaryText),
          _buildSidebarItem(2, Icons.palette_outlined, 'Display & Aesthetics', _activeTabIndex == 2, primaryText),
          _buildSidebarItem(3, Icons.security_outlined, 'Secure Vault', _activeTabIndex == 3, primaryText),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, bool isActive, Color primaryText) {
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.blueAccent : primaryText.withOpacity(0.5), size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blueAccent : primaryText.withOpacity(0.7),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isActive)
              const Spacer(),
            if (isActive)
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabBar(bool isDark, Color primaryText, Color surface, Color border) {
    return Container(
      color: surface,
      height: 50,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blueAccent,
        labelColor: Colors.blueAccent,
        unselectedLabelColor: primaryText.withOpacity(0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Attach'),
          Tab(text: 'General'),
          Tab(text: 'Aesthetics'),
          Tab(text: 'Secure'),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop, bool isDark, Color primaryText, Color secondaryText, Color surface, Color subSurface, Color border) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAttachTab(isDesktop, isDark, primaryText, secondaryText, surface, subSurface, border),
        _buildPlaceholderTab('General Configuration', Icons.tune_rounded, primaryText, secondaryText),
        _buildPlaceholderTab('Display & Aesthetics', Icons.palette_outlined, primaryText, secondaryText),
        _buildPlaceholderTab('Secure Vault Settings', Icons.security_outlined, primaryText, secondaryText),
      ],
    );
  }

  Widget _buildAttachTab(bool isDesktop, bool isDark, Color primaryText, Color secondaryText, Color surface, Color subSurface, Color border) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) 
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildCompanyConnectionPanel(isDark, primaryText, secondaryText, subSurface, border, surface)),
                const SizedBox(width: 48),
                Expanded(flex: 2, child: _buildRightSideCompaniesPanel(isDark, primaryText, secondaryText, surface, border)),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompanyConnectionPanel(isDark, primaryText, secondaryText, subSurface, border, surface),
                const SizedBox(height: 32),
                _buildRightSideCompaniesPanel(isDark, primaryText, secondaryText, surface, border),
              ],
            ),
          const SizedBox(height: 48),
          _buildActivityLogSection(isDark, primaryText, secondaryText, surface, border),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon, Color primaryText, Color secondaryText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: primaryText.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(color: primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Advanced options for this module are coming soon.', style: TextStyle(color: secondaryText, fontSize: 14)),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildCompanyConnectionPanel(bool isDark, Color primaryText, Color secondaryText, Color subSurface, Color border, Color surface) {
    return Consumer2<ProjectProvider, CompanyProvider>(
      builder: (context, projProvider, compProvider, child) {
        final List<Company> companies = compProvider.allCompanies;
        Project? currentProject;
        try { currentProject = projProvider.allProjects.firstWhere((p) => p.id == widget.currentProjectId); } catch (e) {}
        
        final currentCompany = currentProject?.companyId != null 
                             ? compProvider.allCompanies.where((c) => c.id == currentProject?.companyId).firstOrNull 
                             : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workspace Alignment',
              style: TextStyle(color: primaryText, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Synchronize your current business workspace with a verified master organization to unlock enterprise-grade features.',
              style: TextStyle(color: secondaryText, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),

            AnimatedContainer(
              duration: 500.ms,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: currentCompany != null 
                    ? [Colors.blueAccent.withOpacity(0.15), Colors.blueAccent.withOpacity(0.02)]
                    : [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.01)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                border: Border.all(color: (currentCompany != null ? Colors.blueAccent : Colors.orange).withOpacity(0.3), width: 1),
                boxShadow: [
                  if (currentCompany != null) BoxShadow(color: Colors.blueAccent.withOpacity(0.05), blurRadius: 40, spreadRadius: 10)
                ]
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: (currentCompany != null ? Colors.blueAccent : Colors.orange), shape: BoxShape.circle),
                    child: Icon(currentCompany != null ? Icons.link_rounded : Icons.link_off_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentCompany != null ? 'ACTIVE CONNECTION' : 'SYSTEM DISCONNECTED',
                          style: TextStyle(color: (currentCompany != null ? Colors.blueAccent : Colors.orange), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentCompany != null ? currentCompany.name : 'Awaiting alignment...',
                          style: TextStyle(color: primaryText, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            _buildSectionHeader('Method 1: Direct Secure Access', Icons.vpn_key_outlined, primaryText),
            const SizedBox(height: 16),
            _buildCidInput(subSurface, border, primaryText, secondaryText),

            const SizedBox(height: 48),

            _buildSectionHeader('Method 2: Registry Deployment', Icons.grid_view_rounded, primaryText),
            const SizedBox(height: 16),
            _buildDropdownSelector(subSurface, border, primaryText, secondaryText, surface, companies, currentCompany),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color primaryText) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 18),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCidInput(Color subSurface, Color border, Color primaryText, Color secondaryText) {
    return Container(
      decoration: BoxDecoration(
        color: subSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.fingerprint, color: Colors.blueAccent, size: 20)),
          Expanded(
            child: TextField(
              controller: _cidSearchController,
              style: TextStyle(color: primaryText, letterSpacing: 1.2, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'ENTER ENTERPRISE IDENTIFIER...',
                hintStyle: TextStyle(color: secondaryText.withOpacity(0.3), fontSize: 12, letterSpacing: 1),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          InkWell(
            onTap: _isProcessing ? null : () {
               if (_cidSearchController.text.trim().isNotEmpty) _processLinking(_cidSearchController.text.trim());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(16)),
              child: const Text('DEPLOY LINK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector(Color subSurface, Color border, Color primaryText, Color secondaryText, Color surface, List<Company> companies, Company? currentCompany) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: subSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDropdownCid,
          hint: Text('BROWSE AVAILABLE REGISTRY', style: TextStyle(color: secondaryText.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold)),
          dropdownColor: surface,
          icon: const Icon(Icons.unfold_more_rounded, color: Colors.blueAccent),
          isExpanded: true,
          items: companies.map((c) => DropdownMenuItem(
            value: c.id,
            child: Row(
              children: [
                const Icon(Icons.business_center_rounded, size: 18, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Text(c.name, style: TextStyle(color: primaryText, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('NID: ${c.id}', style: TextStyle(color: secondaryText, fontSize: 11)),
              ],
            ),
          )).toList(),
          onChanged: (val) { if (val != null && val != currentCompany?.id) _processLinking(val); },
        ),
      ),
    );
  }

  Widget _buildRightSideCompaniesPanel(bool isDark, Color primaryText, Color secondaryText, Color surface, Color border) {
    return Consumer2<CompanyProvider, ProjectProvider>(
      builder: (context, compProvider, projProvider, child) {
        final filteredCompanies = compProvider.allCompanies.where((c) => 
          c.name.toLowerCase().contains(_listSearchQuery) || c.id.toLowerCase().contains(_listSearchQuery)).toList();
        Project? cp;
        try { cp = projProvider.allProjects.firstWhere((p) => p.id == widget.currentProjectId); } catch (e) {}

        return Container(
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: border)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Cloud Archive', style: TextStyle(color: primaryText, fontSize: 18, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.cloud_queue_rounded, size: 16, color: Colors.blueAccent)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _listSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search registry...',
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.blueAccent),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCompanies.length,
                  itemBuilder: (context, i) {
                    final c = filteredCompanies[i];
                    final linked = c.id == cp?.companyId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => linked ? null : _processLinking(c.id),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: linked ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: linked ? Colors.blueAccent.withOpacity(0.4) : Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 18, backgroundColor: linked ? Colors.blueAccent : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)), child: Icon(linked ? Icons.done : Icons.business, size: 16, color: linked ? Colors.white : secondaryText)),
                              const SizedBox(width: 16),
                              Expanded(child: Text(c.name, style: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 14))),
                              if (linked) const TagWidget(text: 'LINKED', color: Colors.blueAccent),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityLogSection(bool isDark, Color primaryText, Color secondaryText, Color surface, Color border) {
    return Consumer<ProjectProvider>(
      builder: (context, projProvider, child) {
        Project? cp;
        try { cp = projProvider.allProjects.firstWhere((p) => p.id == widget.currentProjectId); } catch (e) {}
        final logs = cp?.syncLogs ?? [];
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Deployment Ledger', style: TextStyle(color: primaryText, fontSize: 18, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  if (logs.isNotEmpty)
                    TextButton(onPressed: () => projProvider.clearSyncLogs(widget.currentProjectId), child: const Text('PURGE LEDGER', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
              const SizedBox(height: 24),
              if (logs.isEmpty)
                Center(child: Text('NO CONNECTION TRACES DETECTED', style: TextStyle(color: secondaryText.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)))
              else
                ...logs.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Container(width: 2, height: 40, color: Colors.blueAccent.withOpacity(0.3)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.message, style: TextStyle(color: primaryText, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${_getMonth(e.value.timestamp.month)} ${e.value.timestamp.day} · BY ${e.value.author}', style: TextStyle(color: secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
            ],
          ),
        );
      },
    );
  }

  String _getMonth(int month) {
    const m = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return m[month - 1];
  }
}

class TagWidget extends StatelessWidget {
  final String text;
  final Color color;
  const TagWidget({super.key, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }
}
