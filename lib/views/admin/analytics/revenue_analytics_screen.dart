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
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // DATE FILTER HEADER
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              const Icon(Icons.date_range),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                  onPressed: _pickDateRange, child: const Text("Refine Date"))
            ],
          ),
        ),
        const Divider(height: 1),

        // ANALYTICS BODY
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tickets')
                .where('status', isEqualTo: 'confirmed')
                .snapshots(),
            builder: (context, ticketSnap) {
              if (!ticketSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // NESTED STREAM FOR REFUNDS
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('refunds')
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, refundSnap) {
                  if (!refundSnap.hasData) {
                    return const SizedBox(); // Wait for both
                  }

                  final tickets = ticketSnap.data!.docs;
                  final refunds = refundSnap.data!.docs;
                  final stats = _calculateNetRevenue(tickets, refunds);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKPIs(stats),
                        const SizedBox(height: 32),
                        const Text("Net Revenue Over Time",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildLineChartPlaceholder(
                            stats['daily'] as Map<String, double>),
                        const SizedBox(height: 32),
                        const Text("Top Routes by Net Revenue",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildRouteTable(
                            stats['routes'] as Map<String, double>),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Map<String, dynamic> _calculateNetRevenue(List<QueryDocumentSnapshot> tickets,
      List<QueryDocumentSnapshot> refunds) {
    double totalRevenue = 0;
    double todayRevenue = 0;
    Map<String, double> dailyRevenue = {};
    Map<String, double> routeRevenue = {};

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Process Tickets (Gross Revenue)
    for (var doc in tickets) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['totalAmount'] ?? data['price'] ?? 0);
      final double amount = (price is num) ? price.toDouble() : 0.0;

      DateTime? date;
      if (data['departureTime'] is Timestamp) {
        date = (data['departureTime'] as Timestamp).toDate();
      } else if (data['bookingTime'] is Timestamp) {
        date = (data['bookingTime'] as Timestamp).toDate();
      }

      if (date != null &&
          date.isAfter(_startDate) &&
          date.isBefore(_endDate.add(const Duration(days: 1)))) {
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

    // 2. Process Refunds (Deductions)
    for (var doc in refunds) {
      final data = doc.data() as Map<String, dynamic>;
      final refundAmount = (data['refundAmount'] ?? 0).toDouble();

      // Use requestedAt or updatedAt for the refund date deduction
      DateTime? date;
      if (data['updatedAt'] is Timestamp) {
        date = (data['updatedAt'] as Timestamp).toDate();
      }

      if (date != null &&
          date.isAfter(_startDate) &&
          date.isBefore(_endDate.add(const Duration(days: 1)))) {
        final dayKey = DateFormat('MM-dd').format(date);
        // Subtract from daily revenue
        dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) - refundAmount;
        totalRevenue -= refundAmount;

        final docDateStr = DateFormat('yyyy-MM-dd').format(date);
        if (docDateStr == todayStr) {
          todayRevenue -= refundAmount;
        }

        // Note: Connecting refund to route requires tripId lookup or storing route in refund.
        // We will skip route deduction for simplicity unless refund has route info,
        // to avoid "Unknown" negative spikes.
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
      'total': totalRevenue,
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
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold)), // Increased
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
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteTable(Map<String, double> routes) {
    if (routes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("No route data available")),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: routes.entries.map((e) {
            final parts = e.key.split(" - ");
            final from =
                parts.isNotEmpty && parts[0] != "?" ? parts[0] : "Unknown";
            final to =
                parts.length > 1 && parts[1] != "?" ? parts[1] : "Location";

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.fork_right),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text("$from - $to",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  Text("LKR ${e.value.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
