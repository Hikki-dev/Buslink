// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/trip_controller.dart';
import '../../services/auth_service.dart';
import '../results/bus_list_screen.dart';
import '../../utils/app_theme.dart';
import '../booking/my_trips_screen.dart';
import '../favorites/favorites_screen.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdminView;
  const HomeScreen({super.key, this.isAdminView = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Define screens for navigation
    final List<Widget> pages = [
      _HomeContent(isAdminView: widget.isAdminView),
      const MyTripsScreen(showBackButton: false),
      const FavoritesScreen(showBackButton: false),
      const ProfileScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Column(
              children: [
                if (widget.isAdminView)
                  Container(
                    width: double.infinity,
                    color: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text("Welcome Admin - Preview Mode",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                DesktopNavBar(
                  selectedIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
                // Footer only on Home page technically, or everywhere?
                // Since pages[0] has scrollview with footer, we are good.
              ],
            ),
          );
        } else {
          // Mobile View: Bottom Navigation
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              top: false,
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home'),
                  NavigationDestination(
                      icon: Icon(Icons.directions_bus_outlined),
                      selectedIcon: Icon(Icons.directions_bus_filled),
                      label: 'Trips'),
                  NavigationDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite),
                      label: 'Favs'),
                  NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile'),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

// --- Component: Home Content ---
class _HomeContent extends StatelessWidget {
  final bool isAdminView;
  const _HomeContent({this.isAdminView = false});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner for Mobile
          if (isAdminView && !isDesktop)
            Container(
              width: double.infinity,
              color: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text("Welcome Admin - Preview Mode",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
            ),

          _HeroSection(isDesktop: isDesktop),
          Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                      title: "Your Favourites",
                      subtitle: "Quick access to your regular routes"),
                  const SizedBox(height: 20),
                  _FavoritesList(isDesktop: isDesktop),
                  const SizedBox(height: 60),
                  const _SectionHeader(
                      title: "Upcoming Trip", subtitle: "Don't miss your bus!"),
                  const SizedBox(height: 20),
// --- REVISED: Search Card with Autocomplete ---
                  const _CurrentTripStatusCard(),

                  const SizedBox(height: 60),
                  const _SectionHeader(
                      title: "Popular Destinations",
                      subtitle: "Explore the most travelled cities"),
                  const SizedBox(height: 24),
                  _PopularDestinationsGrid(isDesktop: isDesktop),
                  const SizedBox(height: 60),
                  if (isDesktop) ...[
                    const _FeaturesSection(),
                    const SizedBox(height: 60),
                  ]
                ],
              ),
            ),
          )),
          if (isDesktop) const AppFooter(),
          if (!isDesktop) const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// --- Hero Section ---
class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  const _HeroSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final String greeting = user != null
        ? "Hi ${user.displayName?.split(' ').first ?? user.email?.split('@').first ?? 'Traveler'}"
        : "Travel with Comfort & Style";

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: isDesktop ? 600 : 500,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
              "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900.withValues(alpha: 0.3),
              Colors.red.shade900.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: isDesktop ? 48 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      height: 20), // Top spacing for navbar overlap if any
                  Text(greeting,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: isDesktop ? 56 : 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1)),
                  /* const SizedBox(height: 16), is handled by the next lines usually */
                  const SizedBox(height: 16),
                  Text(
                      "Book your bus tickets instantly with BusLink. Reliable, fast, and secure.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: isDesktop ? 18 : 16,
                          color: Colors.white.withValues(alpha: 0.9))),
                  SizedBox(height: isDesktop ? 48 : 32),
                  const _SearchCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- NEW: Current Trip Dashboard Card ---
class _CurrentTripStatusCard extends StatelessWidget {
  const _CurrentTripStatusCard();

