// lib/views/home/home_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../data/cities.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:buslink/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/language_provider.dart';
import '../results/bus_list_screen.dart';
import 'widgets/ongoing_trip_card.dart';
import 'widgets/favorites_section.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';

// Mock Data for Popular Destinatinos
final List<Map<String, dynamic>> _allDestinations = [
  {
    'city': 'Colombo',
    'image': 'https://loremflickr.com/800/600/colombo,srilanka',
    'buses': 45,
    'desc': 'Discover the vibrant Tamil culture and northern cuisine.'
  },
  {
    'city': 'Kandy',
    'image': 'https://loremflickr.com/800/600/kandy,temple',
    'buses': 32,
    'desc': 'Visit the Temple of the Tooth and scenic lake.'
  },
  {
    'city': 'Galle',
    'image': 'https://loremflickr.com/800/600/galle,fort',
    'buses': 64,
    'desc': 'Explore the historic Dutch Fort and beaches.'
  },
  {
    'city': 'Ella',
    'image': 'https://loremflickr.com/800/600/ella,srilanka',
    'buses': 18,
    'desc': 'Hiking trails, waterfalls and the Nine Arch Bridge.'
  },
  {
    'city': 'Nuwara Eliya',
    'image': 'https://loremflickr.com/800/600/nuwaraeliya,tea',
    'buses': 24,
    'desc': 'Little England of Sri Lanka with cool climate.'
  },
  {
    'city': 'Sigiriya',
    'image': 'https://loremflickr.com/800/600/sigiriya,rock',
    'buses': 25,
    'desc': 'The ancient rock fortress and palace ruins.'
  },
  {
    'city': 'Jaffna',
    'image': 'https://loremflickr.com/800/600/jaffna,temple',
    'buses': 20,
    'desc': 'Rich history and unique northern culture.'
  },
  {
    'city': 'Trincomalee',
    'image': 'https://loremflickr.com/800/600/trincomalee,beach',
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
  DateTime? _selectedReturnDate; // NEW: Return Date State

  List<Map<String, dynamic>> _currentDestinations = [];

  @override
  void initState() {
    super.initState();
    // Shuffle and pick 4
    var list = List<Map<String, dynamic>>.from(_allDestinations);
    list.shuffle();
    _currentDestinations = list.take(4).toList();
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

    // NEW: Round Trip Validation
    if (_isRoundTrip && _selectedReturnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select a Return Date for Round Trip booking.')), // Professional Error
      );
      return;
    }

    final tripController = Provider.of<TripController>(context, listen: false);
    tripController.setFromCity(_originController.text);
    tripController.setToCity(_destinationController.text);
    tripController.setDate(_selectedDate);
    tripController.setRoundTrip(_isRoundTrip);
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

  Future<void> _selectDate(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    // For Desktop, we still might want the scaffold if it's running standalone?
    // But now proper entry is CustomerMainScreen.
    // If isDesktop is true, we might want to return just the content.
    // The previous Scaffold had 'extendBodyBehindAppBar: true'.

    // If we just return the CustomScrollView, it needs a Material/Scaffold ancestor for some widgets?
    // CustomerMainScreen provides Scaffold.

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (isDesktop)
                const SliverToBoxAdapter(
                    child: DesktopNavBar(selectedIndex: 0)),
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
                  onReturnDateChanged: (val) =>
                      setState(() => _selectedReturnDate = val),
                  onRoundTripChanged: (val) =>
                      setState(() => _isRoundTrip = val),
                  onBulkBookingChanged: (val) =>
                      setState(() => _isBulkBooking = val),
                ),
              ),
              // --- ONGOING TRIPS & FAVORITES SECTION ---
              StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user == null) return const SliverToBoxAdapter();

                    return SliverToBoxAdapter(
                      child: _buildDashboardSection(context, user, isDesktop),
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
      ],
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
            Ticket? activeTicket;
            if (ticketSnap.hasData && ticketSnap.data!.isNotEmpty) {
              final tickets = ticketSnap.data!
                  .where((t) => t.status != 'cancelled')
                  .toList();
              if (tickets.isNotEmpty) {
                activeTicket = tickets.last;
              }
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: Provider.of<FirestoreService>(context, listen: false)
                  .getUserFavorites(user.uid),
              builder: (context, favSnap) {
                final favorites = favSnap.data ?? [];

                final favoritesWidget = FavoritesSection(
                  favorites: favorites, // Pass list (empty or not)
                  onTap: (fav) {
                    setState(() {
                      _originController.text = fav['fromCity'];
                      _destinationController.text = fav['toCity'];
                      _searchBuses();
                    });
                  },
                );

                if (activeTicket == null) {
                  return favoritesWidget;
                }

                return StreamBuilder<Trip>(
                  stream: Provider.of<FirestoreService>(context, listen: false)
                      .getTripStream(activeTicket.tripId),
                  builder: (context, tripSnap) {
                    if (!tripSnap.hasData) {
                      return favoritesWidget;
                    }

                    final tripWidget = OngoingTripCard(
                      trip: tripSnap.data!,
                      seatCount: activeTicket!.seatNumbers.length,
                      paidAmount: activeTicket.totalAmount,
                    );

                    // Wrap contents
                    // Note: ActiveTicketCard & FavoritesSection might already have containers.
                    // If they do, we shouldn't double wrap.
                    // Checking code: ActiveTicketCard usually has its own style.
                    // User said "properly put like why is it stretched... make it somewhat similar to the search bar".
                    // The screenshots show they are full width black blocks.
                    // I will wrap them in a constrained box to avoid "stretch" on desktop, but fill on mobile.

                    // Since TripWidget and FavoritesWidget are instances of `ActiveTicketCard` and `FavoritesSection`
                    // I'll wrap them here.

                    if (isDesktop) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                favoritesWidget,
                                const SizedBox(height: 24),
                                tripWidget,
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            favoritesWidget,
                            const SizedBox(height: 16),
                            tripWidget,
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ],
    );
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
  // NEW: Return Date Fields
  final DateTime? selectedReturnDate;
  final ValueChanged<DateTime> onReturnDateChanged;
  final ValueChanged<bool> onRoundTripChanged;
  final ValueChanged<bool> onBulkBookingChanged;

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
    required this.selectedReturnDate,
    required this.onReturnDateChanged,
    required this.onRoundTripChanged,
    required this.onBulkBookingChanged,
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
          "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80&w=1280",
      "subtitle":
          "Book your bus tickets instantly with BusLink. Reliable, fast, and secure."
    },
    {
      "image":
          "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?auto=format&fit=crop&q=80&w=1280",
      "subtitle":
          "Discover the most beautiful routes across the island in comfort."
    },
    {
      "image":
          "https://images.unsplash.com/photo-1561361513-2d000a50f0dc?auto=format&fit=crop&q=80&w=1280",
      "subtitle": "Seamless payments and real-time tracking for your journey."
    },
    {
      "image":
          "https://images.unsplash.com/photo-1557223562-6c77ef16210f?auto=format&fit=crop&q=80&w=1280",
      "subtitle": "Experience premium travel with our top-rated bus operators."
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentImageIndex = Random().nextInt(_heroData.length);
    _startTimer();
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
                  top: widget.isDesktop ? 100 : 120,
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
    return Container(
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
          // 1. Tabs View
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // Left aligned tabs
              children: [
                _buildTabItem("One Way", !widget.isRoundTrip,
                    () => widget.onRoundTripChanged(false)),
                const SizedBox(width: 32),
                _buildTabItem("Round Trip", widget.isRoundTrip,
                    () => widget.onRoundTripChanged(true)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

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
            padding:
                const EdgeInsets.only(left: 40, right: 20, top: 24, bottom: 24),
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
                // RETURN DATE (Only if Round Trip)
                if (widget.isRoundTrip) ...[
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: widget.selectedReturnDate ??
                              widget.selectedDate.add(const Duration(days: 1)),
                          firstDate: widget.selectedDate,
                          lastDate: DateTime(2026),
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
                        if (picked != null) {
                          widget.onReturnDateChanged(picked);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.event_repeat,
                              color: AppTheme.primaryColor, size: 22),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Return",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                widget.selectedReturnDate != null
                                    ? DateFormat('EEE, d MMM')
                                        .format(widget.selectedReturnDate!)
                                    : "Select Date",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: widget.selectedReturnDate != null
                                      ? Colors.black87
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // More rounded
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
    );
  }

  Widget _buildTabItem(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade500,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

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
              RawAutocomplete<String>(
                textEditingController: controller,
                focusNode: focusNode,
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
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87)),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSearch(bool isDark) {
    return Container(
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
          Row(
            children: [
              Expanded(
                child: buildTabButton("One Way", !widget.isRoundTrip,
                    () => widget.onRoundTripChanged(false), isDark),
              ),
              const SizedBox(width: 12), // Added Spacing
              Expanded(
                child: buildTabButton("Round Trip", widget.isRoundTrip,
                    () => widget.onRoundTripChanged(true), isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: widget.isBulkBooking,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => widget.onBulkBookingChanged(v!),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("Bulk / Multi-day Booking",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchInput(
            controller: widget.originController,
            icon: Icons.location_on,
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
                          DateFormat('EEE, d MMMM').format(widget.selectedDate),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabButton(
      String text, bool isActive, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor
              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white38 : Colors.black38),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

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
                        contentPadding: EdgeInsets.zero,
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
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87),
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
