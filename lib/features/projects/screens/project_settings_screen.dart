import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/analysis_engine.dart';
import '../../../core/models/project.dart';
import '../../../core/models/company.dart';
import '../providers/project_provider.dart';

class ProjectSettingsScreen extends StatefulWidget {
  final String projectId;

  const ProjectSettingsScreen({super.key, required this.projectId});

  @override
  State<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  String? _selectedCompanyId;
  bool _isSaving = false;
  bool _isDetaching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final engine = Provider.of<AnalysisEngine>(context, listen: false);
      final project = engine.getProject(widget.projectId);
      if (project != null && project.companyId != null) {
        setState(() => _selectedCompanyId = project.companyId);
      }
    });
  }

  Future<void> _handleAttachCompany(Project project) async {
    if (_selectedCompanyId == null || _selectedCompanyId == project.companyId) return;
    setState(() => _isSaving = true);

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final success = await provider.attachToCompany(widget.projectId, _selectedCompanyId!);

    setState(() => _isSaving = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? '✅ Project attached to company successfully!'
          : '❌ Failed to attach. Please try again.'),
      backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));

    if (success) Navigator.pop(context);
  }

  Future<void> _handleDetachCompany(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Detach from Company?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This project will be returned to your private workspace.\nTeam members will no longer see it.',
          style: TextStyle(color: Colors.white60, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Detach'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isDetaching = true);

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final success = await provider.detachFromCompany(widget.projectId);

    setState(() {
      _isDetaching = false;
      if (success) _selectedCompanyId = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? '✅ Project detached. Moved to private workspace.'
          : '❌ Detach failed. Please try again.'),
      backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnalysisEngine, ProjectProvider>(
      builder: (context, engine, provider, child) {
        final project = engine.getProject(widget.projectId);
        final List<Company> allCompanies = engine.companies.values.toList();
        final bool isCurrentlyAttached =
            project?.companyId != null && project!.companyId!.isNotEmpty;

        if (project == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: Text("Project not found", style: TextStyle(color: Colors.white))),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'PROJECT SETTINGS',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(project.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  project.pid,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),

                // Status badges
                Row(children: [
                  _buildBadge(
                    label: isCurrentlyAttached ? '🔗 Attached' : '🔒 Private',
                    color: isCurrentlyAttached
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    label: project.isApproved ? '✅ Approved' : '⏳ Pending Approval',
                    color: project.isApproved
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ]),

                const SizedBox(height: 40),

                // Approval notice for pending projects
                if (!project.isApproved)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.hourglass_top_rounded,
                          color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'This project is pending approval from your Admin or Sub-Admin via EBM Central.',
                          style: TextStyle(
                              color: Color(0xFFF59E0B), fontSize: 13, height: 1.5),
                        ),
                      ),
                    ]),
                  ),

                // Company Attachment Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.business_center,
                              color: Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Company Attachment',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            Text('Link or unlink from a company',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Currently attached company chip
                      if (isCurrentlyAttached) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.link,
                                color: Color(0xFF3B82F6), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                project.companyName ?? 'Company #${project.companyId}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            // Detach button
                            GestureDetector(
                              onTap: _isDetaching
                                  ? null
                                  : () => _handleDetachCompany(project),
                              child: _isDetaching
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.redAccent))
                                  : const Icon(Icons.link_off,
                                      color: Colors.redAccent, size: 20),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'To change company, select a new one below:',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCompanyId,
                            hint: const Text('Select a Company',
                                style: TextStyle(color: Colors.white54)),
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white54),
                            isExpanded: true,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('— No Company (Private)',
                                    style: TextStyle(color: Colors.white38)),
                              ),
                              ...allCompanies.map((Company company) {
                                return DropdownMenuItem<String>(
                                  value: company.id,
                                  child: Text(company.name),
                                );
                              }),
                            ],
                            onChanged: (String? newValue) {
                              setState(() => _selectedCompanyId = newValue);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Attach / Update button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            disabledBackgroundColor:
                                Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: (_selectedCompanyId != null &&
                                  _selectedCompanyId != project.companyId &&
                                  !_isSaving)
                              ? () => _handleAttachCompany(project)
                              : null,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.link_rounded,
                                  color: Colors.white),
                          label: Text(
                            isCurrentlyAttached
                                ? 'Switch Company'
                                : 'Attach to Company',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Privacy info card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.white38, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isCurrentlyAttached
                              ? 'This project is shared with your company workspace. Approved team members can view it.'
                              : 'This project is private. Only you can see it until you attach it to a company.',
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
