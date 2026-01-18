import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/language_provider.dart';
import '../auth/login_screen.dart';

class ConductorNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;

  const ConductorNavBar({super.key, this.selectedIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border:
              Border(bottom: BorderSide(color: Colors.red.shade100, width: 2)),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.05), blurRadius: 10)
          ]),
      child: Row(
        children: [
          // Logo Area - Unique Conductor Branding
          InkWell(
            onTap: () {
              // Stay on dashboard or go home? Conductor usually stays on their dashboard.
              // If they click logo, maybe refresh dashboard.
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("BusLink",
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface)),
                    Text("CONDUCTOR",
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 60),

          // Conductor Specific Generic Items
          _navItem(
              context,
              Provider.of<LanguageProvider>(context)
                  .translate('admin_dashboard'),
              0,
              Icons.dashboard_outlined),
          _navItem(
              context,
              Provider.of<LanguageProvider>(context).translate('scan_ticket'),
              1,
              Icons.qr_code_scanner), // Unique feature
          _navItem(
              context,
              Provider.of<LanguageProvider>(context).translate('reports'),
              2,
              Icons.analytics_outlined),
          _navItem(
              context,
              Provider.of<LanguageProvider>(context).translate('nav_profile'),
              3,
              Icons.person_outline),

          const Spacer(),

          // Language Selector
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.language, color: Colors.grey),
                tooltip: "Change Language",
                onSelected: (String code) {
                  languageProvider.setLanguage(code);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
          const SizedBox(width: 16),

          // Profile Dropdown
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person,
                      size: 20, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                    authService.currentUser!.displayName?.split(' ').first ??
                        'Conductor',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: Colors.grey),
              ],
            ),
            itemBuilder: (context) => [
              // Theme Toggle
              PopupMenuItem(
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Dark Mode",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Switch(
                          value: isDark,
                          activeTrackColor: AppTheme.primaryColor,
                          activeThumbColor: Colors
                              .white, // Switch thumb color works differently now, usually track color defines it.
                          // Or use standard Material 3 Switch logic
                          // activeColor actually controls the THUMB color when ON.
                          // activeTrackColor controls TRACK when ON.
                          // Let's just stick to default or simple overrides.
                          onChanged: (val) {
                            final themeController =
                                Provider.of<ThemeController>(context,
                                    listen: false);
                            themeController.setTheme(
                                val ? ThemeMode.dark : ThemeMode.light);
                            Navigator.pop(
                                context); // Close menu to apply visual update
                          },
                        )
                      ],
                    );
                  },
                ),
              ),
              const PopupMenuDivider(),
              // Logout
              PopupMenuItem(
                value: 'logout',
                onTap: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false);
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 12),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, String label, int index, IconData icon) {
    final bool isActive = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(index);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8))
              : null,
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color:
                      isActive ? AppTheme.primaryColor : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}
