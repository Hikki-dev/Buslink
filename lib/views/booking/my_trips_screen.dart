// lib/views/booking/my_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';

class MyTripsScreen extends StatelessWidget {
  final bool showBackButton;
  const MyTripsScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final controller = Provider.of<TripController>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading:
              showBackButton ? const BackButton(color: Colors.black) : null,
          title: Text("My Trips",
              style: GoogleFonts.outfit(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "UPCOMING"),
              Tab(text: "HISTORY"),
            ],
          ),
        ),
        body: user == null
            ? _buildLoginPrompt()
            : Column(
                children: [
                  _TripStatistics(userId: user.uid),
                  Expanded(
                    child: TabBarView(
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
                ],
              ),
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
          Text("Please sign in to view your trips",
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TripStatistics extends StatelessWidget {
  final String userId;
  const _TripStatistics({required this.userId});

  @override
  Widget build(BuildContext context) {
    // We need to fetch tickets to count statuses.
    // TripController has getUserTickets(userId).
    // We can access it via Provider or new instance if needed, but Provider best.
    final controller = Provider.of<TripController>(context, listen: false);

    return StreamBuilder<List<Ticket>>(
      stream: controller.getUserTickets(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final tickets = snapshot.data!;
        int upcoming = 0;
        int delayed = 0;
        int arrived = 0;
        int cancelled = 0;

        final now = DateTime.now();

        for (var t in tickets) {
          final status =
              (t.tripData['status'] ?? 'scheduled').toString().toLowerCase();

          if (status == 'cancelled') {
            cancelled++;
            continue;
          }
          if (status == 'delayed') {
            delayed++;
          }
          if (status == 'arrived' || status == 'completed') {
            arrived++;
          }

          // Upcoming logic (Date > Now)
          DateTime? tripDate;
          if (t.tripData['departureTime'] is Timestamp) {
            tripDate = (t.tripData['departureTime'] as Timestamp).toDate();
          } else {
            tripDate = t.bookingTime;
          }

          if (tripDate.isAfter(now)) {
            upcoming++;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              _statBox("Upcoming", "$upcoming", Colors.blue, Icons.schedule),
              const SizedBox(width: 12),
              _statBox("Delayed", "$delayed", Colors.orange, Icons.timer_off),
              const SizedBox(width: 12),
              _statBox("Arrived", "$arrived", Colors.green,
                  Icons.check_circle_outline),
              const SizedBox(width: 12),
              _statBox(
                  "Cancelled", "$cancelled", Colors.red, Icons.cancel_outlined),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String label, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(count,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
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
                    style: GoogleFonts.inter(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: tickets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            return _BoardingPassCard(ticket: tickets[index]);
          },
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

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
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
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor)),
                          ),
                          Text(
                              "Ref: ${ticket.ticketId.substring(0, 8).toUpperCase()}",
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade400)),
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
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(fromCity,
                                  style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.grey),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("TO",
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(toCity,
                                  style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _infoBadge(Icons.calendar_today,
                              DateFormat('MMM d, y').format(depTime)),
                          const SizedBox(width: 16),
                          _infoBadge(Icons.chair, "$seatsCount Seats"),
                          const Spacer(),
                          Text("LKR ${ticket.totalAmount.toStringAsFixed(0)}",
                              style: GoogleFonts.outfit(
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
                                      : Colors.grey.shade200,
                                  height: 2,
                                ),
                              )),
                    ),
                    Positioned(
                        left: -10,
                        top: -10,
                        child: CircleAvatar(
                            radius: 10, backgroundColor: Colors.grey.shade50)),
                    Positioned(
                        right: -10,
                        top: -10,
                        child: CircleAvatar(
                            radius: 10, backgroundColor: Colors.grey.shade50)),
                  ],
                ),

                // Bottom Action
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text("View Ticket Details",
                          style: GoogleFonts.inter(color: Colors.black87)),
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w500, color: Colors.grey.shade700))
      ],
    );
  }
}
