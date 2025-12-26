import 'package:flutter/material.dart';
import 'package:buslink/utils/app_theme.dart';
import '../../home/home_screen.dart';
import '../../conductor/conductor_dashboard.dart';
import '../admin_dashboard.dart';
import '../admin_user_management.dart';

class AdminBottomNav extends StatelessWidget {
  final int selectedIndex;

  const AdminBottomNav({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const AdminDashboard();
        break;
      case 1:
        page = const AdminUserManagementScreen();
        break;
      case 2:
        page = const ConductorDashboard(isAdminView: true);
        break;
      case 3:
        page = const HomeScreen(isAdminView: true);
        break;
      default:
        return;
    }

    // Replacement to avoid stack buildup in admin tabs
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      elevation: 3,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
          label: 'Admin',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people, color: AppTheme.primaryColor),
          label: 'Roles',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon:
              Icon(Icons.confirmation_number, color: AppTheme.primaryColor),
          label: 'Scanner',
        ),
        NavigationDestination(
          icon: Icon(Icons.smartphone_outlined),
          selectedIcon: Icon(Icons.smartphone, color: AppTheme.primaryColor),
          label: 'Preview',
        ),
      ],
    );
  }
}
