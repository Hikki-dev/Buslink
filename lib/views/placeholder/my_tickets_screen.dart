// lib/views/placeholder/my_tickets_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. ADD THIS IMPORT
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<TripController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: _user == null
          ? const Center(
              child: Text(
                'You must be logged in to see your tickets.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : StreamBuilder<List<Ticket>>(
              stream: controller.getUserTickets(_user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'You have no booked tickets.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final tickets = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    final tripData = ticket.tripData;

                    // Handle cases where tripData might be null or empty
                    if (tripData.isEmpty || tripData['departureTime'] == null) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Ticket data is incomplete for ID: ${ticket.ticketId}",
                          ),
                        ),
                      );
                    }

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${tripData['fromCity']} ➔ ${tripData['toCity']}",
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              tripData['operatorName'] ?? 'BusLink',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 20),
                            _buildTicketInfoRow(
                              theme,
                              Icons.calendar_today,
                              "Date",
                              // --- 2. 'Timestamp' IS NOW RECOGNIZED ---
                              DateFormat('EEE, MMM d, yyyy').format(
                                (tripData['departureTime'] as Timestamp)
                                    .toDate(),
                              ),
                            ),
                            _buildTicketInfoRow(
                              theme,
                              Icons.access_time,
                              "Depart",
                              // --- 3. 'Timestamp' IS NOW RECOGNIZED ---
                              DateFormat('hh:mm a').format(
                                (tripData['departureTime'] as Timestamp)
                                    .toDate(),
                              ),
                            ),
                            _buildTicketInfoRow(
                              theme,
                              Icons.event_seat,
                              "Seats",
                              ticket.seatNumbers.join(", "),
                            ),
                            _buildTicketInfoRow(
                              theme,
                              Icons.person,
                              "Passenger",
                              ticket.passengerName,
                            ),
                            _buildTicketInfoRow(
                              theme,
                              Icons.confirmation_number_outlined,
                              "Ticket ID",
                              ticket.ticketId,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildTicketInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text("$label: ", style: theme.textTheme.bodyMedium),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
