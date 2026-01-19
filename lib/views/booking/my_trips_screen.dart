// lib/views/booking/my_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import '../ticket/ticket_screen.dart';
// import '../results/bus_list_screen.dart'; (Removed)
import '../layout/desktop_navbar.dart';
// import '../layout/mobile_navbar.dart';
import '../layout/custom_app_bar.dart';
import '../analytics/travel_stats_screen.dart';
import 'refund_request_screen.dart';
import '../../utils/language_provider.dart';
// import 'my_trips_stats_widget.dart';

class MyTripsScreen extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool isAdminView;

  const MyTripsScreen(
      {super.key,
      this.showBackButton = true,
      this.onBack,
      this.isAdminView = false});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final controller = Provider.of<TripController>(context);
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return StreamBuilder<List<Ticket>>(
        stream: controller.getUserTickets(),
        builder: (context, snapshot) {
          // Handle Loading/Error explicitly if needed, but for scaffold structure we might want to return Scaffold even if loading.
          // Let's keep Scaffold structure.
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final allTickets = snapshot.data ?? [];

          // Stats Calculation
          if (!isLoading && !hasError) {
            // Logic moved to TravelStatsScreen
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                if (isDesktop)
                  Material(
                    elevation: 4,
                    child: DesktopNavBar(
                        selectedIndex: 1, isAdminView: isAdminView),
                  ),
                Expanded(
                  child: Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    appBar: CustomAppBar(
                      hideActions: isDesktop,
                      automaticallyImplyLeading: showBackButton && !isDesktop,
                      leading: showBackButton && !isDesktop
                          ? BackButton(
                              color: Theme.of(context).colorScheme.onSurface,
                              onPressed: () {
                                if (onBack != null) {
                                  onBack!();
                                } else {
                                  Navigator.pop(context);
                                }
                              })
                          : null,
                      title: Text(
                          Provider.of<LanguageProvider>(context)
                              .translate('my_trips_title'),
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold)),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.bar_chart),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const TravelStatsScreen()));
                          },
                          tooltip: "Travel Stats",
                        )
                      ],
                      bottom: TabBar(
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                            fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(
                              text: Provider.of<LanguageProvider>(context)
                                  .translate('tab_upcoming')),
                          Tab(
                              text: Provider.of<LanguageProvider>(context)
                                  .translate('tab_history')),
                        ],
                      ),
                    ),
                    body: user == null
                        ? _buildLoginPrompt(context)
                        : isLoading
                            ? const Center(
                                child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: AppTheme.primaryColor),
                                  SizedBox(height: 16),
                                  Text("Loading your trips...",
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Colors.grey))
                                ],
                              ))
                            : hasError
                                ? Center(
                                    child: Text("Error: ${snapshot.error}"))
                                : Column(
                                    children: [
                                      Expanded(
                                        child: TabBarView(
                                          children: [
                                            // Upcoming Tab
                                            _TripsList(
                                                allTickets: allTickets,
                                                userId: user.uid,
                                                isHistory: false),
                                            // History Tab
                                            _TripsList(
                                                allTickets: allTickets,
                                                userId: user.uid,
                                                isHistory: true),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
              Provider.of<LanguageProvider>(context)
                  .translate('sign_in_view_trips'),
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TripsList extends StatelessWidget {
  final List<Ticket> allTickets;
  final String userId;
  final bool isHistory;

  const _TripsList(
      {required this.allTickets,
      required this.userId,
      required this.isHistory});

  @override
  Widget build(BuildContext context) {
    final now = DateTime
        .now(); // Used in cutoff calculation below, so it IS used. Wait, user error?
    // User error says 'now' is not used?
    // Line 199: final cutoff = now.subtract(const Duration(hours: 12));
    // It IS used. Maybe there was another 'now' somewhere?
    // Let's re-read the error: "The value of the local variable 'now' isn't used. startLine: 53"
    // The previous view_file started at 101. I need to check line 53.

    // Helper to parse date consistently
    DateTime getTripDate(Map<String, dynamic> data, DateTime bookingTime) {
      dynamic dep = data['departureDateTime'] ??
          data['departureTime']; // Check departureDateTime first!
      if (dep is Timestamp) return dep.toDate();
      if (dep is DateTime) return dep;
      if (dep is String) {
        return DateTime.tryParse(dep) ??
            bookingTime; // Handle strings just in case
      }
      return bookingTime;
    }

    // --- Filter List for Display (Respecting isHistory) ---
    final cutoff = now.subtract(const Duration(hours: 12));
    var tickets = allTickets.where((ticket) {
      DateTime tripDate = getTripDate(ticket.tripData, ticket.bookingTime);

      final statusLower = ticket.status.toLowerCase();

      if (statusLower == 'refunded') return false;

      if (statusLower == 'cancelled') {
        if (!isHistory) return false;
      }

      if (isHistory) {
        if (statusLower == 'cancelled') return true;
        return tripDate.isBefore(cutoff);
      } else {
        return tripDate.isAfter(cutoff);
      }
    }).toList();

    // Sort
    tickets.sort((a, b) {
      final dateA = getTripDate(a.tripData, a.bookingTime);
      final dateB = getTripDate(b.tripData, b.bookingTime);
      if (isHistory) {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });

    // --- GROUPING LOGIC ---
    final List<dynamic> displayItems = [];
    final Map<String, List<Ticket>> bundles = {};

    for (var t in tickets) {
      String? groupId;

      if (t.tripData['batchId'] != null) {
        groupId = t.tripData['batchId'];
      } else if (t.paymentIntentId != null && t.paymentIntentId!.isNotEmpty) {
        groupId = t.paymentIntentId;
      }

      if (groupId != null) {
        bundles.putIfAbsent(groupId, () => []).add(t);
      } else {
        // No group, treat as single
        displayItems.add(t);
      }
    }

    // Add bundles to display items
    for (var entry in bundles.entries) {
      if (entry.value.length > 1) {
        displayItems.add(entry.value); // Add List<Ticket>
      } else {
        displayItems.add(entry.value.first); // Single ticket from group
      }
    }

    // Re-sort display items by date of first ticket
    displayItems.sort((a, b) {
      Ticket tA = (a is List) ? (a as List<Ticket>).first : (a as Ticket);
      Ticket tB = (b is List) ? (b as List<Ticket>).first : (b as Ticket);

      final dateA = getTripDate(tA.tripData, tA.bookingTime);
      final dateB = getTripDate(tB.tripData, tB.bookingTime);

      if (isHistory) return dateB.compareTo(dateA);
      return dateA.compareTo(dateB);
    });

    return displayItems.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isHistory ? Icons.history : Icons.directions_bus_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                    isHistory
                        ? Provider.of<LanguageProvider>(context)
                            .translate('no_past_trips')
                        : Provider.of<LanguageProvider>(context)
                            .translate('no_upcoming_trips'),
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 18, color: Colors.grey)),
              ],
            ),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView.separated(
              padding: const EdgeInsets.only(
                  bottom: 100, left: 16, right: 16, top: 16),
              itemCount: displayItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                // Not History (Upcoming) OR History (Unified logic as Stats Removed)
                final item = displayItems[index];
                if (item is List<Ticket>) {
                  return _BulkBoardingPassCard(tickets: item);
                } else {
                  return _BoardingPassCard(
                    ticket: item as Ticket,
                    shouldListen: !isHistory,
                  );
                }
              },
            ),
          );
  }
} // End _TripsList

