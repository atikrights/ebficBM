import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebficbm/widgets/responsive_layout.dart';
import 'package:ebficbm/features/dashboard/widgets/dashboard_content.dart';
import 'package:ebficbm/features/companies/screens/company_list_screen.dart';
import 'package:ebficbm/features/projects/screens/project_list_screen.dart';
import 'package:ebficbm/features/tasks/screens/task_list_screen.dart';
import 'package:ebficbm/features/finance/screens/finance_screen.dart';
import 'package:ebficbm/features/reports/screens/reports_screen.dart';
import 'package:ebficbm/features/notes/screens/notes_screen.dart';
import 'package:ebficbm/features/broadcast/screens/broadcast_screen.dart';
import 'package:ebficbm/core/services/refresh_service.dart';
import 'package:ebficbm/features/projects/screens/project_workspace_screen.dart';
import 'package:ebficbm/core/services/update_service.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:ebficbm/features/settings/screens/update_screen.dart';
import 'package:ebficbm/features/guidelines/screens/guidelines_screen.dart';
import 'package:ebficbm/features/modules/screens/module_screen.dart';
import 'package:ebficbm/features/notices/screens/notice_screen.dart';
import 'package:ebficbm/features/assets/screens/asset_library_screen.dart';
import 'package:ebficbm/features/analysis/screens/analysis_screen.dart';


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
    
    // Check for updates on startup (Not on Web)
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UpdateService().initializeBackgroundUpdate();
      });
    }
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

  List<Widget> get _screens {
    final screens = [
      const DashboardContent(),
      const AnalysisScreen(),
      const CompanyListScreen(),
      const ProjectListScreen(),
      const TaskListScreen(),
      const FinanceScreen(),
      const ReportsScreen(),
      const NoticeScreen(),
      const NotesScreen(),
      const BroadcastScreen(),
      const AssetLibraryScreen(),
      const UpdateScreen(),
      const GuidelinesScreen(),
      const ModuleScreen(),
    ];
    if (kIsWeb) {
      screens.removeAt(11); // Remove UpdateScreen
    }
    return screens;
  }

  List<String> get _titles {
    final titles = [
      'Dashboard',
      'Analysis',
      'Companies',
      'Projects',
      'Tasks',
      'Finance',
      'Reports',
      'Official Notices',
      'Notes',
      'Broadcast',
      'Asset Library',
      'Software Update',
      'System Guidelines',
      'App Modules',
    ];
    if (kIsWeb) {
      titles.removeAt(11); // Remove Software Update title
    }
    return titles;
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    final titles = _titles;

    // Safety check: Ensure index is never out of bounds
    int safeIndex = _selectedIndex;
    if (safeIndex >= screens.length) {
      safeIndex = 0;
    }

    return ResponsiveLayout(
      title: titles[safeIndex],
      selectedIndex: safeIndex,
      onNavigationChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _saveNavigationState(index);
      },
      body: AppRefreshIndicator(child: screens[safeIndex]),
    );
  }
}
