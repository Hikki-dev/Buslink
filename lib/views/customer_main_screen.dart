import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'home/home_screen.dart';
import 'booking/my_trips_screen.dart';
import 'favorites/favorites_screen.dart';
import 'profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../controllers/trip_controller.dart';

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
    // Attempt to load preview state if not already set (failsafe)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripController>().initializePersistence();
    });
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

    return Consumer<TripController>(builder: (context, controller, child) {
      final isPreview = widget.isAdminView || controller.isPreviewMode;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            children: [
              // Main Content
              Column(children: [
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ]),

              // Persistent Admin Preview Pill
              if (isPreview)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.black, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            "Admin Preview",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 24, // Smaller button
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(100)),
                            child: TextButton(
                              onPressed: () async {
                                // Exit preview -> Reset state and Go back
                                await controller.setPreviewMode(false);
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/admin', (route) => false);
                                }
                              },
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: Colors.black),
                              child: const Text("EXIT",
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    });
  }
}
