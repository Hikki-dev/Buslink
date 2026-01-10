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
import '../results/bus_list_screen.dart';
import '../layout/desktop_navbar.dart';
// import '../layout/mobile_navbar.dart';
import '../layout/custom_app_bar.dart';
import '../analytics/travel_stats_screen.dart';
import 'refund_request_screen.dart';

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

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          if (isDesktop)
            Material(
              elevation: 4,
              child: DesktopNavBar(selectedIndex: 1, isAdminView: isAdminView),
            ),
          // App Bar Logic: currently MyTripsScreen has a CustomAppBar.
          // We need to keep the AppBar logic but remove the BottomNav.
          // If we remove Scaffold, we can't use 'appBar' property easily unless we wrap in Scaffold but WITHOUT BottomNav.
          // Actually, CustomerMainScreen has a BODY that is IndexedStack -> MyTripsScreen.
          // If MyTripsScreen returns a Scaffold, it's fine as long as it doesn't have a BottomNavigationBar.
          // So we just REMOVE bottomNavigationBar.

          Expanded(
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              // Removed BottomNavigationBar
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
                title: Text("My Trips",
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
                bottom: const TabBar(
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                      fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: "UPCOMING"),
                    Tab(text: "HISTORY"),
                  ],
                ),
              ),
              body: user == null
                  ? _buildLoginPrompt()
                  : TabBarView(
                      children: [
                        _TripsList(
                            controller: controller,
                            userId: user.uid,
                            isHistory: false),
                        _TripsList(
                            controller: controller,
                            userId: user.uid,
                            isHistory: true),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Please sign in to view your trips",
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TripsList extends StatelessWidget {
  final TripController controller;
  final String userId;
  final bool isHistory;

  const _TripsList(
      {required this.controller,
      required this.userId,
      required this.isHistory});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ticket>>(
      stream: controller.getUserTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        var tickets = snapshot.data ?? [];
        final now = DateTime.now();

        // Safe Filtering with Buffer
        final cutoff = now.subtract(const Duration(hours: 12));

        tickets = tickets.where((ticket) {
          DateTime? tripDate;
          if (ticket.tripData.containsKey('departureTime') &&
              ticket.tripData['departureTime'] != null) {
            try {
              final dep = ticket.tripData['departureTime'];
              if (dep is DateTime) {
                tripDate = dep;
              } else if (dep is Timestamp) {
                tripDate = dep.toDate();
              }
            } catch (_) {}
          }
          tripDate ??= ticket.bookingTime;

          if (isHistory) {
            // History = Completed more than 12 hours ago
            return tripDate.isBefore(cutoff);
          } else {
            // Upcoming = Future OR departed within last 12 hours
            return tripDate.isAfter(cutoff);
          }
        }).toList();

        // Sorting
        tickets.sort((a, b) {
          DateTime dateA = a.bookingTime;
          DateTime dateB = b.bookingTime;

          // Try to get actual trip date
          if (a.tripData['departureTime'] is Timestamp) {
            dateA = (a.tripData['departureTime'] as Timestamp).toDate();
          }
          if (b.tripData['departureTime'] is Timestamp) {
            dateB = (b.tripData['departureTime'] as Timestamp).toDate();
          }

          if (isHistory) {
            return dateB.compareTo(dateA); // Newest first
          } else {
            return dateA.compareTo(dateB); // Soonest first
          }
        });

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isHistory ? Icons.history : Icons.directions_bus_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(isHistory ? "No past trips" : "No upcoming trips",
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return _BoardingPassCard(
                    ticket: tickets[index], shouldListen: !isHistory);
              },
            ),
          ),
        );
      },
    );
  }
}

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

      if (rawStatus == 'delayed') {
        statusStr = "DELAYED (+${delayMin}m)";
        statusColor = Colors.red;
      } else if (rawStatus == 'started' || rawStatus == 'departed') {
        statusStr = "ON WAY";
        statusColor = Colors.blue;
      } else if (rawStatus == 'completed' || rawStatus == 'arrived') {
        statusStr = "ARRIVED";
        statusColor = Colors.green;
      } else if (rawStatus == 'onTime' || rawStatus == 'scheduled') {
        statusStr = "ON TIME";
        statusColor = Colors.green;
      } else if (rawStatus == 'cancelled') {
        statusStr = "CANCELLED";
        statusColor = Colors.red.shade900;
      }
    } else {
      // Fallback/Static Status (basic)
      // For history, we assume it's done or use ticket data if available
      statusStr = "HISTORY"; // Or derive from ticket if status was saved
    }

    // Common UI Logic
    final fromCity =
        tripData['fromCity'] ?? ticket.tripData['fromCity'] ?? 'Unknown';
    final toCity = tripData['toCity'] ?? ticket.tripData['toCity'] ?? 'Unknown';
    final seatsCount = ticket.seatNumbers.length;

    DateTime depTime = ticket.bookingTime;
    if (tripData['departureTime'] is Timestamp) {
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusStr,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor)),
                    ),
                    Text(
                        "Ref: ${ticket.ticketId.substring(0, 8).toUpperCase()}",
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: subTextColor)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("FROM",
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("TO",
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
                            SnackBar(content: Text("Error opening ticket: $e")),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8), // Fix clipping
                          side: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text("View Ticket",
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
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Book Again Logic
                        final controller =
                            Provider.of<TripController>(context, listen: false);
                        controller.setFromCity(
                            ticket.tripData['fromCity'] ?? 'Colombo');
                        controller
                            .setToCity(ticket.tripData['toCity'] ?? 'Kandy');
                        controller.setDepartureDate(DateTime.now());
                        controller.searchTrips(controller.fromCity ?? '',
                            controller.toCity ?? '', DateTime.now());

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BusListScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8), // Fix clipping
                          backgroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("Book Again",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // NEW: Refund Link for Upcoming Trips
          if (!shouldListen) // implies isHistory == false (wait check calling logic) -- Actually shouldListen is true for upcoming usually
            const SizedBox.shrink(),

          if (tripData['status'] != 'completed' &&
              tripData['status'] != 'cancelled' &&
              tripData['status'] != 'arrived')
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextButton.icon(
                onPressed: () {
                  try {
                    final trip = Trip.fromMap(tripData, ticket.tripId);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RefundRequestScreen(
                                ticket: ticket, trip: trip)));
                  } catch (e) {
                    debugPrint("Error nav to refund: $e");
                  }
                },
                icon: const Icon(Icons.undo, size: 16, color: Colors.grey),
                label: const Text("Request Refund / Cancel",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ),
        ],
      ),
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
