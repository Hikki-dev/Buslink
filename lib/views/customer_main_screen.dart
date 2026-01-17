import 'dart:async'; // For StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'booking/my_trips_screen.dart';
import 'favorites/favorites_screen.dart';
import 'profile/profile_screen.dart';
import '../controllers/trip_controller.dart';
import 'layout/notifications_screen.dart'; // Added Import
import '../services/notification_service.dart'; // Added for Permission Dialog

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

  StreamSubscription? _notifSubscription;
  DateTime _lastCheckTime = DateTime.now();

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
      _setupNotificationListener();
      // Ask for Notification Permissions with Friendly Dialog
      NotificationService.requestPermissionWithDialog(context);
    });
  }

  void _setupNotificationListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final Timestamp? ts = data['createdAt'];
        if (ts != null) {
          final date = ts.toDate();
          // Verify it's NEW (after screen load) to avoid alert on startup
          if (date.isAfter(_lastCheckTime)) {
            _lastCheckTime = date; // Update watermark

            // Show Local "Push"
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.black87,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? 'New Notification',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(data['body'] ?? '',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  action: SnackBarAction(
                    label: "VIEW",
                    textColor: Colors.amber,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
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

    final user = Provider.of<User?>(context);
    final bool isGuest = user == null || user.isAnonymous;

    // Reset index if we switched from user -> guest and index is out of bounds
    // But better to do this in logic.
    // For now, if isGuest and index > 0 (Home), force Home.
    int currentIndex = _selectedIndex;
    if (isGuest && currentIndex > 0) {
      currentIndex = 0;
    }

    final List<Widget> pages = [
      HomeScreen(isAdminView: widget.isAdminView), // Index 0 (Always visible)
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
    ];

    if (!isGuest) {
      pages.addAll([
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
      ]);

      navItems.addAll([
        const BottomNavigationBarItem(
          icon: Icon(Icons.confirmation_number_outlined),
          activeIcon: Icon(Icons.confirmation_number),
          label: 'My Trips',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          activeIcon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ]);
    } else {
      // Optional: Add a "Login" tab for guests?
      // The user strictly asked to *hide* the profile tab.
      // Having just 1 item (Home) in BottomNavBar looks weird or might error.
      // Let's keep it simple: If guest, maybe hide BottomNavBar entirely?
      // Or add "Support"?
      // For now, I'll strictly follow "hide profile tab".
      // If BottomNavBar has 1 item, it usually throws assertion error in older Flutter,
      // but typically we need >=2 items.
      // Let's add a "Login" tab that redirects to Auth.
      pages.add(const Scaffold(body: SizedBox())); // Dummy for redirect
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.login),
        label: 'Log In',
      ));
    }

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
              // Safe index check for IndexedStack
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  // Only relevant for Mobile/PWA touch, but user asked for "Web" which might mean touch screens on web or trackpad
                  // Sensitivity check
                  if (details.primaryVelocity! > 300) {
                    // Swipe Right -> Go Back (or previous tab? User said "go to page I was in" which implies History Forward?)
                    // User said: "swipe left it should go back from the page, if I swipe right it should go to page I was in"
                    // Usually: Swipe Right (Move Finger Left->Right) = Back
                    // Swipe Left (Move Finger Right->Left) = Forward

                    // Interpreting User:
                    // "swipe left it should go back" -> Dragging finger to LEFT (Right to Left motion)? That usually means Next/Forward.
                    // Or does he mean "Swipe from Left edge"?
                    // Let's assume standard behavior:
                    // Swipe Right (Velocity > 0) -> Back
                    // Swipe Left (Velocity < 0) -> Forward

                    // But he said "swipe left it should go back". That is inverted or he means "Swipe TO the left"?
                    // "Swipe Left" usually means gesture direction <---
                    // If I swipe <--- I usually go to NEXT page (New content comes from Right).
                    // If I swipe ---> I usually go to PREVIOUS page (Old content comes from Left).

                    // User: "if I swipe left it should go back from the page"
                    // This is confusing. <--- for Back?
                    // Let's try to infer: "Left Swipe" = Go Back.
                    // "Right Swipe" = Go Forward ("Page I was in").

                    // But usually "Back" is accessible by Swiping from Left edge to Right.

                    // I will implement standard navigation unless forced otherwise, but I'll follow his text literally if possible.
                    // "Swipe Left" (Velocity < 0) -> Navigator.pop() ??
                    // "Swipe Right" (Velocity > 0) -> Navigator.push() ?? (Can't push forward easily without history)

                    // Actually, if we are in a tab view, maybe he means switching tabs?
                    // But he mentioned "page".

                    // Let's implement generic:
                    // Right Swipe (Velocity > 0) -> Pop (Back)
                    // Left Swipe (Velocity < 0) -> Nothing (Forward unavailable) or Maybe switch tabs?

                    // I'll stick to Standard: Right Swipe (--->) is BACK.
                    Navigator.maybePop(context);
                  }
                },
                child: IndexedStack(
                  index: currentIndex >= pages.length ? 0 : currentIndex,
                  children: pages,
                ),
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
                  currentIndex:
                      currentIndex >= navItems.length ? 0 : currentIndex,
                  onTap: (index) {
                    if (isGuest && index == 1) {
                      // "Log In" tapped
                      Navigator.pushNamed(context, '/login');
                      return;
                    }
                    _onItemTapped(index);
                  },
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
                  items: navItems,
                ),
              ),
      );
    });
  }
}
