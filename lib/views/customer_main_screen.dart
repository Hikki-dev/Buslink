import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'home/home_screen.dart';
import 'booking/my_trips_screen.dart';
import 'favorites/favorites_screen.dart';
import 'profile/profile_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  final bool isAdminView;
  final int initialIndex;
  const CustomerMainScreen(
      {super.key, this.isAdminView = false, this.initialIndex = 0});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      const HomeScreen(),
      const MyTripsScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine Desktop
    // Note: If desktop, the logic in child screens (DesktopNavBar) usually takes over.
    // However, for consistency, if we are in Admin Preview mode (often mobile simulation),
    // we want this wrapper to persist.
    // If we're on actual Desktop, the child screens render their own Scaffolds.
    // The issue is: If child screens have Scaffolds, they clash with this Scaffold?
    // We should only use this wrapper for Mobile/Tablet or Preview Mode.
    // BUT child screens currently verify isDesktop.

    // Let's pass 'false' to children or refactor children to NOT have scaffold for mobile.
    // Refactoring children is cleaner.

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(children: [
          // --- Persistent Admin Preview Banner ---
          if (widget.isAdminView)
            Container(
              width: double.infinity,
              color: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.black, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      "Welcome Admin - Preview Mode",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(100)),
                      child: TextButton(
                        onPressed: () {
                          // Exit preview -> Go back to Admin Dashboard
                          // Since we pushed/replaced, we might need to route explicitly
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/admin', (route) => false);
                        },
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: Colors.black),
                        child: const Text("EXIT",
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ]),
      ),
      bottomNavigationBar: isDesktop
          ? null // Desktop usually handles its own or doesn't use bottom nav
          : Container(
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
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).cardColor,
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
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.confirmation_number_outlined),
                    activeIcon: Icon(Icons.confirmation_number),
                    label: 'My Trips',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border),
                    activeIcon: Icon(Icons.favorite),
                    label: 'Favorites',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
    );
  }
}
