// lib/views/home/home_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/trip_view_model.dart';
import '../profile/profile_screen.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:buslink/services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/language_provider.dart';
import 'bulk_calendar_dialog.dart';
import '../results/bus_list_screen.dart';
import '../auth/login_screen.dart';
import 'widgets/ongoing_trip_card.dart';
// import 'widgets/favorites_section.dart'; // Removed
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';
import '../layout/notifications_screen.dart';

import '../../data/destinations_data.dart';

// Mock Data for Popular Destinatinos
// Updated Popular Destinations with High Quality Images
// Mock Data for Popular Destinatinos
// Updated Popular Destinations with functional Unsplash URLs
// Data moved to lib/data/destinations_data.dart for dynamic handling

// Fallback images for new dynamic locations (Simulating diverse "Google Images" results)
final List<String> _genericImages = [
  'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80&w=800', // Bus
  'https://images.unsplash.com/photo-1494515855673-b8a20997e3f8?auto=format&fit=crop&q=80&w=800', // Nature
  'https://images.unsplash.com/photo-1502088513349-3ff6dd7bdd0d?auto=format&fit=crop&q=80&w=800', // Scenic
  'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?auto=format&fit=crop&q=80&w=800', // Bus 2
  'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?auto=format&fit=crop&q=80&w=800', // Urban
  'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?auto=format&fit=crop&q=80&w=800', // City
  'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&q=80&w=800', // Travel
  'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&q=80&w=800', // Boat/Water
  'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=800', // Beach
  'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&q=80&w=800', // Mountain
  'https://images.unsplash.com/photo-1433086966358-54859d0ed716?auto=format&fit=crop&q=80&w=800', // Nature 2
  'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&q=80&w=800', // Lake
];