  @override
  Widget build(BuildContext context) {
    final authSubject = Provider.of<AuthService>(context);
    final controller = Provider.of<TripController>(context);
    final user = authSubject.currentUser;

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: Text("Sign in to see your active trip")),
      );
    }

    return StreamBuilder<dynamic>(
      // Using dynamic to avoid circular dep check issues, practically Ticket
      stream: controller.getCurrentActiveTicket(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_bus_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No active trips right now",
                    style: GoogleFonts.inter(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        final ticket = snapshot.data!; // This is a Ticket model
        final tripData = ticket.tripData;

        // Extract Data
        final fromCity = tripData['fromCity'] ?? "Unknown";
        final toCity = tripData['toCity'] ?? "Unknown";
        final opName = tripData['operatorName'] ?? "Bus Operator";
        final price = ticket.totalAmount;
        final seats = ticket.seatNumbers.join(", ");
        final status = tripData['status'] ?? 'scheduled';

        return Column(
          children: [
            // 1. Connection Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opName,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("Bus No: ${tripData['busNumber'] ?? 'N/A'}",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text("Active",
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ORIGIN",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(fromCity,
                              style: GoogleFonts.outfit(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Icon(Icons.arrow_right_alt,
                          size: 30, color: Colors.grey.shade300),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("DESTINATION",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(toCity,
                              style: GoogleFonts.outfit(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SEATS",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade400)),
                          Text(seats,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("PRICE PAID",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade400)),
                          Text("LKR ${price.toStringAsFixed(0)}",
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 2. Status Indicators
            Row(
              children: [
                _statusIndicator(
                    "Departed",
                    status == "departed" ||
                        status == "onWay" ||
                        status == "arrived"),
                const SizedBox(width: 8),
                _statusIndicator(
                    "On Way",
                    status == "onWay" ||
                        status == "arrived"), // Simplified logic
                const SizedBox(width: 8),
                _statusIndicator("Arrived", status == "arrived"),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _statusIndicator(String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? Colors.green.shade200 : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.circle,
                size: 10,
                color: isActive ? Colors.green : Colors.grey.shade400),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green.shade700 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- Search Card with Tabs ---
class _SearchCard extends StatefulWidget {
  const _SearchCard();

  @override
  State<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<_SearchCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  // Demo Data (Same as existing logic)
  final List<String> cities = [
    "Colombo",
    "Kandy",
    "Galle",
    "Jaffna",
    "Matara",
    "Ella",
    "Trincomalee",
    "Anuradhapura"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _selectDate(BuildContext context, TripController controller) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
            ),
            child: child!,
          );
        });
    if (picked != null) {
      controller.setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Pre-fill controllers if data exists in controller
    if (controller.fromCity != null &&
        _fromController.text != controller.fromCity) {
      _fromController.text = controller.fromCity!;
    }
    if (controller.toCity != null && _toController.text != controller.toCity) {
      _toController.text = controller.toCity!;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 20))
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tabs
            Container(
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "One Way"),
                    Tab(text: "Round Trip"),
                  ]),
            ),

            Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: Column(
                children: [
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                            child: _buildLocationInput(
                                context,
                                "Where you are now",
                                _fromController,
                                cities,
                                (v) => controller.setFromCity(v),
                                Icons.my_location)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Icon(Icons.arrow_forward,
                              color: Colors.grey.shade300),
                        ),
                        Expanded(
                            child: _buildLocationInput(
                                context,
                                "Where you will be going",
                                _toController,
                                cities,
                                (v) => controller.setToCity(v),
                                Icons.location_on)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildDateField(context, controller)),
                        const SizedBox(width: 24),
                        _buildSearchButton(context, controller),
                      ],
                    )
                  else ...[
                    _buildLocationInput(
                        context,
                        "Where you are now",
                        _fromController,
                        cities,
                        (v) => controller.setFromCity(v),
                        Icons.my_location),
                    const SizedBox(height: 16),
                    Center(
                        child:
                            Icon(Icons.swap_vert, color: Colors.grey.shade300)),
                    const SizedBox(height: 16),
                    _buildLocationInput(
                        context,
                        "Where you will be going",
                        _toController,
                        cities,
                        (v) => controller.setToCity(v),
                        Icons.location_on),
                    const SizedBox(height: 24),
                    _buildDateField(context, controller),
                    const SizedBox(height: 32),
                    SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: _buildSearchButton(context, controller)),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput(
      BuildContext context,
      String hint,
      TextEditingController textController,
      List<String> options,
      Function(String) onSelected,
      IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* Text(label.toUpperCase(), style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
        const SizedBox(height: 10), */
        // Removed label to match "Where you are now" placeholder style more closely or keep it clean
        // The user request said: Input 1 placeholder: "Where you are now", no dropdown.

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return options.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: onSelected,
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    // Sync internal controller if needed, but Autocomplete manages its own unless passed
                    // We need to keep our state controller in sync.
                    if (textController.text !=
                            fieldTextEditingController.text &&
                        fieldTextEditingController.text.isNotEmpty) {
                      // Logic to prevent loops, simplified here
                    }

                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.normal),
                      ),
                      onChanged: (val) {
                        // Also update parent controller if user types manually
                        onSelected(val);
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 300, // Or dynamic
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
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
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDateField(BuildContext context, TripController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* Text("DEPARTURE DATE", style: GoogleFonts.inter(...) ), const SizedBox(height: 10), */
        InkWell(
          onTap: () => _selectDate(context, controller),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  controller.travelDate != null
                      ? DateFormat('EEE, d MMM yyyy')
                          .format(controller.travelDate!)
                      : "Select Date",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: controller.travelDate != null
                          ? Colors.black
                          : Colors.grey.shade400),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSearchButton(BuildContext context, TripController controller) {
    return ElevatedButton(
      onPressed: () {
        if (controller.fromCity == null ||
            controller.toCity == null ||
            controller.travelDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please fill all fields")));
          return;
        }
        controller.searchTrips(context);
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const BusListScreen()));
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22)),
      child: Text("SEARCH BUSES",
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 14,
              color: Colors.white)),
    );
  }
}
// --- Features & Favorites reused but minimized here for brevity or import ---
// I'll inline the list widgets for simplicity as I rewrote them before,
// but ensure they use Theme.of(context) dynamically for Dark Mode.

class _FavoritesList extends StatelessWidget {
  final bool isDesktop;
  const _FavoritesList({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final controller = Provider.of<TripController>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "Log in to view favorites",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: controller.getUserFavorites(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No favorites added yet",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            );
          }

          final favorites = snapshot.data!;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return _favCard(
                context,
                fav['fromCity'] ?? 'Unknown',
                fav['toCity'] ?? 'Unknown',
              );
            },
          );
        },
      ),
    );
  }

  Widget _favCard(BuildContext context, String from, String to) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text("$from - $to",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Daily Service",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PopularDestinationsGrid extends StatelessWidget {
  final bool isDesktop;
  const _PopularDestinationsGrid({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {
        "name": "Kandy",
        "image": "https://loremflickr.com/640/480/kandy,temple",
        "desc":
            "The hill capital, home to the Temple of the Tooth and scenic lakes."
      },
      {
        "name": "Galle",
        "image": "https://loremflickr.com/640/480/galle,fort",
        "desc":
            "Historic fort city on the southwest coast with Dutch colonial architecture."
      },
      {
        "name": "Ella",
        "image": "https://loremflickr.com/640/480/ella,srilanka",
        "desc":
            "Mountain village famous for the Nine Arch Bridge and stunning hiking trails."
      },
      {
        "name": "Jaffna",
        "image": "https://loremflickr.com/640/480/jaffna,temple",
        "desc":
            "Cultural hub of the north, known for its vibrant Hindu temples and history."
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // Adjust aspect ratio for card content
          crossAxisCount: isDesktop
              ? 4
              : 1, // Single column on mobile for better visibility
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isDesktop ? 0.8 : 1.5), // Wider cards on mobile
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final dest = destinations[index];
        return _DestinationCard(
          name: dest['name']!,
          imageUrl: dest['image']!,
          description: dest['desc']!,
        );
      },
    );
  }
}

class _DestinationCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String description;

  const _DestinationCard({
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl),
            fit: BoxFit.cover,
            colorFilter: _isHovered
                ? ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.6), BlendMode.darken)
                : ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3), BlendMode.darken),
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    widget.description,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                crossFadeState: _isHovered
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(children: [
          Icon(Icons.security, size: 40),
          SizedBox(height: 10),
          Text("Secure")
        ]),
        Column(children: [
          Icon(Icons.timer, size: 40),
          SizedBox(height: 10),
          Text("Fast")
        ]),
        Column(children: [
          Icon(Icons.headset_mic, size: 40),
          SizedBox(height: 10),
          Text("Support")
        ]),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(subtitle,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
        Container(
            width: 50,
            height: 4,
            color: AppTheme.primaryColor,
            margin: const EdgeInsets.only(top: 8)),
      ],
    );
  }
}
