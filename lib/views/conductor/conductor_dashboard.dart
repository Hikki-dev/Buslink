import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/trip_controller.dart';
import '../../models/boarding_result.dart';
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
import 'package:buslink/l10n/app_localizations.dart';
import 'package:buslink/views/widgets/language_selector.dart';
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
                  AppLocalizations.of(context)!.conductorDashboard,
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
            // 1. Language Selector
            const LanguageSelector(),
            const SizedBox(width: 8),

            // 2. Theme Selector
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
                      label: Text(AppLocalizations.of(context)!.logout,
                          style: const TextStyle(
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
              color: Colors.grey.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search,
                size: 48, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.findTrips,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.manageSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Outfit',
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
              label: Text(AppLocalizations.of(context)!.searchTrips,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner,
                size: 48, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.scanTicket,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.scanTicketSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ticketIdController,
                  textInputAction: TextInputAction.go,
                  autocorrect: false,
                  onSubmitted: _verifyTicket,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.manualTicketId,
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
                  label: Text(AppLocalizations.of(context)!.useCamera),
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
                  label: Text(AppLocalizations.of(context)!.verify),
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
              _showRejectedDialog("Ticket not accepted",
                  "Access Denied: Trip expired >12h ago");
            }
            return;
          }
        }
      } catch (e) {
        debugPrint("Expiration check error: $e");
      }

      if (ticket.isBoarded) {
        if (mounted) _showAlreadyBoarded(ticket.boardedAt!);
        return;
      }

      if (mounted) _showTicketDetailsDialog(ticket);
    } else {
      if (mounted) {
        _showRejectedDialog("Ticket not found", "Invalid Ticket ID: $ticketId");
      }
    }
  }

  void _showRejectedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: TicketRejectedCard(
            title: title,
            message: message,
            onClose: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  void _showAlreadyBoarded(DateTime at) =>
      _showRejectedDialog("Already boarded", alreadyBoardedMessage(at));

  void _showTicketDetailsDialog(Ticket ticket) {
    final controller = Provider.of<TripController>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var busy = false;
        return StatefulBuilder(
          builder: (_, setDialogState) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: TicketVerifiedCard(
                  ticket: ticket,
                  busy: busy,
                  onApprove: () async {
                    setDialogState(() => busy = true);
                    final result =
                        await controller.approveBoarding(ticket.ticketId);
                    if (!mounted || !dialogContext.mounted) return;
                    if (result.status == BoardingStatus.failed) {
                      setDialogState(() => busy = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "Could not record boarding. Check your connection and try again.")));
                      return;
                    }
                    Navigator.pop(dialogContext);
                    _announceBoarding(result);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _announceBoarding(BoardingResult result) {
    switch (result.status) {
      case BoardingStatus.recorded:
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Boarding recorded")));
      case BoardingStatus.alreadyBoarded:
        _showAlreadyBoarded(result.boardedAt ?? DateTime.now());
      case BoardingStatus.cancelled:
        _showRejectedDialog(
            "Ticket not accepted", "This ticket was cancelled.");
      case BoardingStatus.notFound:
        _showRejectedDialog(
            "Ticket not found", "This ticket no longer exists.");
      case BoardingStatus.failed:
        break;
    }
  }
}

/// Wording for the reject dialog when a ticket has already been checked in.
String alreadyBoardedMessage(DateTime at) =>
    "This ticket was already checked in at ${DateFormat('h:mm a').format(at)}. "
    "Each ticket can board only once.";

/// Shown when a ticket checks out. The code is the thing the
/// conductor must compare with the passenger's own screen, so it is the
/// biggest item.
class TicketVerifiedCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onApprove;

  /// True while the boarding is being saved; disables the button.
  final bool busy;

  /// Live seat data for the mini seat map (defaults to Firestore).
  final Stream<Trip>? seatStream;

  const TicketVerifiedCard({
    super.key,
    required this.ticket,
    required this.onApprove,
    this.busy = false,
    this.seatStream,
  });

  @override
  Widget build(BuildContext context) {
    final code = ticket.shortId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.verified, color: Colors.green.shade800, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text("Ticket is valid",
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text("Passenger",
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Colors.grey.shade700)),
        Text(ticket.passengerName.isEmpty ? 'N/A' : ticket.passengerName,
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final seat in ticket.seatNumbers)
              Chip(
                avatar: const Icon(Icons.event_seat, size: 18),
                label: Text("Seat $seat",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                width: 1.5),
          ),
          child: Column(
            children: [
              const Text(
                "Ask the passenger for their code. It must match:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Semantics(
                label: 'Verified code ${code ?? 'not available'}',
                excludeSemantics: true,
                child: Text(code ?? 'N/A',
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 44,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _row("Bus No", ticket.tripData['busNumber'] ?? 'N/A'),
        _row(
            "Origin",
            ticket.tripData['originCity'] ??
                ticket.tripData['fromCity'] ??
                'N/A'),
        _row(
            "Destination",
            ticket.tripData['destinationCity'] ??
                ticket.tripData['toCity'] ??
                'N/A'),
        const SizedBox(height: 8),
        const Text("Seat Location:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              tripStream: seatStream,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: busy ? null : onApprove,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            child: busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.white))
                : const Text("Approve Boarding"),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  color: Colors.grey.shade700)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Shown when a ticket cannot be accepted. A dialog, not a snackbar that
/// disappears while the conductor is looking at the passenger.
class TicketRejectedCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;
  const TicketRejectedCard({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.cancel, color: Colors.red.shade800, size: 56),
          ),
        ),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            child: const Text("Try again"),
          ),
        ),
      ],
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
                      tooltip: 'Close',
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
