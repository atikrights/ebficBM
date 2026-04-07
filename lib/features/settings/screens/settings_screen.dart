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
  String? _selectedDropdownCid;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
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
    _cidSearchController.dispose();
    super.dispose();
  }

  Future<void> _processLinking(String targetCid) async {
    setState(() => _isProcessing = true);
    final compProvider = Provider.of<CompanyProvider>(context, listen: false);
    final projProvider = Provider.of<ProjectProvider>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 1000));

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
      projProvider.updateProject(proj.copyWith(companyId: targetCid));
      
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
    final surfaceColor = isDark ? const Color(0xFF1A1A1E) : Colors.white;
    final subSurfaceColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F3F5);
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFFAFAFA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDesktop, isDark, primaryTextColor, surfaceColor, borderColor),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : (isTablet ? 32 : 16),
                    vertical: 32,
                  ),
                  child: isDesktop 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildCompanyConnectionPanel(isDark, primaryTextColor, secondaryTextColor, subSurfaceColor, borderColor)),
                            const SizedBox(width: 48),
                            Expanded(flex: 2, child: _buildRightSideCompaniesPanel(isDark, primaryTextColor, secondaryTextColor, surfaceColor, borderColor)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCompanyConnectionPanel(isDark, primaryTextColor, secondaryTextColor, subSurfaceColor, borderColor),
                            const SizedBox(height: 32),
                            _buildRightSideCompaniesPanel(isDark, primaryTextColor, secondaryTextColor, surfaceColor, borderColor),
                          ],
                        ),
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
        horizontal: isDesktop ? 60 : 24,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.settings_outlined, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 16),
            Text(
              'Workspace Settings',
              style: TextStyle(
                color: primaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            if (_isProcessing)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyConnectionPanel(bool isDark, Color primaryText, Color secondaryText, Color subSurface, Color border) {
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
              'Company Synchronization',
              style: TextStyle(color: primaryText, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Link your workspace securely to a master company via CID or list selection.',
              style: TextStyle(color: secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // CONNECTION STATUS CARD
            Container(
              key: ValueKey(currentCompany?.id ?? 'none'),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: currentCompany != null 
                    ? [Colors.green.shade900.withOpacity(0.3), Colors.green.shade800.withOpacity(0.1)]
                    : (isDark ? [Colors.orange.shade900.withOpacity(0.3), Colors.orange.shade800.withOpacity(0.1)] 
                              : [Colors.orange.shade100, Colors.orange.shade50]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: currentCompany != null ? Colors.green.shade700.withOpacity(0.5) : Colors.orange.shade700.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: currentCompany != null ? Colors.green.shade700 : Colors.orange.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentCompany != null ? Icons.verified_user : Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentCompany != null ? 'SECURELY LINKED' : 'UNLINKED WORKSPACE',
                          style: TextStyle(
                            color: currentCompany != null ? (isDark ? Colors.greenAccent : Colors.green.shade800) 
                                                          : (isDark ? Colors.orangeAccent : Colors.orange.shade900),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentCompany != null ? currentCompany.name : 'No active enterprise connection',
                          style: TextStyle(
                            color: currentCompany != null 
                                ? (isDark ? Colors.white : Colors.green.shade900)
                                : (isDark ? Colors.white : Colors.black87),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // METHOD 1: SEARCH BY CID
            Text(
              'Method 1: Direct Link via CID',
              style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: subSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.fingerprint, color: secondaryText),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _cidSearchController,
                      style: TextStyle(color: primaryText, letterSpacing: 1.2),
                      decoration: InputDecoration(
                        hintText: 'Enter Enterprise CID (e.g. CID-123456)',
                        hintStyle: TextStyle(color: secondaryText),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (value) => value.isNotEmpty ? _processLinking(value) : null,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (_cidSearchController.text.trim().isNotEmpty) {
                        _processLinking(_cidSearchController.text.trim());
                      }
                    },
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.shade700,
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(11), bottomRight: Radius.circular(11)),
                      ),
                      child: const Text('ATTACH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Divider(color: border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: secondaryText, fontSize: 12)),
                ),
                Expanded(child: Divider(color: border)),
              ],
            ),
            const SizedBox(height: 32),

            // METHOD 2: LOCATE & SELECT
            Text(
              'Method 2: Locate in Registry',
              style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: subSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDropdownCid,
                  hint: Text('Select an available company', style: TextStyle(color: secondaryText)),
                  dropdownColor: subSurface,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                  isExpanded: true,
                  style: TextStyle(color: primaryText, fontSize: 16),
                  items: companies.map((Company company) {
                    return DropdownMenuItem<String>(
                      value: company.id,
                      child: Text('${company.name} [CID: ${company.id}]'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != currentCompany?.id) {
                      _processLinking(newValue);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRightSideCompaniesPanel(bool isDark, Color primaryText, Color secondaryText, Color surface, Color border) {
    return Consumer2<CompanyProvider, ProjectProvider>(
      builder: (context, compProvider, projProvider, child) {
        final companies = compProvider.allCompanies;
        Project? currentProj;
        try { currentProj = projProvider.allProjects.firstWhere((p) => p.id == widget.currentProjectId); } catch (e) {}

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                     child: const Icon(Icons.business, color: Colors.blueAccent, size: 22),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text('Active Registry Organizations', style: TextStyle(color: primaryText, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Alternatively, select an organization directly from the registry to establish a secure data link.', style: TextStyle(color: secondaryText, fontSize: 13)),
              const SizedBox(height: 24),
              if (companies.isEmpty)
                 Center(
                   child: Padding(
                     padding: const EdgeInsets.all(32),
                     child: Text('No companies deployed in registry yet.', style: TextStyle(color: secondaryText)),
                   )
                 )
              else
                 SizedBox(
                   height: 400, // Dynamic max height inside scrolling column
                   child: ListView.builder(
                     physics: const BouncingScrollPhysics(),
                     itemCount: companies.length,
                     itemBuilder: (context, index) {
                       final comp = companies[index];
                       final isLinked = comp.id == currentProj?.companyId;
                       
                       return InkWell(
                         onTap: () {
                           if (!isLinked && !_isProcessing) {
                             _cidSearchController.clear();
                             _processLinking(comp.id);
                           }
                         },
                         borderRadius: BorderRadius.circular(16),
                         child: Container(
                           margin: const EdgeInsets.only(bottom: 12),
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: isLinked ? [Colors.blueAccent.withOpacity(0.15), Colors.blueAccent.withOpacity(0.02)] 
                                                : (isDark ? [Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.01)]
                                                          : [Colors.black.withOpacity(0.02), Colors.black.withOpacity(0.01)]),
                               begin: Alignment.topLeft,
                               end: Alignment.bottomRight,
                             ),
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: isLinked ? Colors.blueAccent.withOpacity(0.4) : border),
                             boxShadow: isLinked ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.15), blurRadius: 15, spreadRadius: 1)] : [],
                           ),
                           child: Row(
                             children: [
                               Container(
                                 padding: const EdgeInsets.all(10),
                                 decoration: BoxDecoration(color: isLinked ? Colors.blueAccent.shade700 : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)), shape: BoxShape.circle),
                                 child: Icon(isLinked ? Icons.check : Icons.business_center, color: isLinked ? Colors.white : secondaryText, size: 16),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(comp.name, style: TextStyle(color: isLinked ? (isDark ? Colors.blueAccent.shade100 : Colors.blue.shade800) : primaryText, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                     const SizedBox(height: 4),
                                     Text('CID: ${comp.id}', style: TextStyle(color: secondaryText, fontSize: 12, letterSpacing: 0.5)),
                                   ]
                                 )
                               ),
                               if (isLinked)
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                   decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                   child: Text('LINKED', style: TextStyle(color: isDark ? Colors.blueAccent : Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                 )
                               else
                                 Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2), size: 14)
                             ]
                           ),
                         )
                       );
                     }
                   )
                 )
            ]
          )
        );
      }
    );
  }
}
