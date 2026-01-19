import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

// import '../layout/conductor_navbar.dart';
// import '../admin/layout/admin_bottom_nav.dart';
import '../admin/admin_dashboard.dart';
import '../../utils/language_provider.dart';
import 'conductor_trip_management_screen.dart';
import '../booking/bus_layout_widget.dart';
import 'package:intl/intl.dart';
import '../../views/auth/login_screen.dart';
import 'qr_scan_screen.dart';

class ConductorDashboard extends StatefulWidget {
  final bool isAdminView;
  const ConductorDashboard({super.key, this.isAdminView = false});

  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard> {
  final TextEditingController _ticketIdController = TextEditingController();
  // final TextEditingController _busNumberController = TextEditingController(); // Unused

  @override
  void initState() {
    super.initState();
    // Auto-load cities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripController>(context, listen: false)
          .fetchAvailableCities();
    });
  }

  @override
  void dispose() {
    _ticketIdController.dispose();
    // _busNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // get user from provider if needed
    // final user = Provider.of<AuthService>(context).currentUser;

    return LayoutBuilder(builder: (context, constraints) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // No back button on dashboard
          title: Row(
            children: [
              const Icon(Icons.directions_bus, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Provider.of<LanguageProvider>(context)
                      .translate('conductor_dashboard_title'),
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            // 1. Theme Selector
            Consumer<ThemeController>(
              builder: (context, themeController, _) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                      color: Theme.of(context).colorScheme.onSurface),
                  tooltip: isDark
                      ? Provider.of<LanguageProvider>(context)
                          .translate('light_mode')
                      : Provider.of<LanguageProvider>(context)
                          .translate('dark_mode_tooltip'),
                  onPressed: () {
                    themeController
                        .setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                  },
                );
              },
            ),
            // 2. Language Selector
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) {
                return PopupMenuButton<String>(
                  icon: Icon(Icons.language,
                      color: Theme.of(context).colorScheme.onSurface),
                  tooltip: Provider.of<LanguageProvider>(context)
                      .translate('change_language'),
                  onSelected: (String code) {
                    languageProvider.setLanguage(code);
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'en',
                      child: Text('English'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'si',
                      child: Text('සිංහල (Sinhala)'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'ta',
                      child: Text('தமிழ் (Tamil)'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // REMOVED BOTTOM NAV BAR as requested
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (widget.isAdminView) _buildAdminBanner(),

                    // 1. TICKET SCANNER (Keep as is)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _buildScannerSection(isDark),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // 2. BUS MANAGEMENT (Search)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _buildBusSearchSection(isDark),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // 3. LOGOUT BUTTON
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Provider.of<AuthService>(context, listen: false)
                            .signOut();
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true)
                              .pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(
                          Provider.of<LanguageProvider>(context)
                              .translate('log_out'),
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50))),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBusSearchSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search, size: 64, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          Text(
              Provider.of<LanguageProvider>(context)
                  .translate('find_trip_title'),
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
              Provider.of<LanguageProvider>(context)
                  .translate('manage_routes_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                    context: context, builder: (_) => const FindTripDialog());
              },
              icon: const Icon(Icons.search),
              label: Text(
                  Provider.of<LanguageProvider>(context)
                      .translate('search_trips_button'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ...

  Widget _buildAdminBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300), // Strong Amber
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Provider.of<LanguageProvider>(context)
                .translate('admin_preview_mode'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                  (route) => false);
            },
            child: Text(
                Provider.of<LanguageProvider>(context).translate('exit'),
                style: const TextStyle(color: Colors.black87)),
          )
        ],
      ),
    );
  }

  Widget _buildScannerSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner,
                size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
              Provider.of<LanguageProvider>(context)
                  .translate('scan_ticket_title'),
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
              Provider.of<LanguageProvider>(context)
                  .translate('scan_ticket_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ticketIdController,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: Provider.of<LanguageProvider>(context)
                        .translate('manual_ticket_id'),
                    hintText: "e.g. TICKET-1234",
                    prefixIcon: const Icon(Icons.keyboard),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Web scanning works on HTTPS (e.g. Vercel)
                    // Ensure camera permissions are granted.

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRScanScreen()),
                    );

                    if (result != null && result is String) {
                      setState(() {
                        _ticketIdController.text = result;
                      });
                      if (context.mounted) {
                        _verifyTicket(result);
                      }
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(Provider.of<LanguageProvider>(context)
                      .translate('use_camera')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _verifyTicket(_ticketIdController.text),
                  icon: const Icon(Icons.check),
                  label: Text(Provider.of<LanguageProvider>(context)
                      .translate('verify_button')),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Removed unused _buildMyTripsList and _buildTripCard

  void _verifyTicket(String ticketId) async {
    if (ticketId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Provider.of<LanguageProvider>(context, listen: false)
              .translate('please_enter_ticket_id'))));
      return;
    }
    final controller = Provider.of<TripController>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final Ticket? ticket = await controller.verifyTicket(ticketId.trim());
    if (mounted) Navigator.pop(context);

    if (ticket != null) {
      // Access Control: Check if trip is expired
      final now = DateTime.now();

      DateTime? arrivalTime;
      try {
        if (ticket.tripData['arrivalTime'] != null) {
          final val = ticket.tripData['arrivalTime'];
          if (val is String) {
            arrivalTime = DateTime.tryParse(val);
          } else if (val is Timestamp) {
            arrivalTime = val.toDate();
          }
        } else if (ticket.tripData['departureTime'] != null) {
          final val = ticket.tripData['departureTime'];
          DateTime? depTime;
          if (val is String) {
            depTime = DateTime.tryParse(val);
          } else if (val is Timestamp) {
            depTime = val.toDate();
          }
          if (depTime != null) {
            // Fallback: 4h trip duration
            arrivalTime = depTime.add(const Duration(hours: 4));
          }
        }

        if (arrivalTime != null) {
          // Access allowed only up to 12 hours AFTER departure (or 4h after arrival)
          // Using strict 12h from departure as the primary "Time Passed" rule per user Constraint.
          final depTime = ticket.tripData['departureTime'] is Timestamp
              ? (ticket.tripData['departureTime'] as Timestamp).toDate()
              : DateTime.now(); // Fallback

          if (now.difference(depTime).inHours > 12) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      Provider.of<LanguageProvider>(context, listen: false)
                          .translate('access_denied_12h')),
                  backgroundColor: Colors.red));
            }
            return;
          }
        }
      } catch (e) {
        debugPrint("Expiration check error: $e");
      }

      if (mounted) _showTicketDetailsDialog(ticket);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "${Provider.of<LanguageProvider>(context, listen: false).translate('invalid_ticket_id')}: $ticketId"),
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
            child: SingleChildScrollView(
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
                  Text(
                      "${Provider.of<LanguageProvider>(context).translate('verified_code')}: ${ticket.shortId ?? 'N/A'}",
                      style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ticketDetailRow(
                      Provider.of<LanguageProvider>(context)
                          .translate('passenger'),
                      ticket.passengerName),
                  _ticketDetailRow(
                      Provider.of<LanguageProvider>(context).translate('seats'),
                      ticket.seatNumbers.join(", ")),
                  _ticketDetailRow(
                      Provider.of<LanguageProvider>(context)
                          .translate('bus_no'),
                      ticket.tripData['busNumber'] ?? 'N/A'),
                  _ticketDetailRow(
                      Provider.of<LanguageProvider>(context)
                          .translate('origin'),
                      ticket.tripData['fromCity'] ?? 'N/A'),
                  _ticketDetailRow(
                      Provider.of<LanguageProvider>(context)
                          .translate('destination'),
                      ticket.tripData['toCity'] ?? 'N/A'),

                  const SizedBox(height: 16),
                  Text(
                      "${Provider.of<LanguageProvider>(context).translate('seat_location')}:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Visual Seat Verification
                  SizedBox(
                    height: 300,
                    child: SingleChildScrollView(
                      child: BusLayoutWidget(
                        trip: Trip.fromMap(ticket.tripData, ticket.tripId),
                        totalSeats: 40,
                        highlightedSeats: ticket.seatNumbers,
                        isReadOnly: true,
                        isDark:
                            false, // Dialog is usually light or adaptive, but hardcoding false for now to match white background
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(Provider.of<LanguageProvider>(context)
                          .translate('approve_boarding')),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
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
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class FindTripDialog extends StatefulWidget {
  const FindTripDialog({super.key});

  @override
  State<FindTripDialog> createState() => _FindTripDialogState();
}

class _FindTripDialogState extends State<FindTripDialog> {
  String? _selectedFromCity;
  String? _selectedToCity;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<EnrichedTrip> _results = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Fetch cities dynamically when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripController>(context, listen: false)
          .fetchAvailableCities();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _search() async {
    if (_selectedFromCity == null || _selectedToCity == null) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _results = [];
    });

    try {
      final controller = Provider.of<TripController>(context, listen: false);
      // We use the same search logic as Home
      final trips = await controller.service
          .searchTrips(_selectedFromCity!, _selectedToCity!, _selectedDate);
      final enriched = await controller.enrichTrips(trips);

      // Filter out trips that started > 4 hours ago to declutter (unless active)
      // User requested not to see 5AM trips at 10AM.
      final now = DateTime.now();
      final filtered = enriched.where((t) {
        // Access Control Logic - Robust & Dynamic

        // 1. If it's a future trip (tomorrow), allow it (Planning).
        if (t.departureTime.day > now.day) return true;
        if (t.departureTime.year > now.year ||
            t.departureTime.month > now.month) {
          return true;
        }

        // 2. SAME DAY LOGIC
        final diffHours = now.difference(t.departureTime).inHours;

        // If trip is ACTIVE (Departed/OnWay/Delayed), show it regardless of time (within reason, say 24h)
        // This ensures a delayed bus driven at 3 PM (scheduled 5 AM) is still visible IF status was updated.
        // However, if status is still 'Scheduled' at 3 PM for a 5 AM bus, it's likely a stale/missed record.

        if (t.status == 'departed' ||
            t.status == 'on_way' ||
            t.status == 'delayed') {
          // Keep active trips visible for up to 18 hours to allow for very long journeys
          return diffHours < 18;
        }

        // 3. If Scheduled/Completed/Cancelled
        if (t.status == 'completed' || t.status == 'cancelled') {
          // Hide immediately or after short buffer
          return false;
        }

        // 4. If Scheduled but time passed
        // User Request: "1.51 PM and its showing me 5AM trips... show me the current ones only"
        // Implicitly: Hide trips scheduled more than X hours ago if they haven't started.
        // Let's set a strict window: Hide trips scheduled > 4 hours ago if they are still 'scheduled'.
        // (Assuming a bus won't start 4 hours late without status update to 'Delayed')
        if (diffHours > 3) {
          return false;
        }

        return true;
      }).toList();

      setState(() {
        _results = filtered;
      });
    } catch (e) {
      debugPrint("Error searching trips: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                          Provider.of<LanguageProvider>(context)
                              .translate('find_trip_title'),
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                if (!_hasSearched ||
                    (_hasSearched && _results.isEmpty && _isLoading)) ...[
                  // --- INPUT FORM ---
                  Consumer<TripController>(builder: (context, tripCtrl, child) {
                    final cities = tripCtrl.availableCities;

                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          key: const Key('fromCityDropdown'),
                          initialValue: _selectedFromCity,
                          items: cities
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedFromCity = v),
                          decoration: InputDecoration(
                              labelText: Provider.of<LanguageProvider>(context)
                                  .translate('origin'),
                              border: const OutlineInputBorder(),
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined)),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const Key('toCityDropdown'),
                          initialValue: _selectedToCity,
                          items: cities
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedToCity = v),
                          decoration: InputDecoration(
                              labelText: Provider.of<LanguageProvider>(context)
                                  .translate('destination'),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.flag_outlined)),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 60)));
                      if (d != null) setState(() => _selectedDate = d);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                          labelText: Provider.of<LanguageProvider>(context)
                              .translate('select_date'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today)),
                      child:
                          Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _search,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              Provider.of<LanguageProvider>(context)
                                  .translate('search_trips_button'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ] else ...[
                  // --- RESULTS LIST ---
                  Text(
                      "${Provider.of<LanguageProvider>(context).translate('results_for')} ${DateFormat('MMM d').format(_selectedDate)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    Center(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: AppTheme.primaryColor),
                        const SizedBox(height: 16),
                        Text(
                            Provider.of<LanguageProvider>(context)
                                .translate('searching_trips_loading'),
                            style: const TextStyle(
                                fontFamily: 'Inter', color: Colors.grey))
                      ],
                    ))
                  else if (_results.isEmpty)
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(Provider.of<LanguageProvider>(context)
                          .translate('no_trips_found_today')),
                    ))
                  else
                    SizedBox(
                      height: 300,
                      child: ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final trip = _results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.directions_bus,
                                    color: Colors.blue)),
                            title: Text("${trip.fromCity} - ${trip.toCity}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "${DateFormat('hh:mm a').format(trip.departureTime)} • Bus ${trip.busNumber}"),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Access Control check
                              final now = DateTime.now();

                              // Fallback if arrivalTime is suspect (same as departure usually means missing duration)
                              DateTime effectiveArrival = trip.arrivalTime;
                              if (trip.arrivalTime
                                      .difference(trip.departureTime)
                                      .inMinutes <
                                  30) {
                                // Assert at least 4 hours if data invalid
                                effectiveArrival = trip.departureTime
                                    .add(const Duration(hours: 4));
                              }

                              // Allow up to 4 hours after optimized arrival time
                              final accessLimit = effectiveArrival
                                  .add(const Duration(hours: 4));

                              if (now.isAfter(accessLimit) ||
                                  trip.status == 'cancelled') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            Provider.of<LanguageProvider>(
                                                    context,
                                                    listen: false)
                                                .translate(
                                                    'access_denied_expired')),
                                        backgroundColor: Colors.red));
                                return;
                              }

                              Navigator.pop(context);
                              // Provider.of<TripController>(context, listen: false).setConductorTrip(trip);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ConductorTripManagementScreen(
                                              trip: trip)));
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: () => setState(() {
                            _hasSearched = false;
                            _results = [];
                          }),
                      child: Text(Provider.of<LanguageProvider>(context)
                          .translate('search_again')))
                ]
              ],
            )));
  }
}
