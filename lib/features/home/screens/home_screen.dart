import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebficBM/widgets/responsive_layout.dart';
import 'package:ebficBM/features/dashboard/widgets/dashboard_content.dart';
import 'package:ebficBM/features/companies/screens/company_list_screen.dart';
import 'package:ebficBM/features/projects/screens/project_list_screen.dart';
import 'package:ebficBM/features/tasks/screens/task_list_screen.dart';
import 'package:ebficBM/features/finance/screens/finance_screen.dart';
import 'package:ebficBM/features/reports/screens/reports_screen.dart';
import 'package:ebficBM/features/notes/screens/notes_screen.dart';
import 'package:ebficBM/core/services/refresh_service.dart';
import 'package:ebficBM/features/projects/screens/project_workspace_screen.dart';
import 'package:ebficBM/core/services/update_service.dart';
import 'package:ebficBM/features/settings/screens/update_screen.dart';
import 'package:ebficBM/features/guidelines/screens/guidelines_screen.dart';
import 'package:ebficBM/features/modules/screens/module_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNavigationState();
    
    // Check for updates on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdate(context);
    });
  }

  Future<void> _loadNavigationState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('selected_home_index') ?? 0;
    final activeProjectId = prefs.getString('active_workspace_id');

    if (mounted) {
      setState(() => _selectedIndex = savedIndex);
      
      // If we were inside a project before refresh, jump back in!
      if (activeProjectId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProjectWorkspaceScreen(projectId: activeProjectId)),
            );
          }
        });
      }
    }
  }

  Future<void> _saveNavigationState(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_home_index', index);
  }

  final List<Widget> _screens = [
    const DashboardContent(),
    const CompanyListScreen(),
    const ProjectListScreen(),
    const TaskListScreen(),
    const FinanceScreen(),
    const ReportsScreen(),
    const NotesScreen(),
    const UpdateScreen(),
    const GuidelinesScreen(),
    const ModuleScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Companies',
    'Projects',
    'Tasks',
    'Finance',
    'Reports',
    'Notes',
    'Software Update',
    'System Guidelines',
    'App Modules',
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: _titles[_selectedIndex],
      selectedIndex: _selectedIndex,
      onNavigationChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _saveNavigationState(index);
      },
      body: AppRefreshIndicator(child: _screens[_selectedIndex]),
    );
  }
}
