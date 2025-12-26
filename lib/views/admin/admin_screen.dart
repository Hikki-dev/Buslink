import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import 'layout/admin_navbar.dart';
import 'layout/admin_footer.dart';

class AdminScreen extends StatefulWidget {
  final Trip? trip;
  const AdminScreen({super.key, required this.trip});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();

  // A) Route Details
  String? _fromCity;
  String? _toCity;
  String? _viaRoute;
  final TextEditingController _durationController = TextEditingController();

  // B) Schedule
  DateTime _departureTime = DateTime.parse("2023-01-01 08:00:00");
  DateTime _arrivalTime = DateTime.parse("2023-01-01 12:00:00");
  final List<String> _operatingDays = []; // Mon, Tue...
  bool _isRecurring = true;
  DateTime? _tripDate;

  // C) Fare
  final TextEditingController _fareController = TextEditingController();

  // Extra (Bus)
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _operatorController = TextEditingController();
  final TextEditingController _seatsController =
      TextEditingController(text: "40");
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _busTypeController =
      TextEditingController(text: "Access / Luxury");

  bool get isEditing => widget.trip != null;

  final List<String> _viaOptions = [
    "Expressway",
    "Kurunegala",
    "Kandy Road",
    "Galle Road",
    "Nittambuwa",
    "Avissawella",
    "Normal Route"
  ];

