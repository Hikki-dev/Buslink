import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LateDeparturesDashboard extends StatefulWidget {
  const LateDeparturesDashboard({super.key});

  @override
  State<LateDeparturesDashboard> createState() =>
      _LateDeparturesDashboardState();
}

class _LateDeparturesDashboardState extends State<LateDeparturesDashboard> {
  String? _selectedRoute;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Map<String, int> _stats = {
    'total': 0,
    'onTime': 0,
    'late': 0,
    'lateRate': 0, // Percentage
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      // Build Query
      Query query = FirebaseFirestore.instance.collection('trips');

      // Filter by Month (Client side filtering mostly as Firestore range + equality on other fields is complex)
      // Or we can query by date range if we have an index.
      // Let's fetch last 500 trips and filter.
      // Limit to avoid excessive reads.
      final snapshot = await query
          .orderBy('departureTime', descending: true)
          .limit(500)
          .get();

      int total = 0;
      int onTime = 0;
      int late = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Date Filter
        DateTime? depTime;
        if (data['departureTime'] is Timestamp) {
          depTime = (data['departureTime'] as Timestamp).toDate();
        } else if (data['departureTime'] is String) {
          depTime = DateTime.tryParse(data['departureTime']);
        }

        if (depTime == null) continue;

        // Filter by Specific Day
        if (depTime.year != _selectedDate.year ||
            depTime.month != _selectedDate.month ||
            depTime.day != _selectedDate.day) {
          continue;
        }

        // Route Filter (Search Text)
        if (_selectedRoute != null && _selectedRoute!.isNotEmpty) {
          final query = _selectedRoute!.toLowerCase();
          final routeStr =
              "${data['fromCity']} - ${data['toCity']}".toLowerCase();
          final fromCity = (data['fromCity'] ?? '').toString().toLowerCase();
          final toCity = (data['toCity'] ?? '').toString().toLowerCase();

          // Fuzzy search: Match "from - to" OR individual cities
          if (!routeStr.contains(query) &&
              !fromCity.contains(query) &&
              !toCity.contains(query)) {
            continue;
          }
        }

        total++;
        // Check Status
        final status = (data['status'] ?? '').toString().toLowerCase();
        final delay = (data['delayMinutes'] ?? 0) as int;

        if (status == 'delayed' || delay > 0) {
          late++;
        } else if (status == 'completed' ||
            status == 'arrived' ||
            status == 'on time') {
          onTime++;
        }
      }

      setState(() {
        _stats = {
          'total': total,
          'onTime': onTime,
          'late': late,
          'lateRate': total > 0 ? ((late / total) * 100).round() : 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching late stats: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Late Departures Analytics"),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Controls Row
            Row(
              children: [
                // Route Search Field (Replaces Dropdown)
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Search Route (e.g. Colombo)",
                      hintText: "Enter Origin or Destination",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                    ),
                    onChanged: (val) {
                      setState(() => _selectedRoute = val);
                      _fetchStats();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Date Selector (Specific Day)
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2030));
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _fetchStats();
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                          labelText: "Date",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          suffixIcon: const Icon(Icons.calendar_today)),
                      child:
                          Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  // KPI Boxes
                  Row(
                    children: [
                      _buildKPIBox("Total Analysis", "${_stats['total']} Trips",
                          Colors.blue),
                      const SizedBox(width: 16),
                      _buildKPIBox("Late Rate", "${_stats['lateRate']}%",
                          _stats['lateRate']! > 20 ? Colors.red : Colors.green),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Label + Pie Chart
                  const Text("On-time vs Late Performance",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 250,
                    width: 250,
                    child: CustomPaint(
                      painter: PieChartPainter(
                        onTime: _stats['onTime']!,
                        lateCount: _stats['late']!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem("On Time", Colors.green),
                      const SizedBox(width: 24),
                      _legendItem("Late / Delayed", Colors.red),
                    ],
                  )
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildKPIBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(12)),
              child: Text(color == Colors.red ? "Needs Attention" : "Healthy",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600))
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final int onTime;
  final int lateCount;

  PieChartPainter({required this.onTime, required this.lateCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final total = onTime + lateCount;

    if (total == 0) {
      final paint = Paint()..color = Colors.grey.shade200;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final onTimeSweep = (onTime / total) * 2 * pi;
    final lateSweep = (lateCount / total) * 2 * pi;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw OnTime Arc
    final paintOnTime = Paint()..color = Colors.green;
    canvas.drawArc(rect, -pi / 2, onTimeSweep, true, paintOnTime);

    // Draw Late Arc
    final paintLate = Paint()..color = Colors.red;
    canvas.drawArc(rect, -pi / 2 + onTimeSweep, lateSweep, true, paintLate);

    // Draw Center Hole (Donut)
    final holeRadius = radius * 0.6;
    final holePaint = Paint()
      ..color = Colors.white; // Should match scaffold background
    canvas.drawCircle(center, holeRadius, holePaint);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.onTime != onTime || oldDelegate.lateCount != lateCount;
  }
}
