import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
