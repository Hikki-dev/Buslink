import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/language_provider.dart'; // Added Import
import '../support/support_screen.dart';

import '../auth/login_screen.dart';
import '../customer_main_screen.dart';
import 'notifications_screen.dart'; // Added Import
import '../settings/account_settings_screen.dart'; // Added Import for Settings

class DesktopNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isAdminView;
  // If null, it means we are not on the main tab view (e.g. booking flow)
  final Function(int)? onTap;

  const DesktopNavBar(
      {super.key,
      this.selectedIndex = -1,
      this.isAdminView = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    final user = authService.currentUser;

    return Material(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.1),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            // Logo Area
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CustomerMainScreen(
                            initialIndex: 0, isAdminView: isAdminView)),
                    (route) => false);
              },
              child: const Row(
                children: [
                  Icon(Icons.directions_bus,
                      color: AppTheme.primaryColor, size: 30),
                  SizedBox(width: 8),
                  Text("BusLink",
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                ],
              ),
            ),

            const Spacer(),

            // Nav Items
            Consumer<LanguageProvider>(builder: (context, langProvider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _navItem(context, langProvider.translate('nav_home'), 0),
                  if (user != null) ...[
                    _navItem(
                        context, langProvider.translate('nav_my_trips'), 1),
                    _navItem(
                        context, langProvider.translate('nav_favorites'), 2),
                    _navItem(context, langProvider.translate('nav_profile'), 3),
                  ],
                ],
              );
            }),

            const SizedBox(width: 40),

            // Language Selector
            Consumer<LanguageProvider>(builder: (context, langProvider, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: PopupMenuButton<String>(
                  tooltip: langProvider.translate('language'),
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.language,
                          size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        langProvider.currentLanguage.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                  onSelected: (lang) {
                    langProvider.setLanguage(lang);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'en',
                      child: Text("English"),
                    ),
                    const PopupMenuItem(
                      value: 'si',
                      child: Text("Sinhala"),
                    ),
                    const PopupMenuItem(
                      value: 'ta',
                      child: Text("Tamil"),
                    ),
                  ],
                ),
              );
            }),

            // Notification Icon (Use StreamBuilder to listen to Auth State if needed, but 'user' variable is already from Provider)
            if (user != null) ...[
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: AppTheme.primaryColor),
                  tooltip: 'Notifications',
                  onPressed: () {
                    // Navigate to Notifications Screen
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationsScreen()));
                  },
                ),
              ),
            ],

            // User Greeting & Dropdown
            if (user != null) ...[
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>?;

                  // Priority: Firestore Name -> Auth Name -> Email -> 'Traveler'
                  String displayName = userData?['displayName'] ??
                      user.displayName ??
                      user.email?.split('@').first ??
                      'Traveler';

                  // Logic for "Hi, [Name]" - Shorten if too long
                  final rawFirst = displayName.split(' ').first;
                  final firstName = rawFirst.length > 12
                      ? "${rawFirst.substring(0, 10)}..."
                      : rawFirst;

                  // Admin badge logic if needed (optional)
                  final bool isAdmin = userData?['role'] == 'admin';

                  return Consumer<ThemeController>(
                    builder: (context, themeController, _) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;

                      // Access LangProvider for Dropdown translations
                      final langProvider =
                          Provider.of<LanguageProvider>(context);

                      return PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        tooltip: "Account Menu",
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                  "${langProvider.translate('welcome_back')}, $firstName",
                                  style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down,
                                  size: 16, color: Theme.of(context).hintColor),
                            ],
                          ),
                        ),
                        itemBuilder: (BuildContext context) {
                          return [
                            // Header
                            PopupMenuItem(
                              enabled: true, // Make clickable
                              onTap: () {
                                // Navigate to Profile
                                if (onTap != null) {
                                  onTap!(3);
                                } else {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CustomerMainScreen(
                                                  initialIndex: 3)),
                                      (route) => false);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, // Full Name here
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                                  if (userData?['email'] != null)
                                    Text(userData!['email'],
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5))),
                                  if (isAdmin)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: const Text("ADMIN",
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red)),
                                      ),
                                    )
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),

                            // Profile
                            PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(width: 12),
                                  Text(langProvider.translate('nav_profile'),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      )),
                                ],
                              ),
                            ),

                            // Favourites
                            PopupMenuItem(
                              value: 'favorites',
                              child: Row(
                                children: [
                                  Icon(Icons.favorite,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(width: 12),
                                  Text(langProvider.translate('nav_favorites'),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      )),
                                ],
                              ),
                            ),

                            // Settings
                            PopupMenuItem(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(Icons.settings,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(width: 12),
                                  Text("Settings", // Missing Translation Key
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      )),
                                ],
                              ),
                            ),

                            const PopupMenuDivider(),

                            // Theme Toggle
                            PopupMenuItem(
                              value: 'theme',
                              child: Row(
                                children: [
                                  Icon(
                                      isDark
                                          ? Icons.light_mode
                                          : Icons.dark_mode,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(width: 12),
                                  Text(
                                      isDark
                                          ? "Light Mode"
                                          : langProvider.translate('dark_mode'),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      )),
                                ],
                              ),
                            ),

                            const PopupMenuDivider(),

                            // Logout
                            PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout,
                                      size: 20, color: Colors.red.shade400),
                                  const SizedBox(width: 12),
                                  Text(langProvider.translate('log_out'),
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Colors.red.shade400,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ];
                        },
                        onSelected: (value) async {
                          switch (value) {
                            case 'profile':
                              if (onTap != null) {
                                onTap!(3);
                              } else {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CustomerMainScreen(
                                                initialIndex: 3)),
                                    (route) => false);
                              }
                              break;
                            case 'favorites':
                              if (onTap != null) {
                                onTap!(2);
                              } else {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CustomerMainScreen(
                                                initialIndex: 2)),
                                    (route) => false);
                              }
                              break;
                            case 'settings':
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AccountSettingsScreen()));
                              break;
                            case 'theme':
                              themeController.setTheme(
                                  isDark ? ThemeMode.light : ThemeMode.dark);
                              break;
                            case 'logout':
                              await authService.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                    (r) => false);
                              }
                              break;
                          }
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 24),
            ],

            // Support & Actions
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SupportScreen())),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: AppTheme.primaryColor, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Consumer<LanguageProvider>(
                      builder: (context, langProvider, child) {
                    return Text(
                      langProvider.translate('help_support'),
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryColor),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 20),

            if (user != null)
              GestureDetector(
                onTap: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Consumer<LanguageProvider>(
                      builder: (context, langProvider, child) {
                    return Row(
                      children: [
                        Icon(Icons.logout,
                            size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Text(
                          langProvider.translate('log_out'),
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.red.shade700),
                        ),
                      ],
                    );
                  }),
                ),
              )
            else
              GestureDetector(
                onTap: () async {
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Consumer<LanguageProvider>(
                      builder: (context, langProvider, child) {
                    return Row(
                      children: [
                        Icon(Icons.login,
                            size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          langProvider.translate('nav_login'),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.primaryColor),
                        ),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, int index) {
    final bool isActive = selectedIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isActive
        ? AppTheme.primaryColor
        : (isDark ? Colors.white : Colors.black); // Force Black in Light Mode

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!(index);
          } else {
            // ... existing nav logic ...
            Widget page;
            page = CustomerMainScreen(
                initialIndex: index, isAdminView: isAdminView);
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => page), (route) => false);
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold, // Always Bold as requested
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
