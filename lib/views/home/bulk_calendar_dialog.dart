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
  // _seats removed

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
    // Standard Material Date Picker Aesthetic (Crimson)
    final primaryColor = AppTheme.primaryColor;
    const onHeaderColor = Colors.white;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER (Mimic Material DatePicker)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SELECT DATES",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getHeaderText(),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      color: onHeaderColor,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // INTEGRATED PASSENGER COUNTER REMOVED
                ],
              ),
            ),

            // CALENDAR BODY
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    // Allow natural sizing with max width constraint standard for pickers
                    width: 360,
                    child: CalendarDatePicker2(
                      config: CalendarDatePicker2Config(
                        calendarType: CalendarDatePicker2Type.multi,
                        selectedDayHighlightColor: primaryColor,
                        selectedDayTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        todayTextStyle: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        controlsTextStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        // Mimic Material 3 rounded selection
                        dayBorderRadius: BorderRadius.circular(20),
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
              ),
            ),

            // ACTIONS
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(
                        context, {'dates': _selectedDates, 'SEATS': 1}),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getHeaderText() {
    if (_selectedDates.isEmpty) return "Select dates";
    if (_selectedDates.length == 1) {
      return DateFormat('EEE, MMM d').format(_selectedDates.first);
    }
    return "${_selectedDates.length} Dates Selected";
  }
}
