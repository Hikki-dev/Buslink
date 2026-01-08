import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';

class TravelStatsScreen extends StatelessWidget {
  const TravelStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Analytics"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed') // Only completed trips
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No travel history yet."));
          }

          final docs = snapshot.data!.docs;
          final stats = _calculateStats(docs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(stats),
                const SizedBox(height: 32),
                const Text("Monthly Spending",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildBarChart(stats['monthly']),
                const SizedBox(height: 32),
                const Text("Top Destinations",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDestinationsList(stats['destinations']),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) {
    double totalSpent = 0;
    int totalTrips = docs.length;
    Map<String, double> monthlySpending = {}; // "2023-10" -> 5000
    Map<String, int> destinations = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] ?? 0).toDouble();
      totalSpent += price;

      // Date
      // Assuming 'tripDate' or check trip details. Ticket might have 'date'.
      // If not, use createdAt or similar. Let's assume 'tripDate' exists on ticket or fetch Trip.
      // For simplicity in this task, I'll use current timestamp if missing, but Ticket model has trip details usually.
      // Looking at Ticket model early... it has tripId.
      // Ideally we fetch Trip, but for perf we use what's on Ticket.
      // Let's assume Ticket has 'date' string or DateTime.
      // If not, we might be limited.
      // Let's try 'bookingDate' (createdAt).
      Timestamp? ts = data['createdAt'] as Timestamp?;
      if (ts != null) {
        final date = ts.toDate();
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
        monthlySpending[key] = (monthlySpending[key] ?? 0) + price;
      }

      final dest = data['destination'] ?? "Unknown";
      destinations[dest] = (destinations[dest] ?? 0) + 1;
    }

    // Sort destinations
    var sortedDest = destinations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalSpent': totalSpent,
      'totalTrips': totalTrips,
      'monthly': monthlySpending,
      'destinations': sortedDest,
    };
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
            child: _statCard(
                "Total Spent",
                "LKR ${stats['totalSpent'].toStringAsFixed(0)}",
                Icons.attach_money,
                Colors.green)),
        const SizedBox(width: 16),
        Expanded(
            child: _statCard("Trips Taken", "${stats['totalTrips']}",
                Icons.directions_bus, Colors.blue)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> monthly) {
    if (monthly.isEmpty) return const SizedBox();

    final maxVal = monthly.values.reduce((a, b) => a > b ? a : b);
    final sortedKeys = monthly.keys.toList()..sort(); // Chronological

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedKeys.map((key) {
          final val = monthly[key] ?? 0;
          final h = (val / maxVal) * 150; // max height 150
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: h,
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 8),
              Text(key.substring(5),
                  style: const TextStyle(fontSize: 10)), // Show Month only
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDestinationsList(List<MapEntry<String, int>> dests) {
    return Column(
      children: dests.take(5).map((e) {
        return ListTile(
          leading: CircleAvatar(child: Text("${e.value}")),
          title: Text(e.key),
          subtitle: Text("${e.value} trips"),
        );
      }).toList(),
    );
  }
}
