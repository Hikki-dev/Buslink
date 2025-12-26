import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          InkWell(
            onTap: () {
              // Always go to Home if logo clicked
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false);
            },
            child: Row(
              children: [
                Icon(Icons.directions_bus,
                    color: AppTheme.primaryColor, size: 30),
                const SizedBox(width: 8),
                Text("BusLink",
                    style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ],
            ),
          ),

          const SizedBox(width: 60),

          // Nav Items
          _navItem(context, "Home", 0),
          _navItem(context, "My Trips", 1),
          _navItem(context, "Favorites", 2),
          _navItem(context, "Profile", 3),

          const Spacer(),

          // User Greeting
          if (authService.currentUser != null) ...[
            Text(
                "Hi, ${authService.currentUser!.displayName?.split(' ').first ?? authService.currentUser!.email?.split('@').first ?? 'User'}",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87)),
            const SizedBox(width: 24),
          ],

          // Support & Actions
          OutlinedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SupportScreen())),
              child: const Text("Support")),
          const SizedBox(width: 16),

          TextButton.icon(
            onPressed: () async {
              await authService.signOut();
              // Redirect to home/login after sign out just in case
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false);
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text("Logout"),
            style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, int index) {
    final bool isActive = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(index);
          } else {
            // If we are on a deeper page (like booking), we might need to nav back to Home with index
            // For simplicity, just nav to Home and let it handle init state, or pass arguments.
            // A cleaner way for a real app is Named Routes.
            // Here we just Push Home.
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false);
          }
        },
        child: Text(label,
            style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppTheme.primaryColor : null)),
      ),
    );
  }
}