  final List<String> _daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.trip!;
      _fromCity = t.fromCity;
      _toCity = t.toCity;
      _viaRoute = t.via.isNotEmpty ? t.via : null;
      _durationController.text = t.duration;
      _departureTime = t.departureTime;
      _arrivalTime = t.arrivalTime;
      _operatingDays.addAll(t.operatingDays);
      _fareController.text = t.price.toStringAsFixed(0);
      _busNumberController.text = t.busNumber;
      _operatorController.text = t.operatorName;
      _seatsController.text = t.totalSeats.toString();
      _platformController.text = t.platformNumber;
      _isRecurring = false;
      _tripDate = t.departureTime;
    }
  }

  void _calculateArrival() {
    // If duration matches HH:MM, update arrival
    final dur = _durationController.text;
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(dur)) {
      final parts = dur.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      setState(() {
        _arrivalTime = _departureTime.add(Duration(hours: h, minutes: m));
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Check operating days if creating a route
    // For simplicity, we treat this form as creating a Recurring Route if days are selected,
    // or a single trip if no days selected (default to today/tomorrow logic if we were booking,
    // but for Admin "Add Route", let's assume recurrence or at least single definition).
    // The requirement implies Route Creation.

    // If no days selected, maybe default to "Daily" or error?
    // Let's assume empty days means "One time trip for the selected date" (but we don't have a date picker for single trip here, only time).
    // The prompt says "Operating Days ... (Mon-Sun)". We'll enforce at least one day or handle as 'Daily' if all unchecked?
    // Let's just enforce selection or warn.
    // Validation for new fields
    if (_isRecurring) {
      if (_operatingDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Please select at least one operating day.")));
        return;
      }
    } else {
      // Single Trip
      if (_tripDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a trip date.")));
        return;
      }
    }

    final controller = Provider.of<TripController>(context, listen: false);

    // Prepare Base Data (Time component is in _departureTime/_arrivalTime)
    final tripData = {
      'fromCity': _fromCity,
      'toCity': _toCity,
      'via': _viaRoute,
      'duration': _durationController.text,
      'operatingDays': _isRecurring ? _operatingDays : [],
      'price': double.parse(_fareController.text),
      'busNumber': _busNumberController.text,
      'operatorName': _operatorController.text,
      'totalSeats': int.parse(_seatsController.text),
      'busType': _busTypeController.text,
      'platformNumber':
          _platformController.text.isEmpty ? 'TBD' : _platformController.text,
      'features': ['AC', 'WiFi'], // default
    };

    if (isEditing) {
      // Editing existing trip -> Just update it. Recurrence doesn't apply here usually.
      // We assume editing means editing a specific trip instance.
      // Re-construct full datetime if we allow date editing
      if (_tripDate != null) {
        final d = _tripDate!;
        final newDep = DateTime(
            d.year, d.month, d.day, _departureTime.hour, _departureTime.minute);
        // Calculate arrival based on duration or existing diff
        final durationDiff = _arrivalTime.difference(_departureTime);
        final newArr = newDep.add(durationDiff);

        tripData['departureTime'] = newDep;
        tripData['arrivalTime'] = newArr;
      } else {
        tripData['departureTime'] = _departureTime;
        tripData['arrivalTime'] = _arrivalTime;
      }

      await controller.updateTripDetails(context, widget.trip!.id, tripData);
    } else {
      // ADDING NEW
      if (_isRecurring) {
        // RECURRING ROUTE
        // We pass the dummy times, addRoute will extract HH:MM and use days to generate
        tripData['departureTime'] = _departureTime;
        tripData['arrivalTime'] = _arrivalTime;

        List<int> recurrenceDays =
            _operatingDays.map((d) => _daysOfWeek.indexOf(d) + 1).toList();
        await controller.addRoute(context, tripData, recurrenceDays);
      } else {
        // SINGLE TRIP (ONE-TIME)
        final d = _tripDate!;
        final newDep = DateTime(
            d.year, d.month, d.day, _departureTime.hour, _departureTime.minute);

        // Check for overnight arrival logic based on time
        // If arrival time (HH:MM) is before departure time (HH:MM), it's next day
        DateTime newArr = DateTime(
            d.year, d.month, d.day, _arrivalTime.hour, _arrivalTime.minute);

        if (newArr.isBefore(newDep)) {
          newArr = newArr.add(const Duration(days: 1));
        }

        tripData['departureTime'] = newDep;
        tripData['arrivalTime'] = newArr;
        tripData['isGenerated'] = false; // Manually added

        await controller.addTrip(context, tripData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 800;
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Column(
          children: [
            // Nav
            const AdminNavBar(selectedIndex: 0), // Keeping 0 or handling back

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 40 : 20,
                    horizontal: isDesktop ? 24 : 16),
                child: Column(
                  children: [
                    // Form Container
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Container(
                          padding: EdgeInsets.all(isDesktop ? 32 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                          isEditing
                                              ? Icons.edit
                                              : Icons.add_road,
                                          color: AppTheme.primaryColor),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      isEditing
                                          ? "Edit Route"
                                          : "Add New Route",
                                      style: GoogleFonts.outfit(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                _buildSectionHeader("A) Route Details"),

                                // From / To
                                Row(
                                  children: [
                                    Expanded(
                                        child: _buildDropdown(
                                            "From (Origin)",
                                            _fromCity,
                                            AppConstants.cities,
                                            (v) => _fromCity = v)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: _buildDropdown(
                                            "To (Destination)",
                                            _toCity,
                                            AppConstants.cities,
                                            (v) => _toCity = v)),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Via / Duration
                                Row(
                                  children: [
                                    Expanded(
                                        child: _buildDropdown(
                                            "Via / Route Variant",
                                            _viaRoute,
                                            _viaOptions,
                                            (v) => _viaRoute = v)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _durationController,
                                        readOnly: true,
                                        onTap: () async {
                                          TimeOfDay initial = const TimeOfDay(
                                              hour: 3, minute: 30);
                                          if (_durationController.text
                                              .contains(':')) {
                                            final parts = _durationController
                                                .text
                                                .split(':');
                                            if (parts.length == 2) {
                                              initial = TimeOfDay(
                                                  hour:
                                                      int.tryParse(parts[0]) ??
                                                          3,
                                                  minute:
                                                      int.tryParse(parts[1]) ??
                                                          30);
                                            }
                                          }

                                          final TimeOfDay? picked =
                                              await showTimePicker(
                                            context: context,
                                            initialTime: initial,
                                            helpText: "SELECT TRAVEL DURATION",
                                            initialEntryMode:
                                                TimePickerEntryMode.input,
                                            builder: (context, child) {
                                              return MediaQuery(
                                                data: MediaQuery.of(context)
                                                    .copyWith(
                                                        alwaysUse24HourFormat:
                                                            true),
                                                child: child!,
                                              );
                                            },
                                          );

                                          if (picked != null) {
                                            final h = picked.hour
                                                .toString()
                                                .padLeft(2, '0');
                                            final m = picked.minute
                                                .toString()
                                                .padLeft(2, '0');
                                            setState(() {
                                              _durationController.text =
                                                  "$h:$m";
                                              _calculateArrival();
                                            });
                                          }
                                        },
                                        decoration: const InputDecoration(
                                          labelText: "Duration (HH:MM)",
                                          border: OutlineInputBorder(),
                                          hintText: "Tap to select",
                                          suffixIcon:
                                              Icon(Icons.timer_outlined),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return "Required";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),
                                _buildSectionHeader("B) Schedule"),

                                // Times
                                Row(
                                  children: [
                                    Expanded(
                                        child: _buildTimePicker(
                                            "Departure Time", _departureTime,
                                            (d) {
                                      setState(() => _departureTime = d);
                                      _calculateArrival();
                                    })),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: _buildTimePicker(
                                            "Arrival Time",
                                            _arrivalTime,
                                            (d) => setState(
                                                () => _arrivalTime = d))),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Toggle: Recurring vs Single
                                if (!isEditing)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Schedule Type:",
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        const SizedBox(width: 16),
                                        ToggleButtons(
                                          isSelected: [
                                            _isRecurring,
                                            !_isRecurring
                                          ],
                                          onPressed: (index) {
                                            setState(() {
                                              _isRecurring = index == 0;
                                            });
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          selectedColor: Colors.white,
                                          fillColor: AppTheme.primaryColor,
                                          children: const [
                                            Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16),
                                                child: Text("Recurring Route")),
                                            Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16),
                                                child: Text("One-Time Trip")),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                if (_isRecurring) ...[
                                  Text("Operating Days (Weekly)",
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    children: _daysOfWeek.map((day) {
                                      final isSelected =
                                          _operatingDays.contains(day);
                                      return FilterChip(
                                        label: Text(day.substring(0, 3)),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _operatingDays.add(day);
                                            } else {
                                              _operatingDays.remove(day);
                                            }
                                          });
                                        },
                                        checkmarkColor: Colors.white,
                                        selectedColor: AppTheme.primaryColor,
                                        labelStyle: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87),
                                      );
                                    }).toList(),
                                  ),
                                ] else ...[
                                  Text("Trip Date",
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            _tripDate ?? DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setState(() => _tripDate = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_month,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 12),
                                          Text(
                                            _tripDate == null
                                                ? "Select Date"
                                                : DateFormat('EEE, MMM d, yyyy')
                                                    .format(_tripDate!),
                                            style: GoogleFonts.inter(
                                                fontSize: 16,
                                                color: _tripDate == null
                                                    ? Colors.grey
                                                    : Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 32),
                                _buildSectionHeader("C) Fare & Bus Info"),

                                _buildTextField(
                                    "Fare Amount (LKR)", _fareController,
                                    isNumber: true, icon: Icons.attach_money),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _buildTextField(
                                            "Bus Number", _busNumberController,
                                            icon: Icons.directions_bus)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: _buildTextField("Operator Name",
                                            _operatorController,
                                            icon: Icons.person)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _buildTextField(
                                            "Total Seats", _seatsController,
                                            isNumber: true,
                                            icon: Icons.event_seat)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: _buildTextField(
                                            "Platform No.", _platformController,
                                            icon: Icons.signpost)),
                                  ],
                                ),

                                const SizedBox(height: 48),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                        isEditing
                                            ? "SAVE CHANGES"
                                            : "ADD ROUTE",
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    const AdminFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "Required" : null,
    );
  }

  Widget _buildTimePicker(
      String label, DateTime time, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(
            context: context, initialTime: TimeOfDay.fromDateTime(time));
        if (t != null) {
          final newDate =
              DateTime(time.year, time.month, time.day, t.hour, t.minute);
          onChanged(newDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(DateFormat('hh:mm a').format(time)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, IconData? icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon:
            icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }
}
