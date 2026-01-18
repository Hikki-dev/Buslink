import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/language_provider.dart';

import '../../conductor/conductor_dashboard.dart';
import '../admin_dashboard.dart';
import '../admin_user_management.dart';
import '../../customer_main_screen.dart';
import '../../auth/login_screen.dart';

class AdminNavBar extends StatelessWidget {
  final int selectedIndex;

  const AdminNavBar({super.key, this.selectedIndex = 0});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
            bottom: false,
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Logo Area
                  InkWell(
                    onTap: () {
                      // Reload Admin Dashboard
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminDashboard()));
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.admin_panel_settings,
                              color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("BusLink",
                                style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                            Text("ADMIN CONSOLE",
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.grey,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Desktop Nav links (Hidden on mobile)
                  if (MediaQuery.of(context).size.width > 800) ...[
                    _navLink(
                        context,
                        Provider.of<LanguageProvider>(context)
                            .translate('admin_dashboard'),
                        0,
                        () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminDashboard()))),
                    _navLink(
                        context,
                        Provider.of<LanguageProvider>(context)
                            .translate('user_view'),
                        1,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CustomerMainScreen(
                                    isAdminView: true, initialIndex: 0)))),
                    _navLink(
                        context,
                        Provider.of<LanguageProvider>(context)
                            .translate('conductor_view'),
                        2,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ConductorDashboard(
                                    isAdminView: true)))),
                    _navLink(
                        context,
                        Provider.of<LanguageProvider>(context)
                            .translate('roles'),
                        3, // Index 3
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AdminUserManagementScreen()))),
                  ] else ...[
                    // Mobile Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu),
                      onSelected: (value) {
                        switch (value) {
                          case 'Dashboard':
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminDashboard()));
                            break;
                          case 'User View':
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CustomerMainScreen(
                                        isAdminView: true, initialIndex: 0)));
                            break;
                          case 'Conductor View':
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ConductorDashboard(
                                        isAdminView: true)));
                            break;
                          case 'Roles':
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminUserManagementScreen()));
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        final lp = Provider.of<LanguageProvider>(context,
                            listen: false);
                        return [
                          PopupMenuItem(
                              value: 'Dashboard',
                              child: Text(lp.translate('admin_dashboard'))),
                          PopupMenuItem(
                              value: 'User View',
                              child: Text(lp.translate('user_view'))),
                          PopupMenuItem(
                              value: 'Conductor View',
                              child: Text(lp.translate('conductor_view'))),
                          PopupMenuItem(
                              value: 'Roles',
                              child: Text(lp.translate('roles'))),
                        ];
                      },
                    ),
                  ],

                  if (MediaQuery.of(context).size.width > 800) ...[
                    const SizedBox(width: 16),
                    // Language Selector (Desktop)
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, _) {
                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.language, color: Colors.grey),
                          tooltip: "Change Language",
                          onSelected: (String code) {
                            languageProvider.setLanguage(code);
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'en',
                              child: Text('English'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'si',
                              child: Text('සිංහල (Sinhala)'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'ta',
                              child: Text('தமிழ் (Tamil)'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],

                  // User Profile / Logout
                  PopupMenuButton<String>(
                    child: const CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true)
                              .pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (route) => false);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          enabled: false, child: Text("Admin User")),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [
                          Icon(Icons.logout, size: 16),
                          SizedBox(width: 8),
                          Text("Logout")
                        ]),
                      ),
                    ],
                  )
                ],
              ),
            )));
  }

  Widget _navLink(
      BuildContext context, String label, int index, VoidCallback onTap) {
    final bool isActive = selectedIndex == index;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? AppTheme.primaryColor
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[700]),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
