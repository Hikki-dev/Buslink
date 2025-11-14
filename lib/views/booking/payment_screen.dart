// lib/views/booking/payment_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../ticket/ticket_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final user = Provider.of<User?>(context, listen: false);
    final theme = Theme.of(context);
    final trip = controller.selectedTrip!;
    final seats = controller.selectedSeats;
    final totalAmount = (trip.price * seats.length).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Booking',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(
                theme, 'Route:', '${trip.fromCity} to ${trip.toCity}'),
            _buildSummaryRow(
                theme, 'Bus:', '${trip.operatorName} (${trip.busNumber})'),
            _buildSummaryRow(theme, 'Seats:', seats.join(', ')),
            const Divider(height: 30),
            _buildSummaryRow(
                theme, 'Ticket Price:', 'LKR ${trip.price.toStringAsFixed(0)}'),
            _buildSummaryRow(theme, 'Quantity:', '${seats.length}'),
            const Divider(height: 30),
            DefaultTextStyle(
              style: theme.textTheme.headlineSmall!,
              child:
                  _buildSummaryRow(theme, 'Total Amount:', 'LKR $totalAmount'),
            ),
            const Spacer(),

            // This simulates the "choose visa or master" step
            const Text(
                'This is a placeholder for the payment gateway. Click "Pay Now" to simulate a successful payment and receive your ticket.'),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: theme.elevatedButtonTheme.style?.copyWith(
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16)),
                ),
                child: controller.isLoading
                    ? const CircularProgressIndicator()
                    : Text('Pay LKR $totalAmount Now'),
                onPressed: () async {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Error: You are not logged in.")),
                    );
                    return;
                  }

                  // This is where the real payment logic would go.
                  // For now, we just process the booking.
                  bool success = await controller.processBooking(context, user);

                  if (success && context.mounted) {
                    // Navigate to QR Code Screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TicketScreen(),
                      ),
                      (r) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
