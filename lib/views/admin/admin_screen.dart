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
      final isDesktop = constraints.maxWidth > 900;
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Column(
          children: [
            const AdminNavBar(selectedIndex: 0),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 40 : 20,
                    horizontal: isDesktop ? 40 : 16),
                child: Column(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ]),
                                    child: Icon(
                                        isEditing ? Icons.edit : Icons.add_road,
                                        color: Colors.white,
                                        size: 24),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          isEditing
                                              ? "Edit Route"
                                              : "Add New Route",
                                          style: GoogleFonts.outfit(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.darkText)),
                                      Text(
                                          "Fill in the details below to ${isEditing ? 'update' : 'create'} a bus route.",
                                          style: GoogleFonts.inter(
                                              color: Colors.grey.shade600)),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 40),

                              // A) Route Details Card
                              _buildCard(
                                  title: "Route Details",
                                  icon: Icons.map,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                              child: _buildDropdown(
                                                  "From (Origin)",
                                                  Icons.flight_takeoff,
                                                  _fromCity,
                                                  AppConstants.cities,
                                                  (v) => _fromCity = v)),
                                          const SizedBox(width: 20),
                                          Expanded(
                                              child: _buildDropdown(
                                                  "To (Destination)",
                                                  Icons.flight_land,
                                                  _toCity,
                                                  AppConstants.cities,
                                                  (v) => _toCity = v)),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: _buildDropdown(
                                                  "Via / Route Variant",
                                                  Icons.alt_route,
                                                  _viaRoute,
                                                  _viaOptions,
                                                  (v) => _viaRoute = v)),
                                          const SizedBox(width: 20),
                                          Expanded(
                                              child: _buildDurationField()),
                                        ],
                                      )
                                    ],
                                  )),
                              const SizedBox(height: 24),

                              // B) Schedule Card
                              _buildCard(
                                  title: "Schedule & Timing",
                                  icon: Icons.schedule,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                              child: _buildTimePicker(
                                                  "Departure Time",
                                                  _departureTime, (d) {
                                            setState(() => _departureTime = d);
                                            _calculateArrival();
                                          })),
                                          const SizedBox(width: 20),
                                          Expanded(
                                              child: _buildTimePicker(
                                                  "Arrival Time",
                                                  _arrivalTime,
                                                  (d) => setState(
                                                      () => _arrivalTime = d))),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      if (!isEditing)
                                        _buildScheduleTypeToggle(),
                                      const SizedBox(height: 24),
                                      if (_isRecurring)
                                        _buildRecurringDaysSelector()
                                      else
                                        _buildSingleDatePicker()
                                    ],
                                  )),
                              const SizedBox(height: 24),

                              // C) Bus Info Card
                              _buildCard(
                                  title: "Fare & Bus Information",
                                  icon: Icons.directions_bus,
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                          "Fare Amount (LKR)", _fareController,
                                          isNumber: true,
                                          icon: Icons.attach_money),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: _buildTextField(
                                                  "Bus Number",
                                                  _busNumberController,
                                                  icon: Icons
                                                      .confirmation_number)),
                                          const SizedBox(width: 20),
                                          Expanded(
                                              child: _buildTextField(
                                                  "Operator Name",
                                                  _operatorController,
                                                  icon: Icons.person)),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: _buildTextField(
                                                  "Total Seats",
                                                  _seatsController,
                                                  isNumber: true,
                                                  icon: Icons.event_seat)),
                                          const SizedBox(width: 20),
                                          Expanded(
                                              child: _buildTextField(
                                                  "Platform No.",
                                                  _platformController,
                                                  icon: Icons.signpost)),
                                        ],
                                      ),
                                    ],
                                  )),

                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shadowColor: AppTheme.primaryColor
                                        .withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                      isEditing
                                          ? "SAVE CHANGES"
                                          : "CREATE ROUTE",
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          letterSpacing: 1)),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
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

  Widget _buildCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText)),
            ],
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1)),
          child
        ],
      ),
    );
  }

  Widget _buildScheduleTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem("Recurring Route", _isRecurring,
              () => setState(() => _isRecurring = true)),
          _toggleItem("One-Time Trip", !_isRecurring,
              () => setState(() => _isRecurring = false)),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ]
                  : []),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.grey.shade600))),
    );
  }

  Widget _buildRecurringDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Operating Days",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _daysOfWeek.map((day) {
            final isSelected = _operatingDays.contains(day);
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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade200)),
              labelStyle:
                  TextStyle(color: isSelected ? Colors.white : Colors.black87),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSingleDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _tripDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: AppTheme.primaryColor,
                colorScheme:
                    const ColorScheme.light(primary: AppTheme.primaryColor),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _tripDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Trip Date",
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey.shade500)),
                Text(
                  _tripDate == null
                      ? "Select Date"
                      : DateFormat('EEE, MMM d, yyyy').format(_tripDate!),
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _tripDate == null ? Colors.grey : Colors.black87),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String? value,
      List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "Required" : null,
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      controller: _durationController,
      readOnly: true,
      onTap: () async {
        // ... (Time picker logic same as before, condensed for brevity or reuse)
        // Simplified implementation for cleaner replacement:
        TimeOfDay initial = const TimeOfDay(hour: 3, minute: 30);
        if (_durationController.text.contains(':')) {
          final parts = _durationController.text.split(':');
          if (parts.length == 2) {
            initial = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 3,
                minute: int.tryParse(parts[1]) ?? 30);
          }
        }
        final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: initial,
            helpText: "SELECT DURATION",
            initialEntryMode: TimePickerEntryMode.input,
            builder: (context, child) {
              return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!);
            });

        if (picked != null) {
          final h = picked.hour.toString().padLeft(2, '0');
          final m = picked.minute.toString().padLeft(2, '0');
          setState(() {
            _durationController.text = "$h:$m";
            _calculateArrival();
          });
        }
      },
      decoration: InputDecoration(
        labelText: "Duration (HH:MM)",
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon:
            const Icon(Icons.timer_outlined, color: Colors.grey, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor)),
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
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
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500)),
              Row(
                children: [
                  Text(DateFormat('HH:mm').format(time),
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(width: 8),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey)
                ],
              )
            ],
          )),
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
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: Colors.grey.shade500)
            : null,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor)),
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }
}
