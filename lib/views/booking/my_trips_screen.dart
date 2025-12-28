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

class MyTripsScreen extends StatelessWidget {
  final bool showBackButton;
  const MyTripsScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final controller = Provider.of<TripController>(context);

    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          if (isDesktop) const DesktopNavBar(selectedIndex: 1),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: showBackButton && !isDesktop
                    ? const BackButton(color: Colors.black)
                    : null,
                title: const Text("My Trips",
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                centerTitle: true,
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
      stream: controller.getUserTickets(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        var tickets = snapshot.data ?? [];
        final now = DateTime.now();

        // Safe Filtering
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
            return tripDate.isBefore(now);
          } else {
            return tripDate.isAfter(now);
          }
        }).toList();

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
                return _BoardingPassCard(ticket: tickets[index]);
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
  const _BoardingPassCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    // Listen to live trip updates for status
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .doc(ticket.tripId)
            .snapshots(),
        builder: (context, snapshot) {
          // Fallback to ticket data if loading or error
          var tripData = ticket.tripData;
          String statusStr = "SCHEDULED";
          Color statusColor = Colors.grey;

          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            // Update local vars with live data if available
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
              statusStr = "ON TIME";
              statusColor = Colors.green;
            } else if (rawStatus == 'cancelled') {
              statusStr = "CANCELLED";
              statusColor = Colors.red.shade900;
            }
          }

          final fromCity =
              tripData['fromCity'] ?? ticket.tripData['fromCity'] ?? 'Unknown';
          final toCity =
              tripData['toCity'] ?? ticket.tripData['toCity'] ?? 'Unknown';
          final seatsCount = ticket.seatNumbers.length;

          // Format live times if available, else ticket times
          DateTime depTime = ticket.bookingTime; // Fallback
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
                        children: [
                          _infoBadge(
                              Icons.calendar_today,
                              DateFormat('MMM d, y').format(depTime),
                              subTextColor),
                          const SizedBox(width: 16),
                          _infoBadge(
                              Icons.chair, "$seatsCount Seats", subTextColor),
                          const Spacer(),
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
                Stack(
                  children: [
                    Row(
                      children: List.generate(
                          40,
                          (index) => Expanded(
                                child: Container(
                                  color: index % 2 == 0
                                      ? Colors.transparent
                                      : (isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200),
                                  height: 2,
                                ),
                              )),
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
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: Text("View Ticket",
                              style: TextStyle(
                                  fontFamily: 'Inter', color: textColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Book Again Logic
                            final controller = Provider.of<TripController>(
                                context,
                                listen: false);
                            controller.setFromCity(
                                ticket.tripData['fromCity'] ?? 'Colombo');
                            controller.setToCity(
                                ticket.tripData['toCity'] ?? 'Kandy');
                            controller.setDepartureDate(DateTime.now());
                            controller.searchTrips(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BusListScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text("Book Again",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
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
