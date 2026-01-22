// lib/views/booking/my_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import '../ticket/ticket_screen.dart';
import '../layout/desktop_navbar.dart';
import '../layout/custom_app_bar.dart';
import '../analytics/travel_stats_screen.dart';
import 'refund_request_screen.dart';

enum TripFilter { upcoming, completed, cancelled, delayed }

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
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final allTickets = snapshot.data ?? [];

          return DefaultTabController(
            length: 4, // Changed to 4 Tabs
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
                      bottom: TabBar(
                        isScrollable: true, // Scrollable for 4 tabs
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primaryColor,
                        labelStyle: const TextStyle(
                            fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: "UPCOMING"),
                          Tab(text: "COMPLETED"),
                          Tab(text: "CANCELLED"),
                          Tab(text: "DELAYED"),
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
                                            _TripsList(
                                                allTickets: allTickets,
                                                userId: user.uid,
                                                filter: TripFilter.upcoming),
                                            _TripsList(
                                                allTickets: allTickets,
                                                userId: user.uid,
                                                filter: TripFilter.completed),
                                            _TripsList(
                                                allTickets: allTickets,
                                                userId: user.uid,
                                                filter: TripFilter.cancelled),
                                            _TripsList(
                                                allTickets: allTickets,
                                                userId: user.uid,
                                                filter: TripFilter.delayed),
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
          const Text("Please sign in to view your trips",
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
  final TripFilter filter;

  const _TripsList(
      {required this.allTickets, required this.userId, required this.filter});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 12 hour buffer for "Current" trips to appear in Upcoming/Active?
    // Actually, sticking to simple logic:
    // Upcoming: Date > Now OR Status = Scheduled
    // Completed: Date < Now OR Status = Completed/Arrived
    // Cancelled: Status = Cancelled
    // Delayed: Status = Delayed

    var tickets = allTickets.where((ticket) {
      final tripData = ticket.tripData;
      // Prefer tripData status if available, else ticket status
      String status =
          (tripData['status'] ?? ticket.status).toString().toLowerCase();
      // Parse Date
      DateTime tripDate = ticket.bookingTime; // Default
      dynamic dep = tripData['departureDateTime'] ?? tripData['departureTime'];
      if (dep is Timestamp) {
        tripDate = dep.toDate();
      }

      switch (filter) {
        case TripFilter.cancelled:
          return status == 'cancelled';
        case TripFilter.delayed:
          return status == 'delayed';
        case TripFilter.completed:
          // Exclude cancelled/delayed from completed view?
          if (status == 'cancelled' ||
              status == 'delayed' ||
              status == 'refunded') {
            return false;
          }
          return status == 'completed' ||
              status == 'arrived' ||
              tripDate.isBefore(now);
        case TripFilter.upcoming:
          if (status == 'cancelled' ||
              status == 'delayed' ||
              status == 'refunded' ||
              status == 'completed' ||
              status == 'arrived') {
            return false;
          }
          return tripDate.isAfter(now) ||
              status == 'scheduled' ||
              status == 'Confirmed';
      }
    }).toList();

    // Sort
    tickets.sort((a, b) {
      DateTime dateA = a.bookingTime;
      DateTime dateB = b.bookingTime;
      // ... better parsing ...
      dynamic depA =
          a.tripData['departureDateTime'] ?? a.tripData['departureTime'];
      if (depA is Timestamp) {
        dateA = depA.toDate();
      }
      dynamic depB =
          b.tripData['departureDateTime'] ?? b.tripData['departureTime'];
      if (depB is Timestamp) {
        dateB = depB.toDate();
      }

      if (filter == TripFilter.upcoming) {
        return dateA.compareTo(dateB); // Ascending
      } else {
        return dateB.compareTo(dateA); // Descending (History most recent first)
      }
    });

    // Grouping
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
        displayItems.add(t);
      }
    }

    for (var entry in bundles.entries) {
      if (entry.value.length > 1) {
        displayItems.add(entry.value);
      } else {
        displayItems.add(entry.value.first);
      }
    }

    displayItems.sort((a, b) {
      // Re-sort grouped items
      Ticket tA = (a is List) ? (a as List<Ticket>).first : (a as Ticket);
      Ticket tB = (b is List) ? (b as List<Ticket>).first : (b as Ticket);

      DateTime dateA = tA.bookingTime;
      dynamic depA =
          tA.tripData['departureDateTime'] ?? tA.tripData['departureTime'];
      if (depA is Timestamp) {
        dateA = depA.toDate();
      }

      DateTime dateB = tB.bookingTime;
      dynamic depB =
          tB.tripData['departureDateTime'] ?? tB.tripData['departureTime'];
      if (depB is Timestamp) {
        dateB = depB.toDate();
      }

      if (filter == TripFilter.upcoming) {
        return dateA.compareTo(dateB);
      } else {
        return dateB.compareTo(dateA);
      }
    });

    return displayItems.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bus_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                    filter == TripFilter.upcoming
                        ? "No upcoming trips"
                        : "No trips found",
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
                final item = displayItems[index];
                if (item is List<Ticket>) {
                  return _BulkBoardingPassCard(tickets: item);
                } else {
                  return _BoardingPassCard(
                    ticket: item as Ticket,
                    shouldListen: filter == TripFilter.upcoming ||
                        filter == TripFilter.delayed,
                  );
                }
              },
            ),
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
      // Determine Status
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
        statusStr = "SCHEDULED";
        statusColor = Colors.green;
      } else if (rawStatus == 'cancelled') {
        statusStr = "CANCELLED";
        statusColor = Colors.red.shade900;
      }
    } else {
      // Fallback checks
      final rawStatus =
          (tripData['status'] ?? ticket.status).toString().toLowerCase();
      if (rawStatus == 'Confirmed') {
        statusStr = "CONFIRMED";
      } else if (rawStatus == 'cancelled') {
        statusStr = "CANCELLED";
        statusColor = Colors.red.shade900;
      } else if (rawStatus == 'delayed') {
        statusStr = "DELAYED";
        statusColor = Colors.red;
      } else if (rawStatus == 'completed' || rawStatus == 'arrived') {
        statusStr = "COMPLETED";
        statusColor = Colors.green;
      } else {
        statusStr = "SCHEDULED";
        statusColor = Colors.green;
      }
    }

    final fromCity =
        tripData['fromCity'] ?? tripData['originCity'] ?? 'Unknown';
    final toCity =
        tripData['toCity'] ?? tripData['destinationCity'] ?? 'Unknown';
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(statusStr, statusColor),
                    // No Ref ID needed
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                    Column(
                      children: [
                        Icon(Icons.directions_bus,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.3),
                            size: 32),
                        if (tripData['via'] != null &&
                            tripData['via'] != 'Direct' &&
                            tripData['via'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Via ${tripData['via']}",
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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

          // Dotted Line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: 1,
              child: CustomPaint(
                painter: DashedLinePainter(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TicketScreen(
                                    ticketArg: ticket,
                                    tripArg: Trip.fromMap(
                                        tripData, ticket.tripId))));
                      },
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text("view ticket".toUpperCase(),
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor)),
                    ),
                  ),
                ),
                // Refund Button (Visible if not Cancelled/Completed/Refunded)
                // Date check removed to allow refunds on "Active" trips even if technically past departure (testing/edge cases)
                if (statusStr != 'CANCELLED' &&
                    statusStr != 'COMPLETED' &&
                    statusStr != 'ARRIVED' &&
                    statusStr != 'REFUNDED') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => RefundRequestScreen(
                                      ticket: ticket,
                                      trip: Trip.fromMap(
                                          tripData, ticket.tripId))));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text("Refund",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ]
              ],
            ),
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
                        Column(
                          children: [
                            Icon(Icons.directions_bus,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.3),
                                size: 32),
                            if (first.tripData['via'] != null &&
                                first.tripData['via'] != 'Direct' &&
                                first.tripData['via'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Via ${first.tripData['via']}",
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
