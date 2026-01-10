import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_theme.dart';
import '../refunds/admin_refund_list.dart'; // Import for navigation

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;

  const BookingDetailsScreen(
      {super.key, required this.data, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    // Extract data safely
    final passengerName = data['passengerName'] ?? data['userName'] ?? 'N/A';
    final passengerId = data['userId'] ?? 'N/A';
    final route =
        "${data['fromCity'] ?? data['origin']} ➔ ${data['toCity'] ?? data['destination']}";
    final tripId = data['tripId'] ?? 'N/A';
    final status = (data['status'] ?? 'unknown').toString().toUpperCase();
    final paymentStatus = (data['paymentStatus'] ?? 'Paid')
        .toString()
        .toUpperCase(); // Infer paid
    final price = data['totalAmount'] ?? data['price'] ?? 0;

    // Safely parse date
    String dateStr = 'N/A';
    if (data['departureTime'] != null) {
      final dt = (data['departureTime'] as Timestamp).toDate();
      dateStr = DateFormat('MMM d, yyyy h:mm a').format(dt);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Passenger Info"),
            _buildInfoRow("Name", passengerName),
            _buildInfoRow("User ID", passengerId),
            const SizedBox(height: 24),
            _buildSectionHeader("Trip Info"),
            _buildInfoRow("Booking ID", bookingId),
            _buildInfoRow("Trip ID", tripId),
            _buildInfoRow("Route", route),
            _buildInfoRow("Date & Time", dateStr),
            _buildInfoRow("Status", status),
            const SizedBox(height: 24),
            _buildSectionHeader("Payment Summary"),
            _buildInfoRow("Amount", "LKR $price"),
            _buildInfoRow("Payment Status", paymentStatus),
            if (data['paymentIntentId'] != null)
              _buildInfoRow("Stripe Ref", data['paymentIntentId']),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Refund Management
                  // We can pass arguments if needed, or just let them search
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminRefundListScreen()));
                },
                icon: const Icon(Icons.currency_exchange),
                label: const Text("Go to Refund Management"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
