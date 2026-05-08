import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/analysis_engine.dart';
import '../../../core/models/project.dart';
import '../../../core/models/company.dart';

class ProjectSettingsScreen extends StatefulWidget {
  final String projectId;

  const ProjectSettingsScreen({super.key, required this.projectId});

  @override
  State<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  String? _selectedCompanyId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected company if the project is already linked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final engine = Provider.of<AnalysisEngine>(context, listen: false);
      final project = engine.getProject(widget.projectId);
      if (project != null && project.companyId != null) {
        setState(() {
          _selectedCompanyId = project.companyId;
        });
      }
    });
  }

  Future<void> _handleLinkCompany() async {
    if (_selectedCompanyId == null) return;
    
    setState(() => _isSaving = true);
    
    final engine = Provider.of<AnalysisEngine>(context, listen: false);
    final success = await engine.linkProjectToCompany(widget.projectId, _selectedCompanyId!);
    
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project successfully linked to Company!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to link project. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisEngine>(
      builder: (context, engine, child) {
        final project = engine.getProject(widget.projectId);
        final List<Company> allCompanies = engine.companies.values.toList();

        if (project == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: Text("Project not found", style: TextStyle(color: Colors.white))),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Enterprise Dark Theme
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'PROJECT SETTINGS',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2.0, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  project.name,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage connections and core settings',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                ),
                
                const SizedBox(height: 48),

                // Company Card
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
                      Row(
                        children: [
                          const Icon(Icons.business_center, color: Colors.blueAccent),
                          const SizedBox(width: 12),
                          const Text(
                            'Company Assignment',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Link this project to a master company to sync analytics and tasks globally.',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCompanyId,
                            hint: const Text('Select a Company', style: TextStyle(color: Colors.white54)),
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            items: allCompanies.map((Company company) {
                              return DropdownMenuItem<String>(
                                value: company.id,
                                child: Text(company.name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCompanyId = newValue;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Save action
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (_selectedCompanyId != null && _selectedCompanyId != project.companyId && !_isSaving) 
                              ? _handleLinkCompany 
                              : null,
                          child: _isSaving 
                              ? const SizedBox(
                                  width: 24, height: 24, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : const Text(
                                  'Sync with Company',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      },
    );
  }
}
