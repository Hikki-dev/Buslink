import 'package:flutter/material.dart';
import '../../layout/bl_bottom_bar.dart';
import '../../conductor/conductor_dashboard.dart';
import '../admin_dashboard.dart';
import '../admin_user_management.dart';
import '../../customer_main_screen.dart' as customer_main_screen;

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
        // Use CustomerMainScreen wrapper so we get the Scaffold + Exit Banner
        page = const customer_main_screen.CustomerMainScreen(isAdminView: true);
        break;
      default:
        return;
    }

    // Replacement to avoid stack buildup in admin tabs
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return BlBottomBar(
      currentIndex: selectedIndex,
      onTap: (i) => _onItemTapped(context, i),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Admin'),
        BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Roles'),
        BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Scanner'),
        BottomNavigationBarItem(
            icon: Icon(Icons.smartphone_outlined),
            activeIcon: Icon(Icons.smartphone),
            label: 'Preview'),
      ],
    );
  }
}
