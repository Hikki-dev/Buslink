import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class BulkCalendarDialog extends StatefulWidget {
  final List<DateTime> initialDates;

  const BulkCalendarDialog({super.key, required this.initialDates});

  @override
  State<BulkCalendarDialog> createState() => _BulkCalendarDialogState();
}

class _BulkCalendarDialogState extends State<BulkCalendarDialog> {
  late List<DateTime> _selectedDates;
  int _seats = 1;

  @override
  void initState() {
    super.initState();
    _selectedDates = List.from(widget.initialDates);
    if (_selectedDates.isEmpty) {
      _selectedDates.add(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Peach aesthetic
    const headerColor = Color(0xFFFFDBCF);
    const onHeaderColor = Color(0xFF5E1600);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "How many seats do you want to book?",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: onHeaderColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Seat Counter Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _seats == 1 ? "1 Passenger" : "$_seats Passengers",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 32,
                        color: onHeaderColor,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Card(
                      elevation: 0,
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.remove, color: onHeaderColor),
                            onPressed: _seats > 1
                                ? () => setState(() => _seats--)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: onHeaderColor),
                            onPressed: () => setState(() => _seats++),
                          ),
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white54),
                const SizedBox(height: 8),
                const Text(
                  "Select specific travel dates:",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: onHeaderColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getHeaderText(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    color: onHeaderColor.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Calendar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 328,
              height: 280,
              child: CalendarDatePicker2(
                config: CalendarDatePicker2Config(
                  calendarType: CalendarDatePicker2Type.multi,
                  selectedDayHighlightColor: const Color(0xFFFF8A65),
                  selectedDayTextStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  todayTextStyle: const TextStyle(
                    color: Color(0xFFFF8A65),
                    fontWeight: FontWeight.bold,
                  ),
                  controlsTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: _selectedDates,
                onValueChanged: (dates) {
                  setState(() {
                    _selectedDates = dates.whereType<DateTime>().toList()
                      ..sort();
                  });
                },
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(
                      context, {'dates': _selectedDates, 'seats': _seats}),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderText() {
    if (_selectedDates.isEmpty) return "None selected";
    if (_selectedDates.length == 1) {
      return DateFormat('EEE, MMM d').format(_selectedDates.first);
    }
    return "${_selectedDates.length} Dates selected";
  }
}
