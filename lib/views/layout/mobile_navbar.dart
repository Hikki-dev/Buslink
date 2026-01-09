import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';
import '../booking/my_trips_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../utils/language_provider.dart';

class MobileBottomNav extends StatelessWidget {
  final int selectedIndex;

  const MobileBottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex == -1 ? 0 : selectedIndex,
        onTap: (index) => _onItemTapped(context, index, user),
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            Theme.of(context).cardColor, // Use cardColor for contrast
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
        ),
        items: user == null
            ? [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: Provider.of<LanguageProvider>(context)
                      .translate('nav_home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.login),
                  activeIcon: const Icon(Icons.login),
                  label: Provider.of<LanguageProvider>(context)
                      .translate('nav_login'),
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: Provider.of<LanguageProvider>(context)
                      .translate('nav_home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.confirmation_number_outlined),
                  activeIcon: const Icon(Icons.confirmation_number),
                  label: Provider.of<LanguageProvider>(context)
                      .translate('nav_my_trips'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.favorite_border),
                  activeIcon: const Icon(Icons.favorite),
                  label: Provider.of<LanguageProvider>(context)
                      .translate('nav_favorites'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: Provider.of<LanguageProvider>(context)
                      .translate('nav_profile'),
                ),
              ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index, User? user) {
    if (index == selectedIndex) return;

    // GUEST LOGIC
    if (user == null) {
      if (index == 1) {
        // Login Page
        Navigator.pushNamed(context, '/login');
      } else {
        // Home (Refresh/Reset)
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
      return;
    }

    // USER LOGIC
    Widget page;
    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const MyTripsScreen();
        break;
      case 2:
        page = const FavoritesScreen();
        break;
      case 3:
        page = const ProfileScreen();
        break;
      default:
        page = const HomeScreen();
    }

    // Use replacement to avoid building up a huge stack
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }
}