class _BoardingPassCard extends StatelessWidget {
  final Ticket ticket;
  final bool shouldListen;
  const _BoardingPassCard({required this.ticket, this.shouldListen = true});

  @override
  Widget build(BuildContext context) {
    if (shouldListen) {
      return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('trips')
              .doc(ticket.tripId)
              .snapshots(),
          builder: (context, snapshot) {
            return _buildCardContent(context, snapshot.data);
          });
    } else {
      // Static render for history
      return _buildCardContent(context, null);
    }
  }

  Widget _buildCardContent(BuildContext context, DocumentSnapshot? snapshot) {
    var tripData = ticket.tripData;
    String statusStr = "SCHEDULED";
    Color statusColor = Colors.grey;

    if (snapshot != null && snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      tripData = data;
      // Determine Status from live data
      final rawStatus = data['status'] ?? 'scheduled';
      final delayMin = data['delayMinutes'] ?? 0;
      final lp = Provider.of<LanguageProvider>(context);

      if (rawStatus == 'delayed') {
        statusStr = "${lp.translate('delayed').toUpperCase()} (+${delayMin}m)";
        statusColor = Colors.red;
      } else if (rawStatus == 'started' || rawStatus == 'departed') {
        statusStr = lp.translate('on_way').toUpperCase();
        statusColor = Colors.blue;
      } else if (rawStatus == 'completed' || rawStatus == 'arrived') {
        statusStr = lp.translate('arrived').toUpperCase();
        statusColor = Colors.green;
      } else if (rawStatus == 'onTime' || rawStatus == 'scheduled') {
        statusStr = lp.translate('scheduled').toUpperCase();
        // Note: 'status_on_time' key exists but 'scheduled' is cleaner for default
        statusColor = Colors.green;
      } else if (rawStatus == 'cancelled') {
        statusStr = lp.translate('cancelled').toUpperCase();
        statusColor = Colors.red.shade900;
      }
    } else {
      // Fallback/Static Status (basic)
      statusStr = Provider.of<LanguageProvider>(context)
          .translate('tab_history')
          .toUpperCase();
    }

    // Common UI Logic
    final fromCity = tripData['fromCity'] ??
        tripData['originCity'] ??
        ticket.tripData['fromCity'] ??
        ticket.tripData['originCity'] ??
        'Unknown';
    final toCity = tripData['toCity'] ??
        tripData['destinationCity'] ??
        ticket.tripData['toCity'] ??
        ticket.tripData['destinationCity'] ??
        'Unknown';
    final seatsCount = ticket.seatNumbers.length;

    DateTime depTime = ticket.bookingTime;
    if (tripData['departureDateTime'] is Timestamp) {
      depTime = (tripData['departureDateTime'] as Timestamp).toDate();
    } else if (tripData['departureTime'] is Timestamp) {
      depTime = (tripData['departureTime'] as Timestamp).toDate();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Part
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildStatusBadge(statusStr, statusColor),
                        // Show DELAYED badge explicitly next to Arrived if applicable
                        if ((statusStr == "ARRIVED" ||
                                statusStr == "COMPLETED") &&
                            (tripData['delayMinutes'] ?? 0) > 0) ...[
                          const SizedBox(width: 8),
                          _buildStatusBadge(
                              "DELAYED (+${tripData['delayMinutes']}m)",
                              Colors.red),
                        ]
                      ],
                    ),
                    // Ref ID Removed
                    // Text(
                    //     "Ref: ${ticket.ticketId.substring(0, 8).toUpperCase()}",
                    //     style: TextStyle(
                    //         fontFamily: 'Inter',
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.bold,
                    //         color: subTextColor)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                            Provider.of<LanguageProvider>(context)
                                .translate('from'),
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: subTextColor)),
                        const SizedBox(height: 4),
                        Text(fromCity,
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                      ],
                    ),
                    Icon(Icons.arrow_forward, color: subTextColor),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                            Provider.of<LanguageProvider>(context)
                                .translate('to'),
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: subTextColor)),
                        const SizedBox(height: 4),
                        Text(toCity,
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _infoBadge(
                              Icons.calendar_today,
                              DateFormat('MMM d').format(depTime),
                              subTextColor),
                          _infoBadge(
                              Icons.chair, "$seatsCount Seats", subTextColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("LKR ${ticket.totalAmount.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor))
                  ],
                )
              ],
            ),
          ),

          // Dotted Line (Optimized)
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 1,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      dashWidth: 6,
                      dashSpace: 4,
                    ),
                  ),
                ),
              ),
              Positioned(
                  left: -10,
                  top: -10,
                  child: CircleAvatar(
                      radius: 10,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor)),
              Positioned(
                  right: -10,
                  top: -10,
                  child: CircleAvatar(
                      radius: 10,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor)),
            ],
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Builder(builder: (context) {
              // DYNAMIC BUTTON LOGIC
              bool allowRefund = false;
              if (shouldListen &&
                  statusStr != 'CANCELLED' &&
                  statusStr != 'ARRIVED' &&
                  statusStr != 'COMPLETED' &&
                  statusStr != 'REFUNDED' &&
                  statusStr != 'HISTORY') {
                allowRefund = true;
              }

              return Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          try {
                            final trip =
                                Trip.fromMap(ticket.tripData, ticket.tripId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TicketScreen(
                                    ticketArg: ticket, tripArg: trip),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Error opening ticket: $e")),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text(
                            Provider.of<LanguageProvider>(context)
                                .translate('view_ticket'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor)),
                      ),
                    ),
                  ),
                  if (allowRefund) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            try {
                              final trip =
                                  Trip.fromMap(tripData, ticket.tripId);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => RefundRequestScreen(
                                          ticket: ticket, trip: trip)));
                            } catch (e) {
                              debugPrint("Error nav to refund: $e");
                            }
                          },
                          icon: const Icon(Icons.undo,
                              size: 18, color: Colors.white),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                Provider.of<LanguageProvider>(context)
                                    .translate('refund_btn'),
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white)),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ),
                  ]
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontFamily: 'Inter', fontWeight: FontWeight.w500, color: color))
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    this.color = Colors.grey,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BulkBoardingPassCard extends StatelessWidget {
  final List<Ticket> tickets;
  const _BulkBoardingPassCard({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const SizedBox.shrink();

    // Sort by date
    tickets.sort((a, b) => a.bookingTime.compareTo(b.bookingTime));

    final first = tickets.first;
    final last = tickets.last;
    final total = tickets.length;
    final totalPrice = tickets.fold(0.0, (prev, t) => prev + t.totalAmount);

    // Date Range
    final startFormat = DateFormat('MMM d').format(first.bookingTime);
    final endFormat = DateFormat('MMM d').format(last.bookingTime);
    final dateRange = (first.bookingTime.day == last.bookingTime.day &&
            first.bookingTime.month == last.bookingTime.month)
        ? startFormat
        : "$startFormat - $endFormat";

    // Route (Assume same route or Mixed)
    final fromCity = first.tripData['originCity'] ?? 'Unknown';
    final toCity = first.tripData['destinationCity'] ?? 'Unknown';

    // final isDark = Theme.of(context).brightness == Brightness.dark; // Unused

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.copy_all,
                        size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "BULK BOOKING ($total Trips)",
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                Text(
                  "LKR ${totalPrice.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fromCity,
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const Icon(Icons.arrow_downward,
                            size: 14, color: Colors.grey),
                        Text(toCity,
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("DATES",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(dateRange,
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketScreen(
                            // Pass list of tickets
                            ticketsArg: tickets,
                            // Fallback for logic that needs single trip
                            tripArg: Trip.fromMap(first.tripData, first.tripId),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text("View All Tickets & Download PDF"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
