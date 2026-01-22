import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/trip_model.dart';

class TripsStatsWidget extends StatelessWidget {
  final List<Ticket> allTickets;
  const TripsStatsWidget({super.key, required this.allTickets});

  @override
  Widget build(BuildContext context) {
    int upcoming = 0;
    int arrived = 0;
    int delayed = 0;
    int cancelled = 0;
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 12));

    for (var t in allTickets) {
      dynamic dep = t.tripData['departureTime'];
      DateTime tripDate = t.bookingTime;
      if (dep is Timestamp) tripDate = dep.toDate();
      if (dep is String) tripDate = DateTime.tryParse(dep) ?? t.bookingTime;

      final status = (t.tripData['status'] ?? 'scheduled').toLowerCase();

      // Count strict status first
      if (status == 'cancelled') {
        cancelled++;
      } else if (status == 'arrived' || status == 'completed') {
        arrived++;
      } else if (status == 'delayed' || (t.tripData['delayMinutes'] ?? 0) > 0) {
        delayed++;
      }

      // Upcoming count logic
      if (tripDate.isAfter(cutoff) &&
          status != 'cancelled' &&
          status != 'arrived' &&
          status != 'completed') {
        upcoming++;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBox(context, "Upcoming", "$upcoming", Colors.blue),
          const SizedBox(width: 8),
          _buildBox(context, "Delayed", "$delayed", Colors.orange),
          const SizedBox(width: 8),
          _buildBox(context, "Arrived", "$arrived", Colors.green),
          const SizedBox(width: 8),
          _buildBox(context, 'Cancelled', "$cancelled", Colors.red),
        ],
      ),
    );
  }

  Widget _buildBox(
      BuildContext context, String label, String count, Color color) {
    return Container(
      width: 100, // Fixed width
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        children: [
          Text(count,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)
        ],
      ),
    );
  }
}
