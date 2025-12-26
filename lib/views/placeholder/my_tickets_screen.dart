// lib/views/placeholder/my_tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_model.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- STATIC DATA ---
    final List<Ticket> staticTickets = [
      Ticket(
        ticketId: "TKT-8859-STATIC",
        tripId: "TRIP-001",
        userId: "static_user",
        seatNumbers: [12, 13],
        passengerName: "John Doe",
        passengerPhone: "0771234567",
        bookingTime: DateTime.now().subtract(const Duration(days: 2)),
        totalAmount: 3000.0,
        tripData: {
          'fromCity': 'Colombo',
          'toCity': 'Kandy',
          'operatorName': 'SuperLine Express',
          'busNumber': 'NP-1234',
          'departureTime': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 1, hours: 4))),
          'arrivalTime': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 1, hours: 7))),
        },
      ),
      Ticket(
        ticketId: "TKT-9921-STATIC",
        tripId: "TRIP-002",
        userId: "static_user",
        seatNumbers: [5],
        passengerName: "John Doe",
        passengerPhone: "0771234567",
        bookingTime: DateTime.now().subtract(const Duration(days: 10)),
        totalAmount: 1500.0,
        tripData: {
          'fromCity': 'Galle',
          'toCity': 'Matara',
          'operatorName': 'Southern Star',
          'busNumber': 'SP-5678',
          'departureTime': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5))),
          'arrivalTime': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5, minutes: -45))),
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets (Static)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: staticTickets.length,
        itemBuilder: (context, index) {
          final ticket = staticTickets[index];
          final tripData = ticket.tripData;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${tripData['fromCity']} ➔ ${tripData['toCity']}",
                        style: theme.textTheme.titleLarge,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Confirmed",
                          style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    DateFormat('EEE, MMM d, yyyy').format(
                      (tripData['departureTime'] as Timestamp).toDate(),
                    ),
                  ),
                  _buildTicketInfoRow(
                    theme,
                    Icons.access_time,
                    "Depart",
                    DateFormat('hh:mm a').format(
                      (tripData['departureTime'] as Timestamp).toDate(),
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
