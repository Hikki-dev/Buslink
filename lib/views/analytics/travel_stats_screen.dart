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
    // Hardcoded language code to English
    const languageCode = 'en';

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Travel Trends'),
        elevation: 1,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: user.uid)
            // Removed status filter to get ALL trips for stats
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(languageCode);
          }

          final docs = snapshot.data!.docs;
          final stats = _calculateStats(docs);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NEW: Status Boxes
                Row(
                  children: [
                    _statusBox(context, 'Upcoming', "${stats['Upcoming']}",
                        Colors.blue, Icons.schedule),
                    _statusBox(context, 'Delayed', "${stats['delayed']}",
                        Colors.orange, Icons.timer_off),
                    _statusBox(context, 'Arrived', "${stats['arrived']}",
                        Colors.green, Icons.check_circle),
                    _statusBox(context, 'Cancelled', "${stats['cancelled']}",
                        Colors.red, Icons.cancel),
                  ],
                ),
                const SizedBox(height: 24),

                _buildHeader(stats, languageCode),
                const SizedBox(height: 24),
                _buildTrendsAccordion(stats, languageCode),
                const SizedBox(height: 16),
                _buildInsightsAccordion(stats, languageCode),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.query_stats, size: 80),
          const SizedBox(height: 16),
          Text('No Active Trips', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Complete a trip to see your stats.", style: TextStyle()),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) {
    int completedTrips = 0;
    double totalSpent = 0;
    Map<String, int> citiesVisited = {};
    Map<int, int> monthlyTrips = {};

    int upcoming = 0;
    int delayed = 0;
    int arrived = 0;
    int cancelled = 0;
    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final tripData = data['tripData'] as Map<String, dynamic>? ?? {};

      // --- Status Counting ---
      final rawStatus =
          (data['status'] ?? 'confirmed').toString().toLowerCase();
      final delay =
          (data['delayMinutes'] ?? tripData['delayMinutes'] ?? 0) as int;

      DateTime? date;
      if (data['departureDateTime'] is Timestamp) {
        date = (data['departureDateTime'] as Timestamp).toDate();
      } else if (tripData['departureDateTime'] is Timestamp) {
        date = (tripData['departureDateTime'] as Timestamp).toDate();
      } else if (data['departureTime'] is Timestamp) {
        date = (data['departureTime'] as Timestamp).toDate();
      } else if (tripData['departureTime'] is Timestamp) {
        date = (tripData['departureTime'] as Timestamp).toDate();
      } else if (data['bookingTime'] is Timestamp) {
        date = (data['bookingTime'] as Timestamp).toDate();
      }

      if (date != null) {
        final activeCutoff = now.subtract(const Duration(hours: 12));
        final isActive = date.isAfter(activeCutoff);
        final isFuture = date.isAfter(now);
        final isRecent =
            date.isAfter(now.subtract(const Duration(hours: 24))) &&
                date.isBefore(now);

        if (rawStatus == 'cancelled') {
          if (isFuture || isRecent) {
            cancelled++;
          }
        } else if (rawStatus == 'completed' ||
            rawStatus == 'arrived' ||
            rawStatus == 'confirmed' && date.isBefore(now)) {
          arrived++;
          completedTrips++;
        } else if (rawStatus == 'delayed' || delay > 0) {
          if (isFuture) delayed++;
        } else {
          if (isActive) upcoming++;
        }
      }

      // Amount
      final amt =
          (data['totalAmount'] ?? data['price'] ?? tripData['price'] ?? 0);
      totalSpent += (amt is num) ? amt.toDouble() : 0.0;

      // City Lookup (Nested in tripData usually)
      final dest = tripData['destinationCity'] ??
          tripData['toCity'] ??
          data['destinationCity'] ??
          data['toCity'] ??
          data['destination'] ??
          'Unknown';

      if (dest != 'Unknown') {
        citiesVisited[dest] = (citiesVisited[dest] ?? 0) + 1;
      }

      // Date (Already parsed above)
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

    // Most active month
    String mostActiveMonth = "N/A";
    if (monthlyTrips.isNotEmpty) {
      var sortedMonths = monthlyTrips.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostActiveMonth = DateFormat('MMMM')
          .format(DateTime(_focusedDate.year, sortedMonths.first.key));
    }

    return {
      'totalTrips': completedTrips,
      'totalSpent': totalSpent,
      'favoriteDest': favoriteDest,
      'mostActiveMonth': mostActiveMonth,
      'monthlyTrips': monthlyTrips,
      'year': _focusedDate.year,
      'Upcoming': upcoming,
      'delayed': delayed,
      'arrived': arrived,
      'cancelled': cancelled
    };
  }

  Widget _statusBox(BuildContext context, String label, String count,
      Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(count,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> stats, String lang) {
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
              Text('Total Spent',
                  style: const TextStyle(color: Colors.white70)),
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
            child: const Icon(Icons.credit_card_rounded,
                color: Colors.white, size: 28),
          )
        ],
      ),
    );
  }

  Widget _buildTrendsAccordion(Map<String, dynamic> stats, String lang) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text('Travel Trends',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        data: stats['monthlyTrips'] as Map<int, int>,
                        year: _focusedDate.year),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsAccordion(Map<String, dynamic> stats, String lang) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text('Insights',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.lightbulb, color: Colors.amber),
          children: [
            _insightRow(
                Icons.place, 'Favorite Destination', stats['favoriteDest']),
            _insightRow(Icons.calendar_month, 'Most Active Month',
                stats['mostActiveMonth']),
            _insightRow(Icons.directions_bus, 'Total Trips Completed',
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
  final int year; // NEW
  const _SimpleScatterChart({required this.data, required this.year});

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
                  color: Colors.grey.withValues(alpha: 0.1),
                );
              }),
            ),
            // Trend Line
            if (data.length > 1)
              CustomPaint(
                  size: Size(w, h),
                  painter: _LinePainter(
                      data: data,
                      maxVal: maxVal,
                      color: AppTheme.primaryColor)),

            // Scatter Points
            ...List.generate(12, (index) {
              final month = index + 1;
              final count = data[month] ?? 0;
              if (count == 0) return const SizedBox.shrink();

              // X position: distributed evenly
              final double x = (index / 11) * (w - 20) + 10;
              // Y position
              final double bottom = (count / maxVal) * (h - 20);

              return Positioned(
                left: x - 6,
                bottom: bottom,
                child: Tooltip(
                  message:
                      "${DateFormat('MMMM').format(DateTime(year, month))}: $count",
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
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
                    return Text(DateFormat('MMM').format(DateTime(year, m)),
                        style: TextStyle(fontSize: 10, color: Colors.grey));
                  }),
                ))
          ],
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  final Map<int, int> data;
  final int maxVal;
  final Color color;

  _LinePainter({required this.data, required this.maxVal, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;

    final List<int> sortedMonths = data.keys.toList()..sort();

    for (int month in sortedMonths) {
      final double x = ((month - 1) / 11) * (size.width - 20) + 10;
      final double y =
          size.height - ((data[month]! / maxVal) * (size.height - 20));

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
