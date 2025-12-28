import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../support/support_screen.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';

class DesktopNavBar extends StatelessWidget {
  final int selectedIndex;
  // If null, it means we are not on the main tab view (e.g. booking flow)
  final Function(int)? onTap;

  const DesktopNavBar({super.key, this.selectedIndex = -1, this.onTap});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          // Logo Area
          GestureDetector(
            onTap: () {
              // Always go to Home if logo clicked
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem(context, "Home", 0),
              _navItem(context, "My Trips", 1),
              _navItem(context, "Favourites", 2),
              _navItem(context, "Profile", 3),
            ],
          ),

          const SizedBox(width: 40),

          // User Greeting & Dropdown
          if (authService.currentUser != null) ...[
            Consumer<ThemeController>(
              builder: (context, themeController, _) {
                final user = authService.currentUser!;
                final name = user.displayName?.split(' ').first ??
                    user.email?.split('@').first ??
                    'Traveler';
                final isDark = themeController.themeMode == ThemeMode.dark;

                return PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  tooltip: "Account Menu",
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(30),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text("Hi, $name",
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            size: 16, color: Colors.grey.shade500),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    // Header
                    PopupMenuItem(
                      enabled: false,
                      child: Text("Signed in as ${user.email ?? name}",
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5))),
                    ),
                    const PopupMenuDivider(),

                    // Profile
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text("Profile",
                              style: TextStyle(
                                fontFamily: 'Inter',
                              )),
                        ],
                      ),
                    ),

                    // Favorites
                    const PopupMenuItem(
                      value: 'favorites',
                      child: Row(
                        children: [
                          Icon(Icons.favorite, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text("Favourites",
                              style: TextStyle(
                                fontFamily: 'Inter',
                              )),
                        ],
                      ),
                    ),

                    // Settings
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text("Settings",
                              style: TextStyle(
                                fontFamily: 'Inter',
                              )),
                        ],
                      ),
                    ),

                    const PopupMenuDivider(),

                    // Theme Toggle
                    PopupMenuItem(
                      value: 'theme',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                                  size: 20, color: Colors.grey),
                              const SizedBox(width: 12),
                              Text(
                                  isDark
                                      ? "Switch to Light Mode"
                                      : "Switch to Dark Mode",
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                  )),
                            ],
                          ),
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
                          Text("Logout",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    switch (value) {
                      case 'profile':
                        if (onTap != null) onTap!(3);
                        break;
                      case 'favorites':
                        if (onTap != null) onTap!(2);
                        break; // Favorites is index 2
                      case 'settings':
                        // Placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Settings coming soon")));
                        break;
                      case 'theme':
                        themeController.setTheme(
                            isDark ? ThemeMode.light : ThemeMode.dark);
                        break;
                      case 'logout':
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', (r) => false);
                        }
                        break;
                    }
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
                  border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Support",
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

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
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Text(
                    "Logout",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, int index) {
    final bool isActive = selectedIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Explicit high contrast colors to avoid interpolation crashes
    final Color textColor = isActive
        ? AppTheme.primaryColor
        : (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!(index);
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false);
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