class HomeScreen extends StatefulWidget {
  final bool isAdminView;
  const HomeScreen({super.key, this.isAdminView = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  bool _isRoundTrip = false;
  bool _isBulkBooking = false;
  List<DateTime> _bulkDates = [];
  DateTime? _selectedReturnDate;

  List<Map<String, dynamic>> _currentDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadDynamicDestinations();

    // Listen to changes to update UI state (button enable/disable)
    _originController.addListener(_onInputChanged);
    _destinationController.addListener(_onInputChanged);

    // Check for pre-filled data (e.g. from Book Again)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripController =
          Provider.of<TripController>(context, listen: false);
      if (tripController.fromCity != null &&
          tripController.fromCity!.isNotEmpty) {
        _originController.text = tripController.fromCity!;
      }
      if (tripController.toCity != null && tripController.toCity!.isNotEmpty) {
        _destinationController.text = tripController.toCity!;
      }
    });
  }

  void _onInputChanged() {
    setState(() {});
  }

  Future<void> _loadDynamicDestinations() async {
    try {
      // 1. Get available cities from DB
      final availableCities = await FirestoreService().getAvailableCities();

      // 2. Prepare Final List
      List<Map<String, dynamic>> finalDestinations = [];

      // Map for O(1) lookup of static data
      final staticMap = {
        for (var d in allDestinationsData) d['city'].toString().toLowerCase(): d
      };

      if (availableCities.isNotEmpty) {
        for (var city in availableCities) {
          final lowerCity = city.toLowerCase();

          if (staticMap.containsKey(lowerCity)) {
            // Use high-quality curated data
            finalDestinations.add(staticMap[lowerCity]!);
          } else {
            // DYNAMIC FALLBACK:
            // Assign a deterministic image from the generic pool based on city name hash
            // This ensures the same city always gets the same image, even between reloads.
            final imageIndex =
                city.runes.fold(0, (p, c) => p + c) % _genericImages.length;

            finalDestinations.add({
              'city': city,
              'image': _genericImages[imageIndex],
              'desc': 'Daily services to $city.', // Generic description
              'buses': 10 + Random().nextInt(20), // Generic bus count
            });
          }
        }
      } else {
        // If DB is empty, show a default set (Colombo, Kandy, Galle)
        finalDestinations = allDestinationsData.take(3).toList();
      }

      // 3. Update State
      finalDestinations.shuffle();
      if (!context.mounted) return;
      final isDesktop = MediaQuery.of(context).size.width > 900;

      if (mounted) {
        setState(() {
          _currentDestinations =
              finalDestinations.take(isDesktop ? 6 : 4).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading destinations: $e");
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _originFocusNode.dispose();
    _destinationFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _searchBuses() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter origin and destination')),
      );
      return;
    }

    // Round Trip Validation REMOVED as per request to remove feature
    // if (_isRoundTrip && _selectedReturnDate == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //         content: Text(
    //             'Please select a Return Date for Round Trip booking.')), // Professional Error
    //   );
    //   return;
    // }

    final tripController = Provider.of<TripController>(context, listen: false);
    tripController.setFromCity(_originController.text);
    tripController.setToCity(_destinationController.text);
    tripController.setDate(_selectedDate);

    // Pass Bulk Booking State
    tripController.isBulkBooking = _isBulkBooking;
    tripController.bulkDates = _bulkDates;

    // Trigger the actual Firestore search
    tripController.searchTrips(
        _originController.text, _destinationController.text, _selectedDate);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BusListScreen(),
      ),
    );
  }

  Future<void> _selectDate() async {
    if (_isBulkBooking) {
      final result = await showDialog(
        context: context,
        builder: (context) => BulkCalendarDialog(initialDates: _bulkDates),
      );

      if (!mounted) return;

      if (result != null && result is Map) {
        final List<DateTime> dates = result['dates'];

        setState(() {
          _bulkDates = dates..sort();
          if (_bulkDates.isNotEmpty) {
            _selectedDate = _bulkDates.first;
          }
        });

        // Update Helper Text/Logic (Optional, UI reads _bulkDates)

        // Update Controller Seats (Removed legacy call)
      }
    } else {
      // Standard Single Select
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppTheme.primaryColor,
                primary: AppTheme.primaryColor,
                brightness: Theme.of(context).brightness,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime start = _selectedDate; // Can't return before departure
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReturnDate ?? start.add(const Duration(days: 1)),
      firstDate: start,
      lastDate: start.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              primary: AppTheme.primaryColor,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedReturnDate) {
      setState(() {
        _selectedReturnDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    // For Desktop, we still might want the scaffold if it's running standalone?
    // But now proper entry is CustomerMainScreen.
    // If isDesktop is true, we might want to return just the content.
    // The previous Scaffold had 'extendBodyBehindAppBar: true'.

    // If we just return the CustomScrollView, it needs a Material/Scaffold ancestor for some widgets?
    // CustomerMainScreen provides Scaffold.

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: widget.isAdminView,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (isDesktop)
                    SliverToBoxAdapter(
                        child: DesktopNavBar(
                            selectedIndex: 0, isAdminView: widget.isAdminView))
                  else
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.directions_bus,
                                color: AppTheme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text("BusLink",
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontSize: 22)),
                        ],
                      ),
                      actions: [
                        StreamBuilder<User?>(
                          stream: FirebaseAuth.instance.authStateChanges(),
                          builder: (context, authSnap) {
                            if (!authSnap.hasData) {
                              return const SizedBox.shrink();
                            }
                            final uid = authSnap.data!.uid;

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .where('userId', isEqualTo: uid)
                                  .where('isRead', isEqualTo: false)
                                  .snapshots(),
                              builder: (context, notifSnap) {
                                int unreadCount = 0;
                                if (notifSnap.hasData) {
                                  unreadCount = notifSnap.data!.docs.length;
                                }

                                return IconButton(
                                  icon: Badge(
                                    isLabelVisible: unreadCount > 0,
                                    label: Text("$unreadCount"),
                                    child: const Icon(
                                        Icons.notifications_none_rounded),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationsScreen()),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),

                        // Language Switcher (Globe Icon)
                        Consumer<LanguageProvider>(
                          builder: (context, languageProvider, child) {
                            return IconButton(
                              icon: const Icon(Icons.language),
                              tooltip: 'Switch Language',
                              onPressed: () {
                                languageProvider.toggleLanguage();
                              },
                            );
                          },
                        ),

                        // Theme Switcher
                        Consumer<ThemeController>(
                          builder: (context, themeController, child) {
                            return IconButton(
                              icon: Icon(themeController.isDark
                                  ? Icons.light_mode
                                  : Icons.dark_mode),
                              onPressed: () {
                                themeController.toggleTheme();
                              },
                            );
                          },
                        ),

                        // Profile Dropdown or Login Button
                        StreamBuilder<User?>(
                            stream: FirebaseAuth.instance.authStateChanges(),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              if (user == null) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        Navigator.pushNamed(context, '/login'),
                                    icon: const Icon(Icons.login, size: 18),
                                    label: const Text("Log In",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                );
                              }
                              return FloatingProfileMenu(user: user);
                            }),
                        const SizedBox(width: 8),
                      ],
                    ),
                  SliverToBoxAdapter(
                    child: _HeroSection(
                      isDesktop: isDesktop,
                      originController: _originController,
                      destinationController: _destinationController,
                      originFocusNode: _originFocusNode,
                      destinationFocusNode: _destinationFocusNode,
                      selectedDate: _selectedDate,
                      onDateTap: _selectDate,
                      onSearchTap: _searchBuses,
                      isRoundTrip: _isRoundTrip,
                      isBulkBooking: _isBulkBooking,
                      // NEW: Pass Return Date Logic
                      selectedReturnDate: _selectedReturnDate,
                      onReturnDateTap: () => _selectReturnDate(context),
                      onRoundTripChanged: (val) =>
                          setState(() => _isRoundTrip = val),
                      onBulkBookingChanged: (val) =>
                          setState(() => _isBulkBooking = val),
                      // NEW: Pass bulk counts
                      bulkDatesCount: _bulkDates.length,
                      // NEW: Pass Admin View Context
                      isAdminView: widget.isAdminView,
                    ),
                  ),
                  // --- ONGOING TRIPS & FAVORITES SECTION ---
                  StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        if (user == null) return const SliverToBoxAdapter();

                        return SliverToBoxAdapter(
                          child:
                              _buildDashboardSection(context, user, isDesktop),
                        );
                      }),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    sliver: SliverToBoxAdapter(
                      child: _FeaturesSection(isDesktop: isDesktop),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _PopularDestinationsGrid(
                      isDesktop: isDesktop,
                      destinations: _currentDestinations,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                  if (isDesktop) const SliverToBoxAdapter(child: AppFooter()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSection(
      BuildContext context, User user, bool isDesktop) {
    return Column(
      children: [
        const SizedBox(height: 48),
        StreamBuilder<List<Ticket>>(
          stream: Provider.of<FirestoreService>(context, listen: false)
              .getUserTickets(user.uid),
          builder: (context, ticketSnap) {
            // Logic to filter tickets will be inside the inner StreamBuilder
            // because we need the Trip object to know arrival time/status

            if (!ticketSnap.hasData || ticketSnap.data!.isEmpty) {
              return _buildFavoritesOnly(context, user.uid);
            }

            final tickets = ticketSnap.data!;

            // We need to fetch Trip details for EACH ticket to filter them.
            // This is a bit complex with Streams.
            // For simplicity/performance, let's just show the loading state or
            // proceed to the carousel which will handle filtering internally?
            // BETTER APPROACH: The Carousel should filter.
            // But if we pass all tickets, the carousel count might be wrong.
            // Let's do a solution where we check the trip status inside the carousel item builder,
            // OR ideally we should query differently.
            // Given the current structure, let's filter in the Carousel widget by
            // wrapping the list in a widget that fetches/filters or just checks logic.

            // However, to decide whether to show "No Trips" state, we need to know.
            // Let's pass ALL candidates to the carousel, and let the carousel
            // hide the ones that are completed.

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: Provider.of<FirestoreService>(context, listen: false)
                  .getUserFavoriteRoutes(user.uid),
              builder: (context, favSnap) {
                // Favorites removed as per request
                return _TripsCarouselWidget(
                    tickets: tickets,
                    favoritesWidget: const SizedBox.shrink(),
                    isDesktop: isDesktop);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFavoritesOnly(BuildContext context, String uid) {
    // Favorites removed as per request
    return const SizedBox.shrink();
  }
}

class FloatingProfileMenu extends StatefulWidget {
  final User user;
  const FloatingProfileMenu({super.key, required this.user});

  @override
  State<FloatingProfileMenu> createState() => _FloatingProfileMenuState();
}

class _FloatingProfileMenuState extends State<FloatingProfileMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _expandAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _controller.reverse().then((value) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        setState(() => _isOpen = false);
      });
    } else {
      setState(() => _isOpen = true);
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _controller.forward();
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-150, 50), // Position below and left-aligned
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: _expandAnimation,
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.user.uid)
                            .get(),
                        builder: (context, snapshot) {
                          String displayName =
                              widget.user.displayName ?? "User";
                          String photoURL = widget.user.photoURL ?? "";

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            if (data['displayName'] != null &&
                                data['displayName'].toString().isNotEmpty) {
                              displayName = data['displayName'];
                            } else if (data['name'] != null) {
                              displayName = data['name'];
                            }
                            if (data['photoURL'] != null) {
                              photoURL = data['photoURL'];
                            }
                          }

                          // Ensure we don't show "User" if email exists and name is truly missing
                          if (displayName == "User" &&
                              widget.user.email != null) {
                            displayName = widget.user.email!.split('@')[0];
                          }

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryColor,
                                backgroundImage: (photoURL.isNotEmpty)
                                    ? NetworkImage(photoURL)
                                    : null,
                                onBackgroundImageError:
                                    (photoURL.isNotEmpty) ? (_, __) {} : null,
                                child: (photoURL.isEmpty)
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : "U",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14))
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline, size: 20),
                      title: const Text("Profile"),
                      onTap: () {
                        // Close menu
                        _toggleMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen(
                                    showBackButton: true,
                                  )),
                        );
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.logout, size: 20, color: Colors.red),
                      title: const Text("Logout",
                          style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        _toggleMenu();
                        await Provider.of<AuthService>(context, listen: false)
                            .signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (route) => false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleMenu,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isOpen
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: widget.user.photoURL != null
                    ? NetworkImage(widget.user.photoURL!)
                    : null,
                onBackgroundImageError:
                    widget.user.photoURL != null ? (_, __) {} : null,
                child: widget.user.photoURL == null
                    ? const Icon(Icons.person, size: 16, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripsCarouselWidget extends StatefulWidget {
  final List<Ticket> tickets;
  final Widget favoritesWidget;
  final bool isDesktop;

  const _TripsCarouselWidget(
      {required this.tickets,
      required this.favoritesWidget,
      required this.isDesktop});

  @override
  State<_TripsCarouselWidget> createState() => _TripsCarouselWidgetState();
}

class _TripsCarouselWidgetState extends State<_TripsCarouselWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.90);
  int _currentPage = 0;
  late Stream<List<EnrichedTrip>> _tripsStream;

  @override
  void initState() {
    super.initState();
    _tripsStream = _getTripsForTickets(widget.tickets);
  }

  @override
  void didUpdateWidget(_TripsCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tickets.length != oldWidget.tickets.length ||
        (widget.tickets.isNotEmpty &&
            oldWidget.tickets.isNotEmpty &&
            widget.tickets.first.ticketId !=
                oldWidget.tickets.first.ticketId)) {
      _tripsStream = _getTripsForTickets(widget.tickets);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isDesktop)
          Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: widget.favoritesWidget))
        else
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: widget.favoritesWidget),
        const SizedBox(height: 48),

        // StreamBuilder uses the persistent stream now
        StreamBuilder<List<EnrichedTrip>>(
          stream: _tripsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            var ongoingTrips = snapshot.data!.where((t) {
              // FILTER LOGIC
              // User: "ones that are completed should dissappear"
              if (t.status == 'completed' || t.status == 'cancelled') {
                return false;
              }

              // Also hide if strictly in the past and not active
              // But if it is 'active' (e.g. onWay) but past arrival time, KEEP IT.
              bool isActive = t.status == 'boarding' ||
                  t.status == 'departed' ||
                  t.status == 'onWay' ||
                  t.status == 'arrived'; // Arrived is shown until Completed

              if (!isActive && DateTime.now().isAfter(t.arrivalTime)) {
                return false;
              }
              return true;
            }).toList();

            if (ongoingTrips.isEmpty) return const SizedBox.shrink();

            // Custom Sort: Active Match -> Scheduled
            // Custom Sort: Active Match -> Scheduled
            ongoingTrips.sort((a, b) {
              int rankA = _getTripRank(a.status);
              int rankB = _getTripRank(b.status);
              if (rankA != rankB) return rankA.compareTo(rankB);
              return a.departureTime.compareTo(b.departureTime);
            });

            // Removed single trip optimization to ensure consistent height constraint (520px) via PageView wrapper
            // if (ongoingTrips.length == 1) ...

            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 370,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: ongoingTrips.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      final ticket = widget.tickets.firstWhere(
                          (tk) => tk.tripId == ongoingTrips[index].id,
                          orElse: () => widget.tickets[0]);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: OngoingTripCard(
                          trip: ongoingTrips[index],
                          seatCount: ticket.seatNumbers.length,
                          paidAmount: ticket.totalAmount,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                        ),
                      );
                    },
                  ),
                ),
                if (_currentPage > 0)
                  Positioned(
                    left: 10,
                    child: _buildArrowButton(Icons.arrow_back_ios_new, () {
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }),
                  ),
                if (_currentPage < ongoingTrips.length - 1)
                  Positioned(
                    right: 10,
                    child: _buildArrowButton(Icons.arrow_forward_ios, () {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Icon(icon, size: 16, color: AppTheme.primaryColor),
      ),
    );
  }

  Stream<List<EnrichedTrip>> _getTripsForTickets(List<Ticket> tickets) {
    final tripIds = tickets.map((t) => t.tripId).toSet().toList();
    if (tripIds.isEmpty) return Stream.value([]);

    // We need logic to enrich. Since we can't easily access TripController instance method
    // without context in a persistent stream setup easily if we want to follow provider pattern strictly...
    // Actually, we can get FirestoreService directly or use a specific controller instance if passed.
    // Assuming we can get a transient controller or service.
    // For simplicity, let's use the Provider's service reference if possible, or just new instance.
    // Better: use the context from the widget state.

    return FirebaseFirestore.instance
        .collection('trips')
        .where(FieldPath.documentId, whereIn: tripIds.take(10).toList())
        .snapshots()
        .asyncMap((snap) async {
      try {
        final trips = <Trip>[];
        for (var doc in snap.docs) {
          try {
            trips.add(Trip.fromFirestore(doc));
          } catch (e) {
            debugPrint("Error parsing trip ${doc.id}: $e");
          }
        }

        if (trips.isEmpty) return <EnrichedTrip>[];

        final controller = TripController();
        return await controller.enrichTrips(trips);
      } catch (e) {
        debugPrint("Error enriching trips: $e");
        return <EnrichedTrip>[];
      }
    });
  }

  int _getTripRank(String status) {
    // 0 = Highest Priority (Active)
    if (status == 'departed' || status == 'onWay' || status == 'boarding') {
      return 0;
    }
    // 1 = Scheduled / On Time
    if (status == 'scheduled' || status == 'onTime' || status == 'delayed') {
      return 1;
    }
    // 2 = Arrived (Lowest priority for upcoming view)
    if (status == 'arrived') {
      return 2;
    }
    // 3 = Others (should be filtered out anyway)
    return 3;
  }
}

