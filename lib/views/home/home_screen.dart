// lib/views/home/home_screen.dart
import 'dart:async';
import 'package:buslink/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import '../../models/trip_view_model.dart';

import 'package:provider/provider.dart';
import 'package:buslink/services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
//  // Removed
import 'bulk_calendar_dialog.dart';
import '../results/bus_list_screen.dart';
import 'widgets/ongoing_trip_card.dart';
// import 'widgets/favorites_section.dart'; // Removed
import '../widgets/language_selector.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';
import '../layout/notifications_screen.dart';
import '../tracking/track_bus_screen.dart'; // Added
import 'widgets/news_carousel.dart';
import 'home_hero.dart';
import 'home_sections.dart';
import '../widgets/animated_favorite_button.dart';

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
  bool _isBulkBooking = false;
  List<DateTime> _bulkDates = [];

  @override
  void initState() {
    super.initState();
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
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.enterOriginDestination)),
      );
      return;
    }

    // Round Trip Validation REMOVED as per request to remove feature
    // if (_isRoundTrip && _selectedReturnDate == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //         content: Text('Please select a Return Date for Round Trip booking.')), // Professional Error
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
          } else if (_isBulkBooking) {
            // Fallback for "0 Days" issue if picker returns empty but we want at least one day
            _bulkDates = [_selectedDate];
          }
        });

        // Sync with Controller
        Provider.of<TripController>(context, listen: false).bulkDates =
            _bulkDates;

        // Update Controller Seats (Synced)
        if (result['SEATS'] != null) {
          final int pCount = result['SEATS'] as int;
          Provider.of<TripController>(context, listen: false)
              .setBulkPassengers(pCount);
          // Also set isBulkBooking true if not already
          if (!_isBulkBooking) setState(() => _isBulkBooking = true);
        }
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

  void _pickJourney(String city) {
    _originController.text = 'Colombo';
    _destinationController.text = city;
    _searchBuses();
  }

  Widget _phoneActions(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    Widget circle(String tip, IconData icon, VoidCallback onTap) => Semantics(
          button: true,
          label: tip,
          child: Tooltip(
            message: tip,
            child: Material(
              color: Colors.white.withValues(alpha: 0.2),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(icon, color: Colors.white, size: 24)),
              ),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user != null) ...[
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snap) {
              final unread = snap.data?.docs.length ?? 0;
              return Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: circle(
                    unread > 0 ? 'Notifications, $unread new' : 'Notifications',
                    Icons.notifications_none_rounded,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()))),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        circle('Change language', Icons.language,
            () => LanguageSelector.showLanguageDialog(context)),
        const SizedBox(width: 8),
        if (user != null)
          circle('Log out', Icons.logout, () async {
            await Provider.of<AuthService>(context, listen: false).signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (r) => false);
            }
          })
        else
          circle('Log in', Icons.login,
              () => Navigator.pushNamed(context, '/login')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Material(
      type: MaterialType.transparency,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: widget.isAdminView,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (isDesktop)
              SliverToBoxAdapter(
                  child: DesktopNavBar(
                      selectedIndex: 0, isAdminView: widget.isAdminView)),
            SliverToBoxAdapter(
              child: HomeHero(
                isDesktop: isDesktop,
                isAdminView: widget.isAdminView,
                originController: _originController,
                destinationController: _destinationController,
                originFocusNode: _originFocusNode,
                destinationFocusNode: _destinationFocusNode,
                selectedDate: _selectedDate,
                onDateTap: _selectDate,
                onSearchTap: _searchBuses,
                isBulkBooking: _isBulkBooking,
                bulkDatesCount: _bulkDates.length,
                onBulkBookingChanged: (v) => setState(() => _isBulkBooking = v),
                phoneActions: isDesktop ? null : _phoneActions(context),
              ),
            ),
            // Signed-in travellers: their trips and favourites.
            SliverToBoxAdapter(
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null || widget.isAdminView) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildDashboardSection(context, user, isDesktop),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: isDesktop ? 0 : 8),
                child:
                    PopularJourneys(isDesktop: isDesktop, onPick: _pickJourney),
              ),
            ),
            if (isDesktop) const SliverToBoxAdapter(child: HowItWorks()),
            const NewsCarousel(),
            SliverToBoxAdapter(child: SizedBox(height: isDesktop ? 64 : 24)),
            if (isDesktop) const SliverToBoxAdapter(child: AppFooter()),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection(
      BuildContext context, User user, bool isDesktop) {
    return Column(
      children: [
        // Favorites Section
        StreamBuilder<List<Map<String, dynamic>>>(
            stream: Provider.of<FirestoreService>(context, listen: false)
                .getUserFavoriteRoutes(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildFavoritesSection(context, snapshot.data!, isDesktop);
            }),

        const SizedBox(height: 24),

        // Ongoing/History Trips
        StreamBuilder<List<Ticket>>(
          stream: Provider.of<FirestoreService>(context, listen: false)
              .getUserTickets(user.uid),
          builder: (context, ticketSnap) {
            if (!ticketSnap.hasData || ticketSnap.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final tickets = ticketSnap.data!;
            // Filter logic if needed, but Carousel handles it roughly.
            return _TripsCarouselWidget(
                tickets: tickets,
                favoritesWidget: const SizedBox.shrink(),
                isDesktop: isDesktop);
          },
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(BuildContext context,
      List<Map<String, dynamic>> favorites, bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 0 : 24, vertical: 16),
              child: Text(AppLocalizations.of(context)!.yourFavorites,
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            SizedBox(
              height: 150, // Height for the card (Squashed)
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 24),
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final fav = favorites[index];
                  return _HomeFavoriteCard(
                    from: fav['fromCity'] ?? '',
                    to: fav['toCity'] ?? '',
                    operator: fav['operatorName'] ?? 'Standard',
                    onTap: () {
                      // Populate Search
                      setState(() {
                        _originController.text = fav['fromCity'] ?? '';
                        _destinationController.text = fav['toCity'] ?? '';
                      });
                      // Scroll to top to show search fields
                      _scrollController.animateTo(0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut);
                    },
                    onRemove: () async {
                      if (fav['id'] != null) {
                        await Provider.of<TripController>(context,
                                listen: false)
                            .removeFavorite(fav['id']);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFavoriteCard extends StatelessWidget {
  final String from;
  final String to;
  final String operator;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HomeFavoriteCard({
    required this.from,
    required this.to,
    required this.operator,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220, // Reduced width
        padding: const EdgeInsets.all(12), // Reduced padding
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2225) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                AnimatedFavoriteButton(
                  isFavorite: true,
                  size: 16,
                  onToggle: onRemove,
                ),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded,
                    size: 16, color: Colors.grey),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(from,
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child:
                      Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                ),
                Text(to,
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.tapToQuickBook,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
          ],
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
              // 1. Explicit Status Check
              // User request: Hide 'arrived' trips (Completed)
              if (t.status == 'completed' ||
                  t.status == 'cancelled' ||
                  t.status.toLowerCase() == 'arrived') {
                return false;
              }

              // 2. SAFETY NET: Stale Trip Check
              if (DateTime.now().difference(t.arrivalTime).inHours > 18) {
                return false;
              }

              // 3. Non-Active Past Check
              final s = t.status.toLowerCase();
              bool isActive = s == 'boarding' ||
                  s == 'departed' ||
                  s == 'onway' ||
                  s == 'on way'; // Removed 'arrived' from active check

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

            // Check for Live Trip (Active Status)
            EnrichedTrip? liveTrip;
            try {
              liveTrip = ongoingTrips.firstWhere((t) {
                final s = t.status.toLowerCase();
                return s == 'boarding' ||
                    s == 'departed' ||
                    s ==
                        'onway' || // onWay might be onway or onWay, toLowerCase makes it onway
                    s == 'on way' ||
                    s == 'arrived';
              });
            } catch (_) {}

            return Column(
              children: [
                if (liveTrip != null)
                  LiveJourneyCard(
                    trip: liveTrip,
                    onTap: () {
                      // final ticket = widget.tickets
                      //    .firstWhere((t) => t.tripId == liveTrip!.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrackBusScreen(
                            trip: liveTrip!.trip, // Use inner trip object
                          ),
                        ),
                      );
                    },
                  ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 390,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: ongoingTrips.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, index) {
                          final ticket = widget.tickets.firstWhere(
                              (tk) => tk.tripId == ongoingTrips[index].id,
                              orElse: () => widget.tickets[0]); // Fallback

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
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
                )
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
    final s = status.toLowerCase();
    if (s == 'departed' || s == 'onway' || s == 'on way' || s == 'boarding') {
      return 0;
    }
    // 1 = Scheduled / On Time
    if (s == 'scheduled' || s == 'ontime' || s == 'on time' || s == 'delayed') {
      return 1;
    }
    // 2 = Arrived (Lowest priority for upcoming view)
    if (s == 'arrived') {
      return 2;
    }
    // 3 = Others (should be filtered out anyway)
    return 3;
  }
}

class LiveJourneyCard extends StatelessWidget {
  final EnrichedTrip trip;
  final VoidCallback onTap;

  const LiveJourneyCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
//
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
                : [const Color(0xFF2563EB), const Color(0xFF60A5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          color: Colors.greenAccent, size: 10),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.liveJourney,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  trip.busNumber,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.yourBusIsHere,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${trip.originCity} ➔ ${trip.destinationCity}",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.trackNow.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
