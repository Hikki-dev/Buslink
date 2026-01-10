import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';

class AdminAnalyticsDashboard extends StatelessWidget {
  const AdminAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Analytics Dashboard"),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 1,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: "PUNCTUALITY"),
              Tab(text: "REVENUE"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LateDeparturesView(),
            RevenueView(),
          ],
        ),
      ),
    );
  }
}

class LateDeparturesView extends StatelessWidget {
  const LateDeparturesView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('trips').limit(100).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final stats = _calculateStats(docs);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(context, stats),
              const SizedBox(height: 32),
              const Text("Punctuality Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPieChartPlaceholder(stats),
              const SizedBox(height: 32),
              const Text("Recent Late Departures",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildLateTripsList(stats['lateTrips']),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) {
    int total = docs.length;
    int onTime = 0;
    int late = 0;
    List<Map<String, dynamic>> lateTrips = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final int delay = (data['delayMinutes'] ?? 0).toInt();
      // Safe timestamp conversion
      final DateTime date =
          (data['departureDateTime'] as Timestamp?)?.toDate() ?? DateTime.now();

      if (delay > 15) {
        late++;
        lateTrips.add({
          'route':
              "${data['originCity'] ?? '?'} - ${data['destinationCity'] ?? '?'}",
          'delay': delay,
          'date': date,
          'bus': data['busNumber'] ?? 'Bus'
        });
      } else {
        onTime++;
      }
    }
    lateTrips.sort((a, b) => b['delay'].compareTo(a['delay']));
    return {
      'total': total,
      'onTime': onTime,
      'late': late,
      'lateTrips': lateTrips
    };
  }

  Widget _buildSummaryCards(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
            child: _statCard(context, "Total Trips", "${stats['total']}",
                Icons.directions_bus, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(
            child: _statCard(context, "Late Departures", "${stats['late']}",
                Icons.warning, Colors.red)),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Text(label,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPieChartPlaceholder(Map<String, dynamic> stats) {
    final total = stats['total'] == 0 ? 1 : stats['total'];
    final onTimeVal = (stats['onTime'] as num).toDouble();
    final lateVal = (stats['late'] as num).toDouble();
    final totalVal = total.toDouble();

    final onTimePct = (onTimeVal / totalVal);
    final latePct = (lateVal / totalVal);

    return Container(
      height: 40,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: Colors.grey.shade200),
      child: Row(
        children: [
          Expanded(
            flex: ((onTimePct * 100).toInt() <= 0)
                ? 1
                : (onTimePct * 100).toInt(),
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(20))),
              child: Center(
                  child: Text(
                      "${(onTimePct * 100).toStringAsFixed(1)}% On Time",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
            ),
          ),
          Expanded(
            flex: ((latePct * 100).toInt() <= 0) ? 0 : (latePct * 100).toInt(),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(latePct > 0 ? 20 : 0))),
              child: ((latePct * 100).toInt() <= 0)
                  ? const SizedBox()
                  : Center(
                      child: Text("${(latePct * 100).toStringAsFixed(1)}% Late",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLateTripsList(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty)
      return const Text("No recent late departures.",
          style: TextStyle(color: Colors.black87));
    return Column(
      children: trips.take(5).map((t) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: Text("Route: ${t['route']}"),
            subtitle: Text("Bus: ${t['bus']}"),
            trailing: Text("+${t['delay']} min",
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
}

class RevenueView extends StatelessWidget {
  const RevenueView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('status', isEqualTo: 'confirmed')
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
              _buildRevenueCard(stats['total']),
              const SizedBox(height: 32),
              const Text("Revenue Trend",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBarChart(context, stats['monthly']),
              const SizedBox(height: 32),
              const Text("Top Routes by Revenue",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildRoutePerformance(context, stats['routes']),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calculateRevenue(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    Map<String, double> monthly = {};
    Map<String, double> routes = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['totalAmount'] ?? data['price'] ?? 0);
      final double amount = (price is num) ? price.toDouble() : 0.0;
      total += amount;

      Timestamp? ts = data['bookingTime'] as Timestamp?;
      if (ts != null) {
        final date = ts.toDate();
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
        monthly[key] = (monthly[key] ?? 0) + amount;
      }

      final tripData = data['tripData'] as Map<String, dynamic>?;
      String routeKey = "Unknown Route";
      if (tripData != null) {
        routeKey =
            "${tripData['originCity'] ?? '?'} - ${tripData['destinationCity'] ?? '?'}";
      }
      routes[routeKey] = (routes[routeKey] ?? 0) + amount;
    }

    var sortedRoutes = routes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Map<String, double> topRoutes = {};
    for (var entry in sortedRoutes.take(5)) {
      topRoutes[entry.key] = entry.value;
    }

    return {'total': total, 'monthly': monthly, 'routes': topRoutes};
  }

  Widget _buildRevenueCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor,
          AppTheme.primaryColor.withValues(alpha: 0.7)
        ]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Revenue",
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text("LKR ${total.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, Map<String, double> monthly) {
    if (monthly.isEmpty) return const SizedBox();
    final maxVal = monthly.values.reduce((a, b) => a > b ? a : b);
    final sortedKeys = monthly.keys.toList()..sort();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedKeys.map((key) {
          final val = monthly[key] ?? 0;
          final h = (val / maxVal) * 150;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: h,
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 8),
              Text(key.substring(5), style: const TextStyle(fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoutePerformance(
      BuildContext context, Map<String, double> routes) {
    if (routes.isEmpty) return const Text("No route data available.");

    return Column(
      children: routes.entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              const Icon(Icons.alt_route, color: Colors.blueGrey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.key,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text("LKR ${e.value.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green))
            ],
          ),
        );
      }).toList(),
    );
  }
}
