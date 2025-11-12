// lib/views/ticket/ticket_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
// FIX: Import the new TripController
import '../../controllers/trip_controller.dart';
import '../home/home_screen.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: Use the new TripController
    final controller = Provider.of<TripController>(context);
    // FIX: Use selectedTrip and currentTicket
    final trip = controller.selectedTrip!;
    final ticket = controller.currentTicket!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (r) => false,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                Text(
                  "Booking Confirmed!",
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),

                // BL-06: QR Code
                QrImageView(
                  data: ticket.ticketId, // Use the ticket ID for the QR
                  size: 180,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  "Ticket ID: ${ticket.ticketId}",
                  style: theme.textTheme.bodyMedium,
                ),

                const Divider(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bus Number",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(trip.busNumber, style: theme.textTheme.titleLarge),
                      ],
                    ),
                    // BL-13: Platform (Dynamic)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Platform",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          trip.platformNumber,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _row(theme, "Route", "${trip.fromCity} ➔ ${trip.toCity}"),
                _row(theme, "Seats", ticket.seatNumbers.join(", ")),
                _row(theme, "Passenger", ticket.passengerName),

                const SizedBox(height: 20),
                const Text(
                  "Show this QR code to the conductor.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(val, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
