import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
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
          color: Colors.white,
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("BusLink",
                        style: TextStyle(fontFamily: 'Outfit', 
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    Text("CONDUCTOR",
                        style: TextStyle(fontFamily: 'Inter', 
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
          _navItem(context, "Dashboard", 0, Icons.dashboard_outlined),
          _navItem(context, "Scan Ticket", 1,
              Icons.qr_code_scanner), // Unique feature
          _navItem(context, "Reports", 2, Icons.analytics_outlined),
          _navItem(context, "Profile", 3, Icons.person_outline),

          const Spacer(),

          // User Greeting
          if (authService.currentUser != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade100,
                  child: const Icon(Icons.person, size: 18, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Text(
                    authService.currentUser!.displayName?.split(' ').first ??
                        'Conductor',
                    style: const TextStyle(fontFamily: 'Outfit', 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
              ],
            ),
            const SizedBox(width: 24),
          ],

          // Logout Action
          Container(
            height: 40,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(30)),
            child: TextButton.icon(
              onPressed: () async {
                await authService.signOut();
                // Redirect to Login
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false);
                }
              },
              icon: Icon(Icons.logout, size: 16, color: Colors.grey.shade600),
              label: Text("Logout",
                  style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
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
                  style: TextStyle(fontFamily: 'Inter', 
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
