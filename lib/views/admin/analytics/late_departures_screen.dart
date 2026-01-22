import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../utils/app_theme.dart'; // Added
import '../../../../controllers/trip_controller.dart';
import 'package:provider/provider.dart';

class LateDeparturesView extends StatefulWidget {
  const LateDeparturesView({super.key});

  @override
  State<LateDeparturesView> createState() => _LateDeparturesViewState();
}

class _LateDeparturesViewState extends State<LateDeparturesView> {
  String _routeFilter = "";
  DateTime _selectedDate = DateTime.now();
  DateTime _tempSelectedDate = DateTime.now(); // Temp variable for picker
  String _filterType = "Daily"; // Daily, Monthly, Yearly

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Start/End based on Filter Type
    DateTime startOfPeriod;
    DateTime endOfPeriod;

    if (_filterType == 'Monthly') {
      startOfPeriod = DateTime(_selectedDate.year, _selectedDate.month, 1);
      endOfPeriod =
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
    } else if (_filterType == 'Yearly') {
      startOfPeriod = DateTime(_selectedDate.year, 1, 1);
      endOfPeriod = DateTime(_selectedDate.year, 12, 31, 23, 59, 59);
    } else {
      // Daily
      startOfPeriod =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      endOfPeriod = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, 23, 59, 59);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('departureDateTime', isGreaterThanOrEqualTo: startOfPeriod)
          .where('departureDateTime', isLessThanOrEqualTo: endOfPeriod)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final allTrips = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {
            'Route':
                "${data['originCity'] ?? '?'} - ${data['destinationCity'] ?? '?'}",
            'delay': (data['delayMinutes'] ?? 0).toInt(),
            'date': (data['departureDateTime'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            'bus': data['busNumber'] ?? 'Bus',
            'status': data['status'] ?? 'scheduled'
          };
        }).toList();

        // 2. Filter by Route Text
        final filteredTrips = _routeFilter.isEmpty
            ? allTrips
            : allTrips
                .where((t) => (t['Route'] as String)
                    .toLowerCase()
                    .contains(_routeFilter.toLowerCase()))
                .toList();

        // Calculate Stats (safe if empty)
        final stats = _calculateStats(filteredTrips);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER: SELECTORS ---
              _buildHeader(context),
              const SizedBox(height: 32),

              // --- KPI BOXES ---
              _buildKPIs(context, stats),
              const SizedBox(height: 32),

              // --- PIE CHART ---
              const Text('Punctuality Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 250,
                child: _buildPieChart(stats),
              ),

              const SizedBox(height: 32),

