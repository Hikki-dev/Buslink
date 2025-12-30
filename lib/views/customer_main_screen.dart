import 'package:flutter/material.dart';
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
  // History stack, starting with Home (0)
  final List<int> _history = [0];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    if (_selectedIndex != 0) {
      _history.add(_selectedIndex);
    }
    // Attempt to load preview state if not already set (failsafe)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripController>().initializePersistence();
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _history.add(index);
      _selectedIndex = index;
    });
  }

  void _handleBack() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _selectedIndex = _history.last;
      });
    }
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

    // Re-build pages on every build? No, that's inefficient.
    // Ideally we should keep state. But we need to pass dynamic updated callbacks.
    // If we use 'IndexedStack', widgets are built once.
    // So we can't simply change 'showBackButton' prop inside the list unless we rebuild the list
    // OR the child widgets listen to something.
    // Since 'MyTripsScreen' is stateless, invalidating the _pages list in build is okay
    // provided the underlying keys or types don't change drastically to lose state?
    // IndexedStack preserves state of children. If we replace the child widget with a new instance
    // (same runtime type, different params), state is usually preserved if keys match or absent.
    // Let's rebuild the list in build() to pass current 'showBackButton' state.

    final bool showBack = _history.length > 1;

    final pages = [
      HomeScreen(isAdminView: widget.isAdminView), // Pass admin view
      MyTripsScreen(
          showBackButton: showBack,
          onBack: _handleBack,
          isAdminView: widget.isAdminView),
      FavoritesScreen(
          showBackButton: showBack,
          onBack: _handleBack,
          isAdminView: widget.isAdminView),
      ProfileScreen(
          showBackButton: showBack,
          onBack: _handleBack,
          isAdminView: widget.isAdminView),
    ];

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Consumer<TripController>(builder: (context, controller, child) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(children: [
            if (widget.isAdminView)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300), // Strong Amber
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.admin_panel_settings,
                                  size: 20, color: Colors.black87),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Admin Preview Mode",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // Force clean exit to root to prevent navigator stack corruption
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/', (route) => false);
                          },
                          icon: const Icon(Icons.logout,
                              size: 18, color: Colors.black87),
                          label: const Text("Exit",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
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
                  selectedItemColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  unselectedItemColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  showUnselectedLabels: true,
                  selectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold, // Bold for unselected too
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
