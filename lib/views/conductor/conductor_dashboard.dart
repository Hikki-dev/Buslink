import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/location_permission_helper.dart';

import '../admin/admin_dashboard.dart';

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

  @override
  void initState() {
    super.initState();
    // Auto-load cities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripController>(context, listen: false)
          .fetchAvailableCities();

      // Prompt for Location Permission on Login (Conductor Only)
      LocationPermissionHelper.checkAndRequestPermission(context);
    });
  }

  @override
  void dispose() {
    _ticketIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  "Conductor Dashboard",
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
                  tooltip: isDark ? "Light Mode" : "Dark Mode",
                  onPressed: () {
                    themeController
                        .setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                  },
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      key: const Key('conductor_logout_btn'),
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
                      label: const Text("Log Out",
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
          Text("Find Trip",
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Manage your routes and passengers",
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
              label: const Text("Search Trips",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          const Text(
            "Admin Preview Mode",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                  (route) => false);
            },
            child: const Text("Exit", style: TextStyle(color: Colors.black87)),
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
          Text("Scan Ticket",
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Scan a passenger ticket to verify boarding",
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
                    labelText: "Manual Ticket ID",
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
                  label: const Text("Use Camera"),
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
                  label: const Text("Verify"),
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

  void _verifyTicket(String ticketId) async {
    if (ticketId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a ticket ID")));
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
          final depTime = ticket.tripData['departureTime'] is Timestamp
              ? (ticket.tripData['departureTime'] as Timestamp).toDate()
              : DateTime.now();

          if (now.difference(depTime).inHours > 12) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Access Denied: Trip expired >12h ago"),
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
                  Text("Verified Code: ${ticket.shortId ?? 'N/A'}",
                      style: const TextStyle(
                          fontFamily: 'Outfit',
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
                      "Origin", ticket.tripData['fromCity'] ?? 'N/A'),
                  _ticketDetailRow(
                      "Destination", ticket.tripData['toCity'] ?? 'N/A'),

                  const SizedBox(height: 16),
                  const Text("Seat Location:",
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
                        isDark: false,
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
                      child: const Text("Approve Boarding"),
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

  Future<void> _search() async {
    if (_selectedFromCity == null || _selectedToCity == null) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _results = [];
    });

    try {
      final controller = Provider.of<TripController>(context, listen: false);
      final trips = await controller.service
          .searchTrips(_selectedFromCity!, _selectedToCity!, _selectedDate);
      final enriched = await controller.enrichTrips(trips);

      final now = DateTime.now();
      final filtered = enriched.where((t) {
        if (t.departureTime.day > now.day) return true;
        if (t.departureTime.year > now.year ||
            t.departureTime.month > now.month) {
          return true;
        }

        final diffHours = now.difference(t.departureTime).inHours;

        if (t.status == 'departed' ||
            t.status == 'on_way' ||
            t.status == 'delayed') {
          return diffHours < 18;
        }

        if (t.status == 'completed' || t.status == 'cancelled') {
          return false;
        }

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
                    const Expanded(
                      child: Text("Find Trip",
                          style: TextStyle(
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
                          decoration: const InputDecoration(
                              labelText: "Origin",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on_outlined)),
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
                          decoration: const InputDecoration(
                              labelText: "Destination",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag_outlined)),
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
                              DateTime.now().add(const Duration(days: 30)));
                      if (d != null) {
                        setState(() => _selectedDate = d);
                      }
                    },
                    child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(DateFormat('yyyy-MM-dd').format(_selectedDate))
                          ],
                        )),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _search,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : const Text("Search")),
                  )
                ] else ...[
                  // --- RESULTS ---
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_results.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.bus_alert,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text("No active trips found."),
                          const SizedBox(height: 12),
                          TextButton(
                              onPressed: () =>
                                  setState(() => _hasSearched = false),
                              child: const Text("Search Again"))
                        ],
                      ),
                    )
                  else ...[
                    // LIST
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final t = _results[index];
                          return ListTile(
                            title: Text("${t.fromCity} -> ${t.toCity}"),
                            subtitle: Text(
                                "${DateFormat('HH:mm').format(t.departureTime)} • ${t.status}"),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navigate to management
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ConductorTripManagementScreen(
                                              trip: t)));
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: () => setState(() => _hasSearched = false),
                        child: const Text("Back to Search"))
                  ]
                ]
              ],
            )));
  }
}
