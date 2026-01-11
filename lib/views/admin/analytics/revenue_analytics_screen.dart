import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_theme.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  const RevenueAnalyticsScreen({super.key});

  @override
  State<RevenueAnalyticsScreen> createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen> {
  // Filters could be added here (e.g., date range)
  final int _daysLookback = 30;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('status', isEqualTo: 'confirmed')
          // .where('bookingTime') // Ideally filter by date range for perf
          .limit(500)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final stats = _calculateRevenue(docs);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKPIs(stats),
              const SizedBox(height: 32),
              const Text("Revenue Over Time (Last 30 Days)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildLineChartPlaceholder(stats['daily'] as Map<String, double>),
              const SizedBox(height: 32),
              const Text("Top Routes by Revenue",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildRouteTable(stats['routes'] as Map<String, double>),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calculateRevenue(List<QueryDocumentSnapshot> docs) {
    double totalRevenue = 0;
    double todayRevenue = 0;
    Map<String, double> dailyRevenue = {};
    Map<String, double> routeRevenue = {};

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final cutoff = now.subtract(Duration(days: _daysLookback));

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['totalAmount'] ?? data['price'] ?? 0);
      final double amount = (price is num) ? price.toDouble() : 0.0;

      DateTime? date;
      if (data['bookingTime'] is Timestamp) {
        date = (data['bookingTime'] as Timestamp).toDate();
      }

      if (date != null) {
        // Filter by cutoff manually since firestore compound queries are limited
        if (date.isAfter(cutoff)) {
          final dayKey = DateFormat('MM-dd').format(date);
          dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + amount;
          totalRevenue += amount;

          final docDateStr = DateFormat('yyyy-MM-dd').format(date);
          if (docDateStr == todayStr) {
            todayRevenue += amount;
          }

          // Routes
          final tripData = data['tripData'] as Map<String, dynamic>?;
          String routeKey = "Unknown";
          if (tripData != null) {
            routeKey =
                "${tripData['fromCity'] ?? '?'} - ${tripData['toCity'] ?? '?'}";
          }
          routeRevenue[routeKey] = (routeRevenue[routeKey] ?? 0) + amount;
        }
      }
    }

    // Sort Routes
    var sortedRoutes = routeRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    Map<String, double> topRoutes = {};
    for (var e in sortedRoutes.take(5)) {
      topRoutes[e.key] = e.value;
    }

    return {
      'total': totalRevenue, // In selected period
      'today': todayRevenue,
      'daily': dailyRevenue,
      'routes': topRoutes
    };
  }

  Widget _buildKPIs(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
            child: _kpiCard(
                "30-Day Revenue",
                "LKR ${(stats['total'] as double).toStringAsFixed(0)}",
                Colors.green)),
        const SizedBox(width: 16),
        Expanded(
            child: _kpiCard(
                "Today's Revenue",
                "LKR ${(stats['today'] as double).toStringAsFixed(0)}",
                Colors.blue)),
      ],
    );
  }

  Widget _kpiCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLineChartPlaceholder(Map<String, double> daily) {
    if (daily.isEmpty) {
      return Container(
          height: 200,
          color: Colors.grey.withValues(alpha: 0.1),
          child: const Center(child: Text("No Data")));
    }
    final keys = daily.keys.toList()..sort();
    final maxVal = daily.values.isNotEmpty
        ? daily.values.reduce((a, b) => a > b ? a : b)
        : 1.0;

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: keys.map((k) {
          final val = daily[k]!;
          final h = (val / maxVal) * 180;
          return Expanded(
            child: Tooltip(
              message: "$k: LKR $val",
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: h < 5 ? 5 : h,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteTable(Map<String, double> routes) {
    return Card(
      child: Column(
        children: routes.entries.map((e) {
          return ListTile(
            leading: const Icon(Icons.alt_route),
            title: Text(e.key),
            trailing: Text("LKR ${e.value.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
  }
}
