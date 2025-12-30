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
    // Peach aesthetic from user request / screenshot
    // Using a light peach for header background
    final headerColor = const Color(0xFFFFDBCF);
    final onHeaderColor = const Color(0xFF5E1600);

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select dates",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: onHeaderColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getHeaderText(),
                  style: TextStyle(
                    fontFamily: 'Outfit', // Or appropriate serif if intended
                    fontSize: 32, // Large text like screenshot
                    color: onHeaderColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // Calendar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 328, // Standard M3 dialog width
              height: 300,
              child: CalendarDatePicker2(
                config: CalendarDatePicker2Config(
                  calendarType: CalendarDatePicker2Type.multi,
                  selectedDayHighlightColor:
                      const Color(0xFFFF8A65), // Stronger Peach for selection
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
                  weekdayLabelTextStyle: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  dayTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
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
            padding: const EdgeInsets.all(16), // M3 padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selectedDates),
                  child: Text(
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
