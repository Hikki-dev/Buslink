import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/bl_colors.dart';
import '../support/support_screen.dart';
import '../auth/login_screen.dart';
import '../customer_main_screen.dart';
import 'notifications_screen.dart';
import 'package:buslink/views/widgets/language_selector.dart';
import 'package:buslink/views/settings/account_settings_screen.dart';
import 'package:buslink/l10n/app_localizations.dart';

/// The white top bar on desktop (mockup "Desktop-Home"): wordmark, four
/// big links, the traveller's initials and a plain "Log out" button.
class DesktopNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isAdminView;
  final Function(int)? onTap;

  const DesktopNavBar(
      {super.key,
      this.selectedIndex = -1,
      this.isAdminView = false,
      this.onTap});

  void _go(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => CustomerMainScreen(
                  initialIndex: index, isAdminView: isAdminView)),
          (route) => false);
    }
  }

  Future<void> _logOut(BuildContext context) async {
    await Provider.of<AuthService>(context, listen: false).signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return Container(
      decoration: BoxDecoration(
        color: BL.surface,
        border: Border(bottom: BorderSide(color: BL.hairline)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200, minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _go(context, 0),
                  child: Text('BusLink',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: BL.link)),
                ),
                const Spacer(),
                _link(context, l10n.navHome, 0),
                if (user != null) ...[
                  _link(context, l10n.navMyTrips, 1),
                  _link(context, l10n.navFavorites, 2),
                ],
                _link(context, l10n.navSupport, -2, onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SupportScreen()));
                }),
                const Spacer(),
                const LanguageSelector(),
                if (user != null) ...[
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded,
                        color: BL.link, size: 26),
                    tooltip: 'Notifications',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen())),
                  ),
                  const SizedBox(width: 4),
                  _account(context, user.uid, user.displayName, user.email),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _logOut(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      foregroundColor: BL.ink,
                      side: BorderSide(color: BL.border, width: 1.5),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    child: Text(l10n.navLogout),
                  ),
                ] else
                  FilledButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      backgroundColor: BL.crimson,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    child: Text(l10n.navLogin),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(BuildContext context, String label, int index,
      {VoidCallback? onPressed}) {
    final active = selectedIndex == index;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onPressed ?? () => _go(context, index),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: active ? BL.crimson : Colors.transparent, width: 3)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? BL.link : BL.inkSoft)),
        ),
      ),
    );
  }

  /// Initials circle; tapping it opens the account menu (profile, settings,
  /// light/dark mode).
  Widget _account(
      BuildContext context, String uid, String? authName, String? email) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = (data?['displayName'] ?? data?['name'] ?? authName ?? '')
            .toString();
        final shown = name.isNotEmpty ? name : (email?.split('@').first ?? '');
        final isAdmin = data?['role'] == 'admin';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = Provider.of<ThemeController>(context, listen: false);
        return PopupMenuButton<String>(
          tooltip: 'Account menu for $shown',
          offset: const Offset(0, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (v) {
            switch (v) {
              case 'profile':
                _go(context, 3);
              case 'settings':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen()));
              case 'theme':
                theme.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shown,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: BL.ink)),
                  if (email != null)
                    Text(email,
                        style: TextStyle(fontSize: 14, color: BL.muted)),
                  if (isAdmin)
                    Text('Administrator',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BL.link)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
                value: 'profile',
                height: 48,
                child: Text('Profile', style: TextStyle(fontSize: 16))),
            const PopupMenuItem(
                value: 'settings',
                height: 48,
                child: Text('Settings', style: TextStyle(fontSize: 16))),
            PopupMenuItem(
                value: 'theme',
                height: 48,
                child: Text(isDark ? 'Light mode' : 'Dark mode',
                    style: const TextStyle(fontSize: 16))),
          ],
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: BL.blush, shape: BoxShape.circle),
            child: Text(_initials(shown),
                style: TextStyle(color: BL.deep, fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }
}
