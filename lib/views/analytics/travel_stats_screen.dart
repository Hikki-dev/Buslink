import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class TravelStatsScreen extends StatefulWidget {
  const TravelStatsScreen({super.key});

  @override
  State<TravelStatsScreen> createState() => _TravelStatsScreenState();
}

class _TravelStatsScreenState extends State<TravelStatsScreen> {
  // Simple time filter: current year by default
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Stats"),
        elevation: 1,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: user.uid)
            .where('status',
                isEqualTo: 'completed') // Only completed trips count
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;
          final stats = _calculateStats(docs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(stats),
                const SizedBox(height: 24),
                _buildTrendsAccordion(stats),
                const SizedBox(height: 16),
                _buildInsightsAccordion(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.query_stats, size: 80),
          const SizedBox(height: 16),
          const Text("No travel history yet!", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Complete a trip to see your stats.", style: TextStyle()),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) {
    int totalTrips = docs.length;
    double totalSpent = 0;
    Map<String, int> citiesVisited = {};
    Map<int, int> monthlyTrips = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      // Amount
      final amt = (data['totalAmount'] ?? data['price'] ?? 0);
      totalSpent += (amt is num) ? amt.toDouble() : 0.0;

      // City
      final dest = data['toCity'] ?? data['destination'] ?? 'Unknown';
      citiesVisited[dest] = (citiesVisited[dest] ?? 0) + 1;

      // Date
      DateTime? date;
      if (data['departureTime'] is Timestamp) {
        date = (data['departureTime'] as Timestamp).toDate();
      } else if (data['bookingTime'] is Timestamp) {
        date = (data['bookingTime'] as Timestamp).toDate();
      }

      if (date != null && date.year == _focusedDate.year) {
        monthlyTrips[date.month] = (monthlyTrips[date.month] ?? 0) + 1;
      }
    }

    // Most visited
    String favoriteDest = "N/A";
    if (citiesVisited.isNotEmpty) {
      var sorted = citiesVisited.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      favoriteDest = sorted.first.key;
    }

    return {
      'totalTrips': totalTrips,
      'totalSpent': totalSpent,
      'favoriteDest': favoriteDest,
      'monthlyTrips': monthlyTrips,
      'year': _focusedDate.year
    };
  }

  Widget _buildHeader(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor,
          AppTheme.primaryColor.withValues(alpha: 0.8)
        ]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total Spent",
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text("LKR ${stats['totalSpent'].toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child: const Icon(Icons.wallet, color: Colors.white, size: 28),
          )
        ],
      ),
    );
  }

  Widget _buildTrendsAccordion(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: const Text("Travel Trends",
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.trending_up, color: AppTheme.primaryColor),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          onPressed: () {
                            setState(() {
                              _focusedDate = DateTime(_focusedDate.year - 1);
                            });
                          },
                          icon: const Icon(Icons.chevron_left)),
                      Text("${_focusedDate.year}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              _focusedDate = DateTime(_focusedDate.year + 1);
                            });
                          },
                          icon: const Icon(Icons.chevron_right)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150,
                    child: _SimpleScatterChart(
                        data: stats['monthlyTrips'] as Map<int, int>),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsAccordion(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: const Text("Insights",
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.lightbulb, color: Colors.amber),
          children: [
            _insightRow(
                Icons.place, "Favorite Destination", stats['favoriteDest']),
            _insightRow(Icons.directions_bus, "Total Trips Completed",
                "${stats['totalTrips']}"),
          ],
        ),
      ),
    );
  }

  Widget _insightRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

class _SimpleScatterChart extends StatelessWidget {
  final Map<int, int> data;
  const _SimpleScatterChart({required this.data});

  @override
  Widget build(BuildContext context) {
    int maxVal = 0;
    if (data.isNotEmpty) {
      maxVal = data.values.reduce((a, b) => a > b ? a : b);
    }
    if (maxVal == 0) maxVal = 1;

    // Use LayoutBuilder to get width
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        return Stack(
          children: [
            // Grid Lines (Horizontal)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                return Container(
                  height: 1,
                  color: Colors.grey.withOpacity(0.1),
                );
              }),
            ),
            // Scatter Points
            ...List.generate(12, (index) {
              final month = index + 1;
              final count = data[month] ?? 0;
              if (count == 0) return const SizedBox.shrink();

              // X position: distributed evenly
              final double x = (index / 11) * (w - 20) + 10;
              // Y position: count / maxVal * height (inverted for Stack bottom alignment, but using bottom prop)
              final double bottom = (count / maxVal) * (h - 20);

              return Positioned(
                left: x - 6, // center the dot
                bottom: bottom,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "${DateFormat('MMMM').format(DateTime(2024, month))}: $count trips"),
                        duration: const Duration(seconds: 1)));
                  },
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 2)
                      ],
                    ),
                  ),
                ),
              );
            }),
            // X-Axis Labels
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    // Show every 2 months
                    final m = index * 2 + 1;
                    return Text(DateFormat('MMM').format(DateTime(2024, m)),
                        style: TextStyle(fontSize: 10, color: Colors.grey));
                  }),
                ))
          ],
        );
      },
    );
  }
}
