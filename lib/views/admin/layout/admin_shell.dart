import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../../../utils/bl_colors.dart';
import '../../auth/login_screen.dart';
import '../../conductor/conductor_dashboard.dart';
import '../../customer_main_screen.dart';
import '../admin_dashboard.dart';
import '../admin_feedback_screen.dart';
import '../admin_user_management.dart';
import '../analytics/admin_analytics_dashboard.dart';
import '../bookings/admin_booking_list.dart';
import '../refunds/admin_refund_list.dart';
import '../route_management_screen.dart';

/// The admin pages on a wide screen (mockup "Desktop-Admin"): a dark red side
/// menu on the left and the page on the right. On a phone the page stands
/// alone (it keeps its own bottom bar).
class AdminShell extends StatelessWidget {
  /// 0 Dashboard, 1 Trips, 2 Routes, 3 Bookings, 4 Refunds, 5 Feedback,
  /// 6 Analytics, 7 Users and roles.
  final int selected;
  final Widget child;
  const AdminShell({super.key, required this.selected, required this.child});

  static const _items = [
    ('Dashboard', 0),
    ('Trips', 1),
    ('Routes', 2),
    ('Bookings', 3),
    ('Refunds', 4),
    ('Feedback', 5),
    ('Analytics', 6),
    ('Users and roles', 7),
  ];

  Widget _page(int i) => switch (i) {
        0 || 1 => const AdminDashboard(),
        2 => const RouteManagementScreen(),
        3 => const AdminBookingListScreen(),
        4 => const AdminRefundListScreen(),
        5 => const AdminFeedbackScreen(),
        6 => const AdminAnalyticsDashboard(),
        _ => const AdminUserManagementScreen(),
      };

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width <= 900) return child;
    return Row(
      children: [
        // The menu sits outside the page's Scaffold, so it needs its own
        // Material for text styles and ink.
        Material(
            type: MaterialType.transparency,
            child: _Side(selected: selected, items: _items, pageFor: _page)),
        Expanded(child: child),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  final int selected;
  final List<(String, int)> items;
  final Widget Function(int) pageFor;
  const _Side(
      {required this.selected, required this.items, required this.pageFor});

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, bool on, VoidCallback onTap, {IconData? icon}) =>
        Semantics(
          button: true,
          selected: on,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? BL.crimson : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  icon != null
                      ? Icon(icon,
                          size: 20, color: on ? Colors.white : BL.onCrimson)
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: (on ? Colors.white : BL.onCrimson)
                                .withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                            color: on ? Colors.white : BL.onCrimson)),
                  ),
                ],
              ),
            ),
          ),
        );

    void go(Widget page) => Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => page));

    return Container(
      width: 260,
      color: BL.crimsonDark,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('BusLink',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
            child: Text('Admin',
                style: TextStyle(fontSize: 15, color: BL.onCrimson)),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final (label, i) in items) ...[
                  tile(label, selected == i, () {
                    if (selected != i) go(pageFor(i));
                  }),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 14),
                tile(
                    'Passenger view',
                    false,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerMainScreen(
                                isAdminView: true, initialIndex: 0))),
                    icon: Icons.person_outline),
                const SizedBox(height: 6),
                tile(
                    'Conductor view',
                    false,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ConductorDashboard(isAdminView: true))),
                    icon: Icons.qr_code_scanner),
              ],
            ),
          ),
          tile('Log out', false, () async {
            await Provider.of<AuthService>(context, listen: false).signOut();
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false);
            }
          }, icon: Icons.logout),
        ],
      ),
    );
  }
}
