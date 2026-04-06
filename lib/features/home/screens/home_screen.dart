import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizos_x_pro/widgets/responsive_layout.dart';
import 'package:bizos_x_pro/features/dashboard/widgets/dashboard_content.dart';
import 'package:bizos_x_pro/features/companies/screens/company_list_screen.dart';
import 'package:bizos_x_pro/features/projects/screens/project_list_screen.dart';
import 'package:bizos_x_pro/features/tasks/screens/task_list_screen.dart';
import 'package:bizos_x_pro/features/finance/screens/finance_screen.dart';
import 'package:bizos_x_pro/features/reports/screens/reports_screen.dart';
import 'package:bizos_x_pro/features/notes/screens/notes_screen.dart';
import 'package:bizos_x_pro/core/services/refresh_service.dart';
import 'package:bizos_x_pro/features/projects/screens/project_workspace_screen.dart';
import 'package:bizos_x_pro/core/services/update_service.dart';
import 'package:bizos_x_pro/features/settings/screens/update_screen.dart';

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