class _HeroSection extends StatefulWidget {
  final bool isDesktop;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final FocusNode originFocusNode;
  final FocusNode destinationFocusNode;
  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final VoidCallback onSearchTap;
  final bool isRoundTrip;
  final bool isBulkBooking;
  final int bulkDatesCount;
  // NEW: Return Date Fields
  final DateTime? selectedReturnDate;
  final VoidCallback onReturnDateTap;
  final ValueChanged<bool> onRoundTripChanged;
  final ValueChanged<bool> onBulkBookingChanged;
  final bool isAdminView;

  const _HeroSection({
    required this.isDesktop,
    required this.originController,
    required this.destinationController,
    required this.originFocusNode,
    required this.destinationFocusNode,
    required this.selectedDate,
    required this.onDateTap,
    required this.onSearchTap,
    required this.isRoundTrip,
    required this.isBulkBooking,
    required this.bulkDatesCount,
    required this.selectedReturnDate,
    required this.onReturnDateTap,
    required this.onRoundTripChanged,
    required this.onBulkBookingChanged,
    required this.isAdminView,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  int _currentImageIndex = 0;
  Timer? _timer;

  final List<Map<String, String>> _heroData = [
    {
      "image":
          "https://live.staticflickr.com/65535/55025510678_c31eb6da24_b.jpg", // User Flickr 1
      "subtitle":
          "Book your bus tickets instantly with BusLink. Reliable, fast, and secure."
    },
    {
      "image":
          "https://live.staticflickr.com/65535/55025567979_f812048ac2_h.jpg", // User Flickr 2
      "subtitle":
          "Discover the most beautiful routes across the island in comfort."
    },
    {
      "image":
          "https://live.staticflickr.com/65535/55015711501_a4d336d2c0_b.jpg", // User Flickr 3
      "subtitle": "Seamless payments and real-time tracking for your journey."
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentImageIndex = Random().nextInt(_heroData.length);
    _startTimer();

    // Fetch dynamic cities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<TripController>(context, listen: false)
            .fetchAvailableCities();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var data in _heroData) {
      precacheImage(NetworkImage(data['image']!), context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _heroData.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final user = FirebaseAuth.instance.currentUser;
      final lp = Provider.of<LanguageProvider>(context);

      return SizedBox(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 800), // Faster transition
                child: Container(
                  key: ValueKey(_heroData[_currentImageIndex]["image"]),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          _heroData[_currentImageIndex]["image"] ?? ""),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            // Subtle Dark Gradient Overlay (No Red)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Center(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: widget.isDesktop ? 600 : 550,
                ),
                padding: EdgeInsets.only(
                    top: widget.isAdminView
                        ? (widget.isDesktop
                            ? 40
                            : 20) // drastically reduced for admin preview
                        : (widget.isDesktop ? 100 : 120),
                    bottom: 40,
                    left: 20,
                    right: 20),
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // DB-Driven Greeting
                    if (user != null)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirestoreService().getUserData(user.uid),
                        builder: (context, snapshot) {
                          String name = "";

                          // 1. Try Display Name
                          if (user.displayName != null &&
                              user.displayName!.isNotEmpty) {
                            name = user.displayName!.split(' ').first;
                          }

                          // 2. Try Firestore Data (Best Source)
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            if (data.containsKey('name') &&
                                data['name'].toString().isNotEmpty) {
                              name = data['name'].toString().split(' ').first;
                            }
                          }

                          // 3. Last Resort: Extract from Email (e.g. admin@buslink -> Admin)
                          if (name.isEmpty && user.email != null) {
                            final emailName = user.email!.split('@').first;
                            // Capitalize first letter
                            name = emailName[0].toUpperCase() +
                                emailName.substring(1);
                          }

                          // 4. Fallback if somehow still empty (Should catch all)
                          if (name.isEmpty) name = lp.translate('friend');

                          String greeting = "Hi";
                          final hour = DateTime.now().hour;
                          if (hour < 12) {
                            greeting = lp.translate('good_morning');
                          } else if (hour < 17) {
                            greeting = lp.translate('good_afternoon');
                          } else {
                            greeting = lp.translate('good_evening');
                          }

                          return Text(
                            "$greeting, $name",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize:
                                  48, // Slightly smaller to fit longer text
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: const Offset(2, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      // Fallback if NOT logged in (User requested no "Traveler")
                      Text(
                        lp.translate('welcome'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 56,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(2, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      lp.translate('brand_tagline'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily:
                            'Outfit', // Changed to Outfit for cleaner look
                        fontSize: 18,
                        color: Colors.white, // Slightly transparent
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    widget.isDesktop
                        ? _buildDesktopSearchCard(isDark)
                        : _buildMobileSearch(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("HeroSection Build Error: $e");
      return SizedBox(
        height: 600,
        child: Center(
            child: Text("Visual Error (Hero): $e",
                style: const TextStyle(color: Colors.red))),
      );
    }
  }

  // New "Card Style" Desktop Search
  // New "Card Style" Desktop Search
  Widget _buildDesktopSearchCard(bool isDark) {
    final lp = Provider.of<LanguageProvider>(context);
    return _AnimateFadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 900, // Constrain width for the "Card" look
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // Adaptive Color
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tabs Removed (Round Trip Disabled)
              // Just a spacer or Title if needed?
              const SizedBox(height: 20),
              // const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)), // Divider removed too

              // 2. Bulk Booking Strip
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                color: AppTheme.primaryColor
                    .withValues(alpha: 0.08), // Light Red Strip
                child: Row(
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: widget.isBulkBooking,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (v) => widget.onBulkBookingChanged(v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      lp.translate('bulk_booking'),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Inputs Row
              Padding(
                padding: const EdgeInsets.only(
                    left: 40, right: 20, top: 24, bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInputNoBorder(
                        controller: widget.originController,
                        focusNode: widget.originFocusNode,
                        icon: Icons.my_location, // Target Icon
                        hint: lp.translate('where_from'),
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildInputNoBorder(
                        controller: widget.destinationController,
                        focusNode: widget.destinationFocusNode,
                        icon: Icons.location_on, // Pin Icon
                        hint: lp.translate('where_to'),
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    // DEPARTURE DATE
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: widget.onDateTap,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                color: AppTheme.primaryColor, size: 22),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  lp.translate('departure_date'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEE, d MMM')
                                      .format(widget.selectedDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 22),
                    SizedBox(
                      height: 54, // Slightly taller
                      width: 180, // Wider to prevent wrapping
                      child: ElevatedButton(
                        onPressed: (widget.originController.text.isNotEmpty &&
                                widget.destinationController.text.isNotEmpty &&
                                widget.originController.text
                                        .toLowerCase()
                                        .trim() !=
                                    widget.destinationController.text
                                        .toLowerCase()
                                        .trim())
                            ? widget.onSearchTap
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                          disabledForegroundColor:
                              isDark ? Colors.white38 : Colors.grey.shade600,
                          elevation: (widget.originController.text.isNotEmpty &&
                                  widget
                                      .destinationController.text.isNotEmpty &&
                                  widget.originController.text
                                          .toLowerCase()
                                          .trim() !=
                                      widget.destinationController.text
                                          .toLowerCase()
                                          .trim())
                              ? 8
                              : 0,
                          shadowColor:
                              AppTheme.primaryColor.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // More rounded
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              lp.translate('search'), // concise
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildTabItem Removed (Unused)

  Widget _buildInputNoBorder({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required FocusNode focusNode,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // No label, just hint as placeholder if empty
              Consumer<TripController>(builder: (context, tripCtrl, child) {
                return RawAutocomplete<String>(
                  textEditingController:
                      controller, // Use the TextController passed to widget
                  focusNode: focusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final tripCtrl =
                        Provider.of<TripController>(context, listen: false);
                    final lp =
                        Provider.of<LanguageProvider>(context, listen: false);
                    final cities = tripCtrl.availableCities;

                    if (textEditingValue.text.isEmpty) {
                      return cities;
                    }

                    final query = textEditingValue.text.toLowerCase();
                    return cities.where((String option) {
                      // 1. Check English Match
                      if (option.toLowerCase().contains(query)) return true;

                      // 2. Check Translated Match
                      final cityKey = option.toLowerCase().replaceAll(' ', '_');
                      final translated = lp.translate(cityKey);
                      return translated.toLowerCase().contains(query);
                    });
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: isDark ? const Color(0xFF1E2129) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 300,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final String option = options.elementAt(index);
                              // Translate city name
                              final cityKey =
                                  option.toLowerCase().replaceAll(' ', '_');
                              final translatedOption =
                                  Provider.of<LanguageProvider>(context,
                                          listen: false)
                                      .translate(cityKey);

                              return ListTile(
                                title: Text(translatedOption,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black)),
                                onTap: () => onSelected(option),
                                hoverColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, fieldController, fieldFocusNode,
                      onFieldSubmitted) {
                    return TextField(
                      controller: fieldController,
                      focusNode: fieldFocusNode,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.grey.shade400,
                            fontWeight: FontWeight.w600),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none, // Totally clean
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                      onSubmitted: (val) => onFieldSubmitted(),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSearch(bool isDark) {
    final lp = Provider.of<LanguageProvider>(context);
    return _AnimateFadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(12), // REDUCED PADDING
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSearchInput(
                controller: widget.originController,
                icon: Icons.my_location,
                label: lp.translate('origin'),
                hint: lp.translate('where_from'),
                focusNode: widget.originFocusNode,
                isLast: false,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildSearchInput(
                controller: widget.destinationController,
                icon: Icons.navigation,
                label: lp.translate('destination'),
                hint: lp.translate('where_to'),
                focusNode: widget.destinationFocusNode,
                isLast: false,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: widget.onDateTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lp.translate('departure_date'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color.fromARGB(255, 255, 255, 255)
                                      : const Color.fromARGB(255, 0, 0, 0))),
                          Text(
                              DateFormat('EEE, d MMMM')
                                  .format(widget.selectedDate),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color.fromARGB(255, 255, 255, 255)
                                      : const Color.fromARGB(255, 0, 0, 0))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // NEW: Bulk Booking Toggle for Mobile
              InkWell(
                onTap: () => widget.onBulkBookingChanged(!widget.isBulkBooking),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isBulkBooking
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isBulkBooking
                          ? AppTheme.primaryColor
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isBulkBooking
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: widget.isBulkBooking
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white70 : Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        lp.translate('bulk_booking'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (widget.originController.text.isNotEmpty &&
                          widget.destinationController.text.isNotEmpty &&
                          widget.originController.text.toLowerCase().trim() ==
                              widget.destinationController.text
                                  .toLowerCase()
                                  .trim())
                      ? null // Disable if same city
                      : widget.onSearchTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                      (widget.originController.text.isNotEmpty &&
                              widget.destinationController.text.isNotEmpty &&
                              widget.originController.text
                                      .toLowerCase()
                                      .trim() ==
                                  widget.destinationController.text
                                      .toLowerCase()
                                      .trim())
                          ? lp.translate('select_different_cities')
                          : lp.translate('search_mobile'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // buildTabButton Removed (Unused)

  Widget _buildSearchInput({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String label,
    required bool isLast,
    required bool isDark,
    required FocusNode focusNode,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: widget.isDesktop ? 16 : 0,
          vertical: 8), // Responsive Padding
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Align icon with text field
        children: [
          Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600)),
                RawAutocomplete<String>(
                  textEditingController: controller,
                  focusNode: focusNode, // Use provided FocusNode
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final tripCtrl =
                        Provider.of<TripController>(context, listen: false);
                    final lp =
                        Provider.of<LanguageProvider>(context, listen: false);
                    final cities = tripCtrl.availableCities;

                    if (textEditingValue.text.isEmpty) {
                      return cities;
                    }

                    final query = textEditingValue.text.toLowerCase();
                    return cities.where((String option) {
                      // 1. Check English Match
                      if (option.toLowerCase().contains(query)) return true;

                      // 2. Check Translated Match
                      final cityKey = option.toLowerCase().replaceAll(' ', '_');
                      final translated = lp.translate(cityKey);
                      return translated.toLowerCase().contains(query);
                    });
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical:
                                12), // Increased from 4 for better spacing
                      ),
                      onSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                    );
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: isDark ? const Color(0xFF1E2129) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxHeight: 200, maxWidth: 280),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              final cityKey =
                                  option.toLowerCase().replaceAll(' ', '_');
                              final translatedOption =
                                  Provider.of<LanguageProvider>(context,
                                          listen: false)
                                      .translate(cityKey);

                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    translatedOption,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  final bool isDesktop;
  const _FeaturesSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return _AnimateFadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        child: _FeatureItem(
                          icon: Icons.bolt,
                          title: lp.translate('fast_booking'),
                          description: lp.translate('fast_booking_desc'),
                        ),
                      ),
                      Expanded(
                        child: _FeatureItem(
                          icon: Icons.shield_outlined,
                          title: lp.translate('secure_payments'),
                          description: lp.translate('secure_payments_desc'),
                        ),
                      ),
                      Expanded(
                        child: _FeatureItem(
                          icon: Icons.location_on_outlined,
                          title: lp.translate('live_tracking'),
                          description: lp.translate('live_tracking_desc'),
                        ),
                      ),
                      Expanded(
                        child: _FeatureItem(
                          icon: Icons.support_agent,
                          title: lp.translate('support_24_7'),
                          description: lp.translate('support_desc'),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _FeatureItem(
                        icon: Icons.bolt,
                        title: 'Fast Booking',
                        description: 'Book your seats in less than 60 seconds.',
                      ),
                      const SizedBox(height: 32),
                      _FeatureItem(
                        icon: Icons.shield_outlined,
                        title: 'Secure Payments',
                        description:
                            'Protected with industry-standard encryption.',
                      ),
                      const SizedBox(height: 32),
                      _FeatureItem(
                        icon: Icons.location_on_outlined,
                        title: 'Live Tracking',
                        description: 'Track your bus in real-time on our map.',
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// Replaced by top-level definition

class _PopularDestinationsGrid extends StatefulWidget {
  final bool isDesktop;
  final List destinations;

  const _PopularDestinationsGrid({
    required this.isDesktop,
    required this.destinations,
  });

  @override
  State<_PopularDestinationsGrid> createState() =>
      _PopularDestinationsGridState();
}

class _PopularDestinationsGridState extends State<_PopularDestinationsGrid> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    // Start auto-scroll after a slight delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_autoScroll) return;
      if (!_scrollController.hasClients) return;

      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.offset;

      // Slow smooth scroll
      double nextScroll = currentScroll + 1.0;

      if (nextScroll >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(nextScroll);
      }
    });
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;
    final double current = _scrollController.offset;
    // Mobile Card Width (240) + Margin (20) = 260
    final double target =
        (current - 260).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    setState(() => _autoScroll = false);
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    final double current = _scrollController.offset;
    // Mobile Card Width (240) + Margin (20) = 260
    final double target =
        (current + 260).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    setState(() => _autoScroll = false);
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    // If we have few items, don't auto-scroll excessively
    if (widget.destinations.length < 4) {
      _autoScroll = false;
    }

    return _AnimateFadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lp.translate('popular_destinations'),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24, // Reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.isDesktop)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _scrollLeft,
                              icon:
                                  const Icon(Icons.arrow_back_ios_new_rounded),
                              tooltip: "Scroll Left",
                              iconSize: 20,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: _scrollRight,
                              icon: const Icon(Icons.arrow_forward_ios_rounded),
                              tooltip: "Scroll Right",
                              iconSize: 20,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 320, // Height for the cards
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _autoScroll = false),
                    onExit: (_) => setState(() => _autoScroll = true),
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.destinations.length,
                      itemBuilder: (context, index) {
                        final dest = widget.destinations[index];
                        return Container(
                          width:
                              widget.isDesktop ? 280 : 240, // Fixed width cards
                          margin: const EdgeInsets.only(right: 20),
                          child: _DestinationCard(
                            city: dest['city'],
                            imageUrl: dest['image'],
                            busCount: (dest['buses'] ?? 0) as int,
                            description: dest['desc'],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatefulWidget {
  final String city;
  final String imageUrl;
  final int busCount;
  final String description;

  const _DestinationCard({
    required this.city,
    required this.imageUrl,
    required this.busCount,
    this.description = '',
  });

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    // Derive keys from city name (e.g. "Colombo" -> "colombo", "colombo_desc")
    final cityKey = widget.city.toLowerCase().replaceAll(' ', '_');
    final descKey = "${cityKey}_desc";

    // Check if translation exists, else fall back to original text to be safe
    // Actually lp.translate falls back to key if not found.
    // But original text ("The vibrant...") is NOT the key.
    // If translations are comprehensive, this is fine.
    // If not, we might show "colombo_desc" instead of English text if key missing.
    // But I just added all keys.

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          // On mobile/touch devices, tap to toggle hover state
          setState(() => _isHovering = !_isHovering);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white24, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Gradient
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black
                            .withValues(alpha: _isHovering ? 0.95 : 0.8),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),
              // Text Content
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lp.translate(cityKey) == cityKey
                          ? widget.city
                          : lp.translate(cityKey),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedCrossFade(
                      firstChild: Text(
                        '${widget.busCount} Buses Daily',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.busCount} Buses Daily',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lp.translate(descKey) == descKey
                                ? widget.description
                                : lp.translate(descKey),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      crossFadeState: _isHovering
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimateFadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimateFadeInUp({required this.child, this.delay = Duration.zero});

  @override
  State<_AnimateFadeInUp> createState() => _AnimateFadeInUpState();
}

class _AnimateFadeInUpState extends State<_AnimateFadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _translate = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _translate,
        child: widget.child,
      ),
    );
  }
}