              // --- RECENT LATE TRIPS ---
              const Text('High Delay Trips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildLateTripsList(stats['lateTrips']),
            ],
          ),
        );
      },
    );
  }

  // ... _calculateStats ... (UNCHANGED, so not included in replacement if I could, but I need to replace the whole class to add _filterType variable cleanly or use partial replacement. I'll replace mainly build and _buildHeader)
  // Wait, I can't replace partial class easily if I change fields.
  // I will replace from class definition start to build method end.
  // And also _buildHeader.
  // Actually, I can replace the STATE class start.

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> trips) {
    int total = trips.length;
    int onTime = 0;
    int late = 0; // > 5 mins
    List<Map<String, dynamic>> lateList = [];

    for (var t in trips) {
      if (t['delay'] > 5) {
        // Changed to 5 mins
        late++;
        lateList.add(t);
      } else {
        onTime++;
      }
    }

    lateList.sort((a, b) => b['delay'].compareTo(a['delay']));
    double rate = total == 0 ? 0 : (late / total) * 100;

    String health = "Healthy";
    Color healthColor = Colors.green;
    if (rate > 10) {
      health = "Needs Attention";
      healthColor = Colors.orange;
    }
    if (rate > 30) {
      health = "Critical";
      healthColor = Colors.red;
    }

    return {
      'total': total,
      'onTime': onTime,
      'late': late,
      'rate': rate,
      'health': health,
      'healthColor': healthColor,
      'lateTrips': lateList
    };
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 800;

      // 1. Search Field
      final searchField = LayoutBuilder(builder: (context, constraints) {
        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            final controller =
                Provider.of<TripController>(context, listen: false);
            if (controller.availableCities.isEmpty) {
              controller.fetchAvailableCities();
            }

            return controller.availableCities.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            setState(() => _routeFilter = selection);
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                  hintText: "Search Route (e.g. Colombo)",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
              onChanged: (v) => setState(() => _routeFilter = v),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(option),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      });

      // 2. Filter Chips
      final filterChips = Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterChip("Daily", "Daily"),
              _filterChip("Monthly", "Monthly"),
              _filterChip("Yearly", "Yearly"),
            ],
          ));

      // 3. Date Picker (Dynamic based on filter type)
      final datePicker = InkWell(
        onTap: () async {
          DateTime? picked;

          if (_filterType == 'Daily') {
            picked = await showDatePicker(
              context: context,
              initialDate: _tempSelectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
            );
          } else if (_filterType == 'Monthly') {
            // Month Picker
            picked = await showMonthYearPicker(
              context: context,
              initialDate: _tempSelectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              monthOnly: true,
            );
          } else {
            // Year Picker
            picked = await showYearPicker(
              context: context,
              initialDate: _tempSelectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
            );
          }

          if (picked != null) {
            setState(() => _tempSelectedDate = picked!);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
              Text(
                  _filterType == 'Daily'
                      ? DateFormat('MMM d, yyyy').format(_tempSelectedDate)
                      : _filterType == 'Monthly'
                          ? DateFormat('MMMM yyyy').format(_tempSelectedDate)
                          : DateFormat('yyyy').format(_tempSelectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

      // 4. Search Button
      final searchButton = ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _selectedDate = _tempSelectedDate; // Apply the temp date
          });
        },
        icon: const Icon(Icons.search, size: 18),
        label: const Text('Search'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isMobile
              ? Column(
                  children: [
                    searchField,
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          filterChips,
                          const SizedBox(width: 16),
                          datePicker,
                          const SizedBox(width: 12),
                          searchButton,
                        ],
                      ),
                    )
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: searchField),
                    const SizedBox(width: 16),
                    filterChips,
                    const SizedBox(width: 16),
                    datePicker,
                    const SizedBox(width: 12),
                    searchButton,
                  ],
                ),
        ),
      );
    });
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildKPIs(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            "Total Trips",
            "${stats['total']}",
            Icons.directions_bus,
            Colors.blue,
            null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            context,
            "Late Rate",
            "${(stats['rate'] as double).toStringAsFixed(1)}%",
            Icons.warning_amber,
            stats['healthColor'],
            stats['health'], // Label
          ),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, String title, String value,
      IconData icon, Color color, String? subLabel) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (subLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(subLabel,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> stats) {
    int onTime = stats['onTime'];
    int late = stats['late'];
    final total = onTime + late;

    if (total == 0) return const Center(child: Text("No Data"));

    final onTimePct = onTime / total;
    final latePct = late / total;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Custom Pie
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _PieChartPainter(
                onTimePct: onTimePct,
                latePct: latePct,
                onTimeColor: Colors.blue, // Changed to Blue
                lateColor: Colors.red,
              ),
            ),
          ),
          // Legend
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendItem(
                  Colors.blue,
                  "On Time", // Changed to Blue
                  "${(onTimePct * 100).toStringAsFixed(1)}%"),
              const SizedBox(height: 16),
              _legendItem(
                  Colors.red, "Late", "${(latePct * 100).toStringAsFixed(1)}%"),
            ],
          )
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  Widget _buildLateTripsList(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) return const Text("No significant delays.");
    return Column(
      children: trips.take(5).map((t) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.timer_off, color: Colors.white, size: 20)),
            title: Text(t['Route'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('MMM d, hh:mm a').format(t['date'])),
            trailing: Text("+${t['delay']} min",
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        );
      }).toList(),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final double onTimePct;
  final double latePct;
  final Color onTimeColor;
  final Color lateColor;

  _PieChartPainter({
    required this.onTimePct,
    required this.latePct,
    required this.onTimeColor,
    required this.lateColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw OnTime Arc
    paint.color = Colors.blue; // Force Blue for OnTime
    final onTimeAngle = 2 * pi * onTimePct;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        onTimeAngle, true, paint);

    // Draw Late Arc
    paint.color = lateColor;
    final lateAngle = 2 * pi * latePct;
    // Start late arc where onTime ended
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + onTimeAngle, lateAngle, true, paint);

    // Optional: Donut hole
    // paint.color = Colors.white;
    // canvas.drawCircle(center, radius * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper function for Month Picker
Future<DateTime?> showMonthYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  bool monthOnly = false,
}) async {
  // Show a dialog with month selection
  return await showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      int selectedMonth = initialDate.month;
      int selectedYear = initialDate.year;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Month'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year selector
                  DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    items: List.generate(
                      lastDate.year - firstDate.year + 1,
                      (index) {
                        final year = firstDate.year + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString(),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                    onChanged: (year) {
                      if (year != null) {
                        setState(() => selectedYear = year);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Month grid
                  SizedBox(
                    height: 300,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.0,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected = month == selectedMonth;

                        return InkWell(
                          onTap: () {
                            setState(() => selectedMonth = month);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              months[index]
                                  .substring(0, 3), // Show "Jan", "Feb", etc.
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(DateTime(selectedYear, selectedMonth, 1));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );
}

// Helper function for Year Picker
Future<DateTime?> showYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  // Show a simple dialog with year selection
  return await showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      final years = List<int>.generate(
        lastDate.year - firstDate.year + 1,
        (index) => firstDate.year + index,
      );

      return AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = year == initialDate.year;

              return ListTile(
                title: Text(
                  year.toString(),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : null,
                  ),
                ),
                selected: isSelected,
                onTap: () {
                  Navigator.of(context).pop(DateTime(year, 1, 1));
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
