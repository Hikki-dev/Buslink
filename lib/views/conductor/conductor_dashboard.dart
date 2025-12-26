import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../layout/conductor_navbar.dart';
import '../layout/app_footer.dart';
import 'conductor_trip_management_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTripsForDate(_selectedDate);
    });
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
          backgroundColor: Colors.grey.shade50,
          bottomNavigationBar: !isDesktop
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.white,
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Header (Always Visible)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 48 : 32, horizontal: isDesktop ? 40 : 24),
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black12))),
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
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Icon(Icons.person,
                              size: 30, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome back, $conductorName!",
                                style: GoogleFonts.outfit(
                                    fontSize: isDesktop ? 32 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            Text("Here is your schedule for $_formattedDate.",
                                style: GoogleFonts.inter(
                                    color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Quick Stats
                    Row(
                      children: [
                        _StatCard(
                            label: "Scheduled Trips",
                            value: "${_todaysTrips.length}",
                            icon: Icons.directions_bus,
                            color: Colors.blue),
                        const SizedBox(width: 20),
                        const _StatCard(
                            label: "Pending Issues",
                            value: "0",
                            icon: Icons.warning_amber,
                            color: Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Search & Filter Section
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Find Your Trip",
                        style: GoogleFonts.outfit(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Trips List
          _buildTripsListSection(isDesktop),

          if (isDesktop) const AppFooter(),
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
                  color: Colors.white,
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
            Text("Scan Passenger Ticket",
                style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Point camera at QR code or enter Ticket ID manually",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey)),
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
                  Text("Valid Ticket",
                      style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ticketDetailRow("Passenger", ticket.passengerName),
                  _ticketDetailRow("Seats", ticket.seatNumbers.join(", ")),
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
          Text(label, style: GoogleFonts.inter(color: Colors.grey.shade600)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
              Text("Weekly Reports",
                  style: GoogleFonts.outfit(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
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
                      color: Colors.grey.shade50,
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
            style:
                GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(color: Colors.grey)),
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
            color: Colors.white,
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
                  style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ),
            const SizedBox(height: 24),
            Text(name,
                style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Senior Conductor",
                style: GoogleFonts.inter(color: Colors.grey)),
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
            style: GoogleFonts.inter(
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
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              hintText: "Enter City",
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400)),
        )
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DATE",
            style: GoogleFonts.inter(
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
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(DateFormat('EEE, d MMM').format(_selectedDate),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_drop_down, color: Colors.grey)
              ],
            ),
          ),
        ),
      ],
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
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(Icons.event_busy,
                    size: 48, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 24),
              Text("No trips found for today.",
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              Text("Try changing your search location or check back later.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey.shade500)),
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
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildTripCard(Trip trip, bool isDesktop) {
    final startTime = DateFormat('h.mm a').format(trip.departureTime);
    final endTime = DateFormat('h.mm a').format(trip.arrivalTime);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
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
                    color: Colors.grey.shade200,
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
                              ? Colors.red.shade50
                              : Colors.green.shade50,
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
                    _updateButton(trip),
                  ],
                )
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _tripInfo(startTime, endTime),
                    _updateButton(trip),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(children: [_busInfo(trip)]),
              ],
            ),
    );
  }

  Widget _tripInfo(String start, String end) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$start - $end",
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget _busInfo(Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${trip.fromCity} ➔ ${trip.toCity}",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 16)),
        const SizedBox(height: 4),
        Text(
            "Bus: ${trip.busNumber} • T${trip.id.substring(0, 4).toUpperCase()}",
            style:
                GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _updateButton(Trip trip) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ConductorTripManagementScreen(trip: trip)))
            .then((_) => _loadTripsForDate(_selectedDate));
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      child: Text("Update",
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: Colors.white)),
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
      width: 150,
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
              style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
