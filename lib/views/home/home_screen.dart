// lib/views/home/home_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../data/cities.dart';
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
import 'widgets/ongoing_trip_card.dart';
import 'widgets/favorites_section.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';

// Mock Data for Popular Destinatinos
final List<Map<String, dynamic>> _allDestinations = [
  {
    'city': 'Colombo',
    'image':
        'https://images.unsplash.com/photo-1588258524675-c61d3364e9a6?auto=format&fit=crop&q=80&w=800',
    'buses': 45,
    'desc': 'Discover the vibrant capital and commercial hub.'
  },
  {
    'city': 'Kandy',
    'image':
        'https://images.unsplash.com/photo-1587595431973-160d0d94add1?auto=format&fit=crop&q=80&w=800',
    'buses': 32,
    'desc': 'Visit the Temple of the Tooth and scenic lake.'
  },
  {
    'city': 'Galle',
    'image':
        'https://images.unsplash.com/photo-1578583489240-629424601b0b?auto=format&fit=crop&q=80&w=800',
    'buses': 64,
    'desc': 'Explore the historic Dutch Fort and beaches.'
  },
  {
    'city': 'Ella',
    'image':
        'https://images.unsplash.com/photo-1534313314376-a72289b6181e?auto=format&fit=crop&q=80&w=800',
    'buses': 18,
    'desc': 'Hiking trails, waterfalls and the Nine Arch Bridge.'
  },
  {
    'city': 'Nuwara Eliya',
    'image':
        'https://images.unsplash.com/photo-1586095033777-6e42b8d0034a?auto=format&fit=crop&q=80&w=800',
    'buses': 24,
    'desc': 'Little England of Sri Lanka with cool climate.'
  },
  {
    'city': 'Sigiriya',
    'image':
        'https://images.unsplash.com/photo-1620619767323-b95185694386?auto=format&fit=crop&q=80&w=800',
    'buses': 25,
    'desc': 'The ancient rock fortress and palace ruins.'
  },
  {
    'city': 'Jaffna',
    'image':
        'https://images.unsplash.com/photo-1596555184756-3c58b4566b59?auto=format&fit=crop&q=80&w=800',
    'buses': 20,
    'desc': 'Rich history and unique northern culture.'
  },
  {
    'city': 'Trincomalee',
    'image':
        'https://images.unsplash.com/photo-1629864276707-1b033620023e?auto=format&fit=crop&q=80&w=800',
    'buses': 35,
    'desc': 'Beautiful beaches and diving spots.'
  }
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
  List<DateTime> _bulkDates = []; // NEW: Bulk Dates
  DateTime? _selectedReturnDate; // NEW: Return Date State

  List<Map<String, dynamic>> _currentDestinations = [];

  @override
  void initState() {
    super.initState();
    // Shuffle and pick 4
    var list = List<Map<String, dynamic>>.from(_allDestinations);
    list.shuffle();
    _currentDestinations = list.take(4).toList();

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
    // NEW: Pass bulk dates
    if (_isBulkBooking) {
      if (_bulkDates.isEmpty) {
        // Fallback to selected date if empty
        _bulkDates = [_selectedDate];
      }
      tripController.setBulkDates(_bulkDates);
    }
    // Round Trip logic disabled
    tripController.setRoundTrip(false);
    tripController.setBulkMode(_isBulkBooking);

    // Trigger the actual Firestore search
    tripController.searchTrips(context);

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
        final int seats = result['seats'];

        setState(() {
          _bulkDates = dates..sort();
          if (_bulkDates.isNotEmpty) {
            _selectedDate = _bulkDates.first;
          }
        });

        // Update Helper Text/Logic (Optional, UI reads _bulkDates)

        // Update Controller Seats
        Provider.of<TripController>(context, listen: false)
            .setSeatsPerTrip(seats);
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
                        // Notification Icon
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded),
                          onPressed: () {}, // Todo: Notifications
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

                        // Profile Dropdown (New Animated One)
                        StreamBuilder<User?>(
                            stream: FirebaseAuth.instance.authStateChanges(),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              if (user == null) {
                                return IconButton(
                                  icon: const Icon(Icons.login),
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/'),
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
                      onDateTap: () => _selectDate(context),
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
                final favorites = favSnap.data ?? [];
                final favoritesWidget = FavoritesSection(
                  favorites: favorites,
                  onTap: (fav) {
                    setState(() {
                      _originController.text = fav['fromCity'];
                      _destinationController.text = fav['toCity'];
                      _searchBuses();
                    });
                  },
                );

                return _TripsCarouselWidget(
                    tickets: tickets,
                    favoritesWidget: favoritesWidget,
                    isDesktop: isDesktop);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFavoritesOnly(BuildContext context, String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<FirestoreService>(context, listen: false)
            .getUserFavoriteRoutes(uid),
        builder: (context, favSnap) {
          final favorites = favSnap.data ?? [];
          return FavoritesSection(
            favorites: favorites,
            onTap: (fav) {
              setState(() {
                _originController.text = fav['fromCity'];
                _destinationController.text = fav['toCity'];
                _searchBuses();
              });
            },
          );
        });
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
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                                widget.user.displayName?[0].toUpperCase() ??
                                    "U",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(widget.user.displayName ?? "User",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
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
                        // In a real app we would navigate
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.logout, size: 20, color: Colors.red),
                      title: const Text("Logout",
                          style: TextStyle(color: Colors.red)),
                      onTap: () {
                        _toggleMenu();
                        Provider.of<AuthService>(context, listen: false)
                            .signOut();
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
  late Stream<List<Trip>> _tripsStream;

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
        const SizedBox(height: 20),

        // StreamBuilder uses the persistent stream now
        StreamBuilder<List<Trip>>(
          stream: _tripsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            var ongoingTrips = snapshot.data!.where((t) {
              // FILTER LOGIC
              // User: "ones that are completed should dissappear"
              if (t.status == TripStatus.completed ||
                  t.status == TripStatus.cancelled) {
                return false;
              }

              // Also hide if strictly in the past and not active
              // But if it is 'active' (e.g. onWay) but past arrival time, KEEP IT.
              bool isActive = t.status == TripStatus.boarding ||
                  t.status == TripStatus.departed ||
                  t.status == TripStatus.onWay ||
                  t.status ==
                      TripStatus.arrived; // Arrived is shown until Completed

              if (!isActive && DateTime.now().isAfter(t.arrivalTime)) {
                return false;
              }
              return true;
            }).toList();

            if (ongoingTrips.isEmpty) return const SizedBox.shrink();

            // Custom Sort: Active Match -> Scheduled
            ongoingTrips.sort((a, b) {
              int rankA = _getTripRank(a.status);
              int rankB = _getTripRank(b.status);
              if (rankA != rankB) return rankA.compareTo(rankB);
              return a.departureTime.compareTo(b.departureTime);
            });

            if (ongoingTrips.length == 1) {
              return _buildSingleTrip(ongoingTrips.first);
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 420,
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

  Widget _buildSingleTrip(Trip trip) {
    final ticket = widget.tickets.firstWhere((tk) => tk.tripId == trip.id,
        orElse: () => widget.tickets[0]);
    return OngoingTripCard(
      trip: trip,
      seatCount: ticket.seatNumbers.length,
      paidAmount: ticket.totalAmount,
    );
  }

  Stream<List<Trip>> _getTripsForTickets(List<Ticket> tickets) {
    final tripIds = tickets.map((t) => t.tripId).toSet().toList();
    if (tripIds.isEmpty) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('trips')
        .where(FieldPath.documentId, whereIn: tripIds.take(10).toList())
        .snapshots()
        .map(
            (snap) => snap.docs.map((doc) => Trip.fromFirestore(doc)).toList());
  }

  int _getTripRank(TripStatus status) {
    // 0 = Highest Priority (Active)
    if (status == TripStatus.departed ||
        status == TripStatus.onWay ||
        status == TripStatus.boarding) {
      return 0;
    }
    // 1 = Scheduled / On Time
    if (status == TripStatus.scheduled ||
        status == TripStatus.onTime ||
        status == TripStatus.delayed) {
      return 1;
    }
    // 2 = Arrived (Lowest priority for upcoming view)
    if (status == TripStatus.arrived) {
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
          "https://upload.wikimedia.org/wikipedia/commons/c/c8/Sri_Lanka_Bus.jpg",
      "subtitle":
          "Book your bus tickets instantly with BusLink. Reliable, fast, and secure."
    },
    {
      "image":
          "https://upload.wikimedia.org/wikipedia/commons/2/2e/Lanka_Ashok_Leyland_bus_on_Colombo_road.jpg",
      "subtitle":
          "Discover the most beautiful routes across the island in comfort."
    },
    {
      "image":
          "https://upload.wikimedia.org/wikipedia/commons/4/46/SLTB_inter-city_bus_%287568869668%29.jpg",
      "subtitle": "Seamless payments and real-time tracking for your journey."
    },
    {
      "image":
          "https://upload.wikimedia.org/wikipedia/commons/e/e6/SLTB_Kandy_South_Depot_Mercedes-Benz_OP312_Bus_-_II.jpg",
      "subtitle": "Experience premium travel with our top-rated bus operators."
    },
    {
      "image":
          "https://upload.wikimedia.org/wikipedia/commons/8/87/CTB_bus_no._290.JPG",
      "subtitle": "Smart Transit for a Smarter Sri Lanka."
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentImageIndex = Random().nextInt(_heroData.length);
    _startTimer();

    // Fetch dynamic cities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripController>(context, listen: false)
          .fetchAvailableCities();
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
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _heroData.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    // ... rest of build method untouched mostly, just Autocomplete below ...

    return SizedBox(
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 2),
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
          // Heavy Red Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.3),
                    AppTheme.primaryColor.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.9),
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
                        if (name.isEmpty) name = "Friend";

                        return Text(
                          "Hi, $name",
                          textAlign: TextAlign.center,
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
                        );
                      },
                    )
                  else
                    // Fallback if NOT logged in (User requested no "Traveler")
                    Text(
                      "Welcome",
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
                    "Book your bus tickets instantly with BusLink. Reliable, fast, and secure.",
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
  }

  // New "Card Style" Desktop Search
  Widget _buildDesktopSearchCard(bool isDark) {
    return Material(
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
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
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
                    "Bulk / Multi-day Booking",
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
                      hint: 'Where from?',
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
                      hint: 'Where to?',
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
                                "Departure",
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
                                  color: isDark ? Colors.white : Colors.black87,
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
                      onPressed: widget.onSearchTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 8, // More pop
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
                          const Text(
                            'SEARCH', // concise
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
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    // Use dynamic list or fallback
                    final cities = tripCtrl.availableCities.isNotEmpty
                        ? tripCtrl.availableCities
                        : kSriLankanCities;

                    return cities.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
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
                              return ListTile(
                                title: Text(option,
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
    return Material(
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
              label: 'From',
              hint: 'Origin City',
              focusNode: widget.originFocusNode,
              isLast: false,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSearchInput(
              controller: widget.destinationController,
              icon: Icons.navigation,
              label: 'To',
              hint: 'Destination City',
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
                        Text("Departure Date",
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onSearchTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                child: const Text("SEARCH BUSES",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return kSriLankanCities.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
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
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    option,
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
    return Center(
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
                        title: 'Fast Booking',
                        description:
                            'Book your seats in less than 60 seconds with our streamlined flow.',
                      ),
                    ),
                    Expanded(
                      child: _FeatureItem(
                        icon: Icons.shield_outlined,
                        title: 'Secure Payments',
                        description:
                            'Your transactions are protected with industry-standard encryption.',
                      ),
                    ),
                    Expanded(
                      child: _FeatureItem(
                        icon: Icons.location_on_outlined,
                        title: 'Live Tracking',
                        description:
                            'Track your bus in real-time and never miss your ride again.',
                      ),
                    ),
                    Expanded(
                      child: _FeatureItem(
                        icon: Icons.support_agent,
                        title: '24/7 Support',
                        description:
                            'Our dedicated team is always here to help with your journey.',
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

class _PopularDestinationsGrid extends StatelessWidget {
  final bool isDesktop;
  final List destinations; // Relaxed type

  const _PopularDestinationsGrid({
    required this.isDesktop,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lp.translate('popular_destinations'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 4 : 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.8,
                children: destinations.map((dest) {
                  return _DestinationCard(
                    city: dest['city'],
                    imageUrl: dest['image'],
                    busCount: dest['buses'],
                    description: dest['desc'],
                  );
                }).toList(),
              ),
            ],
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
                      widget.city,
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
                            widget.description,
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
