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
                  onPressed: _pickDateRange,
                  child: const Text('Refine Date')), // Fixed Text
              // Quick Select
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune),
                tooltip: "Quick Select",
                onSelected: (val) {
                  DateTime now = DateTime.now();
                  DateTime start = now;
                  DateTime end = now;

                  if (val == '7') {
                    start = now.subtract(const Duration(days: 7));
                  } else if (val == '30') {
                    start = now.subtract(const Duration(days: 30));
                  } else if (val == 'month') {
                    start = DateTime(now.year, now.month, 1);
                    end = DateTime(now.year, now.month + 1, 0);
                  }
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                  });
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: '7', child: Text('Last 7 Days')), // Fixed Text
                  PopupMenuItem(
                      value: '30', child: Text('Last 30 Days')), // Fixed Text
                  PopupMenuItem(
                      value: 'month', child: Text('This Month')), // Fixed Text
                ],
              )
            ],
          ),
        ),
        const Divider(height: 1),

        // ANALYTICS BODY
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tickets')
                .where('status', whereIn: [
              'Confirmed',
              'COMPLETED',
              'ARRIVED',
              'DELAYED',
              'ON_TIME',
              'confirmed', // Lowercase fallback
              'completed',
              'arrived',
              'delayed',
              'onTime',
              'on_time'
            ]).snapshots(),
            builder: (context, ticketSnap) {
              if (!ticketSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // NESTED STREAM FOR REFUNDS
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('refunds') // Fixed casing
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, refundSnap) {
                  // Allow building even if refunds are loading or empty
                  final tickets = ticketSnap.data!.docs;
                  List<QueryDocumentSnapshot> refunds = [];
                  if (refundSnap.hasData) {
                    refunds = refundSnap.data!.docs;
                  }

                  final stats = _calculateNetRevenue(tickets, refunds);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKPIs(stats),
                        const SizedBox(height: 32),
                        const Text('Net Revenue Over Time', // Fixed
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildScatterChart(
                            stats['daily'] as Map<String, double>),
                        const SizedBox(height: 32),
                        const Text('Top Routes by Net Revenue', // Fixed
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
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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
        // Helper closure since we are in a method
        String getString(Map? m, List<String> keys) {
          if (m == null) return '';
          for (var k in keys) {
            if (m[k] != null &&
                m[k].toString().isNotEmpty &&
                m[k].toString() != 'N/A') return m[k].toString();
          }
          return '';
        }

        final tripData = data['tripData'] as Map<String, dynamic>?;

        // Robust Lookup
        final outputKeys = [
          'fromCity',
          'originCity',
          'origin',
          'from',
          'FromCity',
          'OriginCity',
          'source'
        ];
        final destKeys = [
          'toCity',
          'destinationCity',
          'destination',
          'to',
          'ToCity',
          'DestinationCity',
          'dest'
        ];

        String from = getString(tripData, outputKeys);
        if (from.isEmpty) from = getString(data, outputKeys);
        if (from.isEmpty) from = '?';

        String to = getString(tripData, destKeys);
        if (to.isEmpty) to = getString(data, destKeys);
        if (to.isEmpty) to = '?';

        String routeKey = "$from - $to";

        // ALLOW ALL ROUTES (Even if Unknown)
        // This ensures the "Net Revenue" matches what is shown in the table.
        if (from != '?' && to != '?') {
          routeRevenue[routeKey] = (routeRevenue[routeKey] ?? 0) + amount;
        }
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
                'Net Revenue (30d)', // Fixed
                "LKR ${(stats['total'] as double).toStringAsFixed(0)}",
                Colors.green)),
        const SizedBox(width: 16),
        Expanded(
            child: _kpiCard(
                'Net Revenue (Today)', // Fixed
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

  Widget _buildScatterChart(Map<String, double> daily) {
    if (daily.isEmpty) {
      return Container(
          height: 200,
          color: Colors.grey.withValues(alpha: 0.1),
          child: const Center(
              child: Text('No revenue data for this period'))); // Fixed
    }
    final keys = daily.keys.toList()..sort();
    double maxVal = daily.values.isNotEmpty
        ? daily.values.reduce((a, b) => a > b ? a : b)
        : 1.0;
    double minVal = daily.values.isNotEmpty
        ? daily.values.reduce((a, b) => a < b ? a : b)
        : 0.0;

    // Normalize Range
    if (maxVal < 0) maxVal = 0; // If all are negative, max is 0 (baseline)
    if (minVal > 0) minVal = 0; // If all positive, min is 0 (baseline)

    double range = maxVal - minVal;
    if (range == 0) range = 1000; // Prevent div/0

    return SizedBox(
      height: 250,
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Padding for axes
        const double xStart = 0;
        const double yBottom = 20;
        final double plotW = w - xStart;
        final double plotH = h - yBottom;

        // Calculate zero line position (ratio from bottom)
        // val = min + (ratio * range)  => ratio = (val - min) / range
        // zeroRatio = (0 - min) / range
        double zeroRatio = (0 - minVal) / range;
        double zeroY = yBottom + (zeroRatio * plotH);

        return Stack(
          children: [
            // Zero Line (if visible)
            Positioned(
              bottom: zeroY,
              left: xStart,
              right: 0,
              child: Container(
                  height: 2, color: Colors.grey.withValues(alpha: 0.3)),
            ),

            // Dots
            ...List.generate(keys.length, (index) {
              final k = keys[index];
              final val = daily[k]!;

              // X Position: Index based distribution
              final double x = xStart +
                  (index / (keys.length > 1 ? keys.length - 1 : 1)) *
                      (plotW - 20) +
                  10;

              // Y Position: Relative to Range
              final double ratio = (val - minVal) / range;
              final double y = yBottom + (ratio * plotH);

              return Positioned(
                bottom: y,
                left: x - 6, // Centered
                child: Tooltip(
                  message: "$k: LKR ${val.toStringAsFixed(0)}",
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: val >= 0 ? AppTheme.primaryColor : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: (val >= 0 ? AppTheme.primaryColor : Colors.red)
                              .withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                ),
              );
            }),

            // X Axis Labels (Sampled)
            Positioned(
              bottom: 0,
              left: xStart,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(keys.length, (index) {
                  // Show label if it's start, end, or every 4th/5th depending on count
                  int step = (keys.length / 5).ceil();
                  if (step < 1) step = 1;

                  if (index % step == 0 || index == keys.length - 1) {
                    return Text(keys[index],
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey));
                  }
                  return const SizedBox.shrink();
                }),
              ),
            )
          ],
        );
      }),
    );
  }

  Widget _buildRouteTable(Map<String, double> routes) {
    if (routes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No route data available')), // Fixed
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
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
