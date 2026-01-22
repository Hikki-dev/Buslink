import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 
import 'notifications_screen.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../favorites/favorites_screen.dart';
import '../settings/account_settings_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isAdminView;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Widget? title;

  final bool hideActions;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.isAdminView = false,
    this.leading,
    this.bottom,
    this.centerTitle = false,
    this.title,
    this.hideActions = false,
    this.automaticallyImplyLeading = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: title ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_bus,
                  color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: 8),
              const Text(
                "BusLink",
                style: TextStyle(
                    fontFamily: 'AudioWide',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor),
              ),
            ],
          ),
      centerTitle: centerTitle,
      bottom: bottom,
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
      elevation: 0,
      actions: hideActions
          ? []
          : [
              if (actions != null) ...actions!,
              // ... (actions remain same)
              // Theme Toggle
              Consumer<ThemeController>(
                builder: (context, themeController, _) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    tooltip: isDark ? "Light Mode" : "Dark Mode",
                    onPressed: () {
                      themeController
                          .setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                    },
                  );
                },
              ),

              // Language Selector
              // Language Selector Removed

              // Profile Dropdown (Middle)
              if (user != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 45),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        user.displayName != null && user.displayName!.isNotEmpty
                            ? user.displayName![0].toUpperCase()
                            : (user.email != null && user.email!.isNotEmpty
                                ? user.email![0].toUpperCase()
                                : 'U'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'profile':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()));
                          break;
                        case 'favorites':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FavoritesScreen()));
                          break;
                        case 'settings': // NEW
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AccountSettingsScreen()));
                          break;
                        case 'logout':
                          await Provider.of<AuthService>(context, listen: false)
                              .signOut();
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
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: const [
                            Icon(Icons.person, size: 20),
                            SizedBox(width: 8),
                            Text("Profile"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'favorites',
                        child: Row(
                          children: const [
                            Icon(Icons.favorite, size: 20),
                            SizedBox(width: 8),
                            Text("Favorites"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        // NEW
                        value: 'settings',
                        child: Row(
                          children: const [
                            Icon(Icons.settings, size: 20),
                            SizedBox(width: 8),
                            Text("Settings"),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout,
                                size: 20, color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Text("Logout",
                                style: TextStyle(color: Colors.red.shade400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Notifications (Last)
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()));
                },
              ),

              // Admin Badge
              if (isAdminView)
                Container(
                    margin: const EdgeInsets.only(left: 8, right: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text("ADMIN",
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
            ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
