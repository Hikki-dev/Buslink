import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../layout/conductor_navbar.dart';
// import '../layout/app_footer.dart';
import '../admin/layout/admin_bottom_nav.dart';
import '../admin/admin_dashboard.dart';
import 'conductor_trip_management_screen.dart';
import '../booking/seat_selection_screen.dart';
import '../layout/custom_app_bar.dart';

class ConductorDashboard extends StatefulWidget {
  final bool isAdminView;
  const ConductorDashboard({super.key, this.isAdminView = false});

  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard> {
  int _selectedIndex = 0;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ticketIdController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<Trip> _todaysTrips = [];
  List<Trip> _filteredTrips = [];
  bool _loading = true;

  // --- NEW: My Trips State ---
  List<Trip> _myTrips = [];
  bool _loadingMyTrips = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTripsForDate(_selectedDate);
      _loadMyTrips();
    });
  }

  // --- NEW: Load My Trips ---
  Future<void> _loadMyTrips() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null || widget.isAdminView) {
      if (widget.isAdminView && mounted) {
        setState(() => _loadingMyTrips = false);
      }
      return;
    }

    setState(() => _loadingMyTrips = true);
    final controller = Provider.of<TripController>(context, listen: false);
    final trips = await controller.loadConductorTrips(user.uid);
    if (mounted) {
      setState(() {
        _myTrips = trips;
        _loadingMyTrips = false;
      });
    }
  }

  Future<void> _loadTripsForDate(DateTime date) async {
    setState(() => _loading = true);
    final controller = Provider.of<TripController>(context, listen: false);
    final trips = await controller.getTripsForDate(date);
    if (mounted) {
      setState(() {
        _todaysTrips = trips;
        _filteredTrips = trips;
        _loading = false;
        _filterTrips(); // Re-apply current text filters
      });
    }
  }

  void _filterTrips() {
    final from = _fromController.text.toLowerCase().trim();
    final to = _toController.text.toLowerCase().trim();

    setState(() {
      _filteredTrips = _todaysTrips.where((trip) {
        final matchFrom =
            from.isEmpty || trip.fromCity.toLowerCase().contains(from);
        final matchTo = to.isEmpty || trip.toCity.toLowerCase().contains(to);
        return matchFrom && matchTo;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now()
          .subtract(const Duration(days: 90)), // Allow past for history
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadTripsForDate(picked);
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _ticketIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final String conductorName =
        user?.displayName?.split(' ').first ?? 'Conductor';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          appBar: isDesktop
              ? null
              : CustomAppBar(
                  isAdminView: widget.isAdminView,
                  hideActions: false, // Show actions like theme/profile
                ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottomNavigationBar: !isDesktop
              ? widget.isAdminView
                  ? const AdminBottomNav(selectedIndex: 2)
                  : Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: NavigationBar(
                        backgroundColor: Theme.of(context).cardColor,
                        elevation: 0,
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (idx) =>
                            setState(() => _selectedIndex = idx),
                        destinations: const [
                          NavigationDestination(
                              icon: Icon(Icons.dashboard_outlined),
                              selectedIcon: Icon(Icons.dashboard),
                              label: 'Home'),
                          NavigationDestination(
                              icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
                          NavigationDestination(
                              icon: Icon(Icons.analytics_outlined),
                              selectedIcon: Icon(Icons.analytics),
                              label: 'Reports'),
                          NavigationDestination(
                              icon: Icon(Icons.person_outline),
                              selectedIcon: Icon(Icons.person),
                              label: 'Profile'),
                        ],
                      ),
                    )
              : null,
          body: Column(
            children: [
              if (isDesktop)
                ConductorNavBar(
                  selectedIndex: _selectedIndex,
                  onTap: (idx) => setState(() => _selectedIndex = idx),
                ),
              Expanded(
                child: _buildBody(isDesktop, conductorName),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isDesktop, String conductorName) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView(isDesktop, conductorName);
      case 1:
        return _buildScanTicketView();
      case 2:
        return _buildReportsView();
      case 3:
        return _buildProfileView(conductorName);
      default:
        return _buildDashboardView(isDesktop, conductorName);
    }
  }

  // --- VIEW 0: Dashboard (Existing) ---
  Widget _buildDashboardView(bool isDesktop, String conductorName) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Admin Preview Banner
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
                          // Force clean exit to root / Admin Dashboard
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminDashboard()),
                              (route) => false);
                        },
                        icon: const Icon(Icons.logout,
                            size: 18, color: Colors.black87),
                        label: const Text("Exit",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
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
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          vertical: isDesktop ? 48 : 24,
                          horizontal: isDesktop ? 40 : 24),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                              bottom: BorderSide(
                                  color: Theme.of(context).dividerColor))),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    child: const Icon(Icons.person,
                                        size: 30, color: AppTheme.primaryColor),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Welcome back, $conductorName!",
                                            style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: isDesktop ? 32 : 24,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface)),
                                        Text(
                                            "Here is your schedule for $_formattedDate.",
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Quick Stats
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                        label: "Scheduled Trips",
                                        value: "${_myTrips.length}",
                                        icon: Icons.directions_bus,
                                        color: Colors.blue),
                                  ),
                                  const SizedBox(width: 20),
                                  const Expanded(
                                    child: _StatCard(
                                        label: "Pending Issues",
                                        value: "0",
                                        icon: Icons.warning_amber,
                                        color: Colors.orange),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverAppBar(
                    backgroundColor: Theme.of(context).cardColor,
                    pinned: true,
                    primary: false,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 0,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: TabBar(
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primaryColor,
                        tabs: const [
                          Tab(text: "My Assigned Trips"),
                          Tab(text: "Search All Trips"),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildMyTripsTab(isDesktop),
                  _buildSearchTripsTab(isDesktop),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedDate => DateFormat('EEE, d MMM').format(_selectedDate);

  // --- VIEW 1: Scan Ticket ---
  // --- VIEW 1: Scan Ticket ---
  Widget _buildScanTicketView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20)
                  ]),
              child: const Icon(Icons.qr_code_scanner,
                  size: 64, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text("Scan Passenger Ticket",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Point camera at QR code or enter Ticket ID manually",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', color: Colors.grey)),
            const SizedBox(height: 32),

            // Manual Entry Field
            TextField(
              controller: _ticketIdController,
              decoration: InputDecoration(
                labelText: "Manual Ticket ID Entry",
                hintText: "Enter ID found on ticket",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "Camera permission required for Web Scanning")));
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera Scan"),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyTicket(_ticketIdController.text),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Verify ID"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _verifyTicket(String ticketId) async {
    if (ticketId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a Ticket ID")));
      return;
    }

    final controller = Provider.of<TripController>(context, listen: false);

    // Show scanning indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final Ticket? ticket = await controller.verifyTicket(ticketId.trim());

    // Close loading indicator
    if (mounted) Navigator.pop(context);

    if (ticket != null) {
      if (mounted) _showTicketDetailsDialog(ticket);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Invalid Ticket ID: $ticketId"),
            backgroundColor: Colors.red));
      }
    }
  }

  void _showTicketDetailsDialog(Ticket ticket) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.verified,
                        color: Colors.green, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text("Valid Ticket",
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ticketDetailRow("Passenger", ticket.passengerName),
                  _ticketDetailRow("Seats", ticket.seatNumbers.join(", ")),
                  _ticketDetailRow("Quantity", "${ticket.seatNumbers.length}"),
                  _ticketDetailRow(
                      "Bus No", ticket.tripData['busNumber'] ?? 'N/A'),
                  _ticketDetailRow(
                      "From", ticket.tripData['fromCity'] ?? 'N/A'),
                  _ticketDetailRow("To", ticket.tripData['toCity'] ?? 'N/A'),
                  _ticketDetailRow(
                      "Date",
                      _formatTripDate(ticket.tripData['departureTime']) ??
                          DateFormat('MMM d, yyyy').format(ticket.bookingTime)),
                  _ticketDetailRow("Price Paid",
                      "LKR ${ticket.totalAmount.toStringAsFixed(0)}"),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text("Approve Boarding"),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  String? _formatTripDate(dynamic dateData) {
    if (dateData == null) return null;
    try {
      // Handle Firestore Timestamp
      if (dateData is Timestamp) {
        return DateFormat('MMM d, yyyy').format(dateData.toDate());
      }
      // Handle String (ISO etc) if applicable, though usually Timestamp in our logic
      if (dateData is String) {
        // Try parse
        return DateFormat('MMM d, yyyy').format(DateTime.parse(dateData));
      }
    } catch (e) {
      debugPrint("Date parse error: $e");
    }
    return null;
  }

  Widget _ticketDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontFamily: 'Inter', color: Colors.grey.shade600)),
          if (label == "Seats") // Special high visibility for Seats
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 40, // HUGE
                    color: AppTheme.primaryColor))
          else
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- VIEW 2: Reports ---
  Widget _buildReportsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weekly Reports",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _reportStat("Total Trips", "12"),
                        _reportStat("On-Time Rate", "92%"),
                        _reportStat("Passengers", "450"),
                      ],
                    ),
                    const Divider(height: 48),
                    // Placeholder chart area
                    Container(
                      height: 200,
                      alignment: Alignment.center,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                      child: Text("Performance Chart Placeholder",
                          style: TextStyle(color: Colors.grey.shade400)),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontFamily: 'Inter', color: Colors.grey)),
      ],
    );
  }

  // --- VIEW 3: Profile ---
  Widget _buildProfileView(String name) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(name[0],
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ),
            const SizedBox(height: 24),
            Text(name,
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const Text("Senior Conductor",
                style: TextStyle(fontFamily: 'Inter', color: Colors.grey)),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Help & Support"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out", style: TextStyle(color: Colors.red)),
              onTap: () =>
                  Provider.of<AuthService>(context, listen: false).signOut(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => _filterTrips(),
          decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              hintText: "Enter City",
              hintStyle:
                  TextStyle(fontFamily: 'Inter', color: Colors.grey.shade400)),
        )
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DATE",
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(DateFormat('EEE, d MMM').format(_selectedDate),
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_drop_down, color: Colors.grey)
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 1: My Trips ---
  Widget _buildMyTripsTab(bool isDesktop) {
    if (_loadingMyTrips) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("No trips assigned to you yet.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Check back later or search for trips."),
            const SizedBox(height: 24),
            OutlinedButton(
                onPressed: _loadMyTrips, child: const Text("Refresh"))
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myTrips.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              return _buildTripCard(_myTrips[i], isDesktop, isMyTrip: true);
            },
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Search Trips ---
  Widget _buildSearchTripsTab(bool isDesktop) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Inputs
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Find Your Trip",
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10)
                          ]),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                    child: _buildInput("Current Location",
                                        _fromController, Icons.my_location)),
                                const SizedBox(width: 24),
                                Expanded(
                                    child: _buildInput("Destination",
                                        _toController, Icons.location_on)),
                                const SizedBox(width: 24),
                                _buildDateSelector(),
                                const SizedBox(width: 24),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _loadTripsForDate(_selectedDate),
                                  icon: const Icon(Icons.search),
                                  label: const Text("Search"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      fixedSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildInput("Current Location", _fromController,
                                    Icons.my_location),
                                const SizedBox(height: 16),
                                _buildInput("Destination", _toController,
                                    Icons.location_on),
                                const SizedBox(height: 16),
                                SizedBox(
                                    width: double.infinity,
                                    child: _buildDateSelector()),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _loadTripsForDate(_selectedDate),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    child: const Text("Search Trips",
                                        style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                )
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Trips List
          _buildTripsListSection(isDesktop),
        ],
      ),
    );
  }

  Widget _buildTripsListSection(bool isDesktop) {
    if (_loading) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_filteredTrips.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40.0),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle),
                child: Icon(Icons.event_busy,
                    size: 48, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 24),
              Text("No trips found for today.",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text("Try changing your search location or check back later.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Inter', color: Colors.grey.shade500)),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => _loadTripsForDate(_selectedDate),
                child: const Text("Refresh Schedule"),
              )
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Scheduled Trips (${_filteredTrips.length})",
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredTrips.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  final trip = _filteredTrips[i];
                  return _buildTripCard(trip, isDesktop);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip, bool isDesktop, {bool isMyTrip = false}) {
    final startTime = DateFormat('h.mm a').format(trip.departureTime);
    final endTime = DateFormat('h.mm a').format(trip.arrivalTime);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: isDesktop
          ? Row(
              children: [
                _tripInfo(startTime, endTime),
                Container(
                    height: 40,
                    width: 1,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(horizontal: 32)),
                _busInfo(trip),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: trip.status == TripStatus.delayed
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(trip.status.name.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: trip.status == TripStatus.delayed
                                  ? Colors.red
                                  : Colors.green)),
                    ),
                    const SizedBox(height: 8),
                    if (isMyTrip)
                      _buildStatusActions(trip)
                    else
                      _updateButton(trip),
                  ],
                )
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tripInfo(startTime, endTime),
                const SizedBox(height: 12),
                _busInfo(trip),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                // Action Buttons moved to bottom
                if (isMyTrip)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildStatusActions(trip),
                  )
                else
                  _updateButton(trip),
              ],
            ),
    );
  }

  Widget _tripInfo(String start, String end) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$start - $end",
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 20)),
      ],
    );
  }

  Widget _busInfo(Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${trip.fromCity} ➔ ${trip.toCity}",
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16)),
        const SizedBox(height: 4),
        Text(
            "Bus: ${trip.busNumber} • T${trip.id.substring(0, 4).toUpperCase()}",
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _updateButton(Trip trip) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ElevatedButton.icon(
            onPressed: () {
              final controller =
                  Provider.of<TripController>(context, listen: false);
              controller
                  .selectTrip(trip); // Ensure trip is selected in controller
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SeatSelectionScreen(
                          trip: trip, isConductorMode: true)));
            },
            icon: const Icon(Icons.confirmation_number, size: 16),
            label: const Text("Sell Ticket", // Restored full label
                overflow: TextOverflow.ellipsis),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ConductorTripManagementScreen(trip: trip)))
                  .then((_) => _loadTripsForDate(_selectedDate));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            child: const Text("Update",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusActions(Trip trip) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniStatusButton(
            trip, TripStatus.departed, Icons.departure_board, Colors.green),
        const SizedBox(width: 8),
        _miniStatusButton(
            trip, TripStatus.onWay, Icons.directions_bus_filled, Colors.blue),
        const SizedBox(width: 8),
        _miniStatusButton(
            trip, TripStatus.arrived, Icons.check_circle, Colors.purple),
        const SizedBox(width: 8),
        _miniStatusButton(trip, TripStatus.delayed, Icons.warning, Colors.red,
            isDelay: true),
      ],
    );
  }

  Widget _miniStatusButton(
      Trip trip, TripStatus status, IconData icon, Color color,
      {bool isDelay = false}) {
    return IconButton(
      onPressed: () async {
        final controller = Provider.of<TripController>(context, listen: false);
        if (isDelay) {
          await controller.updateTripStatus(trip.id, status);
        } else {
          await controller.updateTripStatus(trip.id, status);
        }
        // Refresh
        _loadTripsForDate(_selectedDate);
        _loadMyTrips();
      },
      icon: Icon(icon),
      color: color,
      tooltip: status.name.toUpperCase(),
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 150, // Removed fixed width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  // Dark Mode: White & Bold | Light Mode: Black & Bold
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87)),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight
                      .bold, // Requested bold for dark, implied for consistency
                  // Dark Mode: White | Light Mode: Grey/Black
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey.shade700)),
        ],
      ),
    );
  }
}
