import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../../controllers/trip_controller.dart';
import '../../data/cities.dart';
import '../../models/trip_model.dart';
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
      // OperatingDays is List<int> in Model, but List<String> in UI state
      // Model stores: [1, 2, ...] corresponding to Mon, Tue...
      _operatingDays.addAll(t.operatingDays.map((d) {
        if (d >= 1 && d <= _daysOfWeek.length) {
          return _daysOfWeek[d - 1];
        }
        return "Monday"; // Fallback
      }));
      _fareController.text = t.price.toStringAsFixed(0);
      _busNumberController.text = t.busNumber;
      _operatorController.text = t.operatorName;
      _seatsController.text = t.totalSeats.toString();
      _platformController.text = t.platformNumber;
      _isRecurring = false;
      _tripDate = t.departureTime;
      _blockedSeats.addAll(t.blockedSeats);
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
      'busNumber': 'Standard Bus', // Default
      'operatorName': 'BusLink', // Default
      'totalSeats': int.parse(_seatsController.text),
      'platformNumber': 'TBD', // Default
      'blockedSeats': _blockedSeats,
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
        await controller.createRecurringRoute(
            context, tripData, recurrenceDays);
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
      final cardColor = Theme.of(context).cardColor;
      final textColor = Theme.of(context).colorScheme.onSurface;

      return Scaffold(
        backgroundColor: scaffoldColor,
        body: Column(
          children: [
            // Nav
            const AdminNavBar(selectedIndex: 0),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        vertical: isDesktop ? 40 : 20,
                        horizontal: isDesktop ? 24 : 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Form Container
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Container(
                                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        children: [
                                          if (Navigator.canPop(context))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16),
                                              child: IconButton(
                                                  icon: Icon(Icons.arrow_back,
                                                      color: textColor),
                                                  onPressed: () =>
                                                      Navigator.pop(context)),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                                isEditing
                                                    ? Icons.edit
                                                    : Icons.add_road,
                                                color: AppTheme.primaryColor),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              isEditing
                                                  ? "Edit Trip Details"
                                                  : "Add New Trip",
                                              style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor),
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),

                                      _buildSectionHeader("A) Route Details"),

                                      // From / To
                                      Row(
                                        children: [
                                          Expanded(
                                              child: _buildCityAutocomplete(
                                                  "From (Origin)",
                                                  _fromCity,
                                                  (v) => _fromCity = v)),
                                          const SizedBox(width: 16),
                                          Expanded(
                                              child: _buildCityAutocomplete(
                                                  "To (Destination)",
                                                  _toCity,
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
                                            child: Builder(builder: (context) {
                                              final isDark = Theme.of(context)
                                                      .brightness ==
                                                  Brightness.dark;
                                              final textColor =
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurface;
                                              final inputFillColor = isDark
                                                  ? Colors.grey
                                                      .withValues(alpha: 0.1)
                                                  : Colors.grey.shade50;
                                              final borderColor = isDark
                                                  ? Colors.grey
                                                      .withValues(alpha: 0.2)
                                                  : Colors.grey.shade300;

                                              return TextFormField(
                                                controller: _durationController,
                                                readOnly: true,
                                                style:
                                                    TextStyle(color: textColor),
                                                onTap: () async {
                                                  TimeOfDay initial =
                                                      const TimeOfDay(
                                                          hour: 3, minute: 30);
                                                  if (_durationController.text
                                                      .contains(':')) {
                                                    final parts =
                                                        _durationController.text
                                                            .split(':');
                                                    if (parts.length == 2) {
                                                      initial = TimeOfDay(
                                                          hour: int.tryParse(
                                                                  parts[0]) ??
                                                              3,
                                                          minute: int.tryParse(
                                                                  parts[1]) ??
                                                              30);
                                                    }
                                                  }

                                                  final TimeOfDay? picked =
                                                      await showTimePicker(
                                                    context: context,
                                                    initialTime: initial,
                                                    helpText:
                                                        "SELECT TRAVEL DURATION",
                                                    initialEntryMode:
                                                        TimePickerEntryMode
                                                            .input,
                                                    builder: (context, child) {
                                                      return MediaQuery(
                                                        data: MediaQuery.of(
                                                                context)
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
                                                decoration: InputDecoration(
                                                  labelText: "Duration (HH:MM)",
                                                  labelStyle: TextStyle(
                                                      color:
                                                          Colors.grey.shade500),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color:
                                                                  borderColor)),
                                                  focusedBorder:
                                                      const OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: AppTheme
                                                                  .primaryColor,
                                                              width: 2)),
                                                  border:
                                                      const OutlineInputBorder(),
                                                  hintText: "Tap to select",
                                                  hintStyle: TextStyle(
                                                      color:
                                                          Colors.grey.shade500),
                                                  suffixIcon: const Icon(
                                                      Icons.timer_outlined,
                                                      color: Colors.grey),
                                                  filled: true,
                                                  fillColor: inputFillColor,
                                                ),
                                                validator: (v) {
                                                  if (v == null || v.isEmpty) {
                                                    return "Required";
                                                  }
                                                  return null;
                                                },
                                              );
                                            }),
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
                                                  "Departure Time",
                                                  _departureTime, (d) {
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
                                              color: isDark
                                                  ? Colors.grey
                                                      .withValues(alpha: 0.1)
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 16,
                                            runSpacing: 8,
                                            children: [
                                              Text("Schedule Type:",
                                                  style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: textColor)),
                                              ToggleButtons(
                                                constraints:
                                                    const BoxConstraints(
                                                  minHeight: 36.0,
                                                  minWidth: 80.0,
                                                ),
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
                                                fillColor:
                                                    AppTheme.primaryColor,
                                                color: textColor.withValues(
                                                    alpha: 0.7),
                                                children: const [
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 12),
                                                      child: Text(
                                                          "Recurring Route",
                                                          style: TextStyle(
                                                              fontSize: 13))),
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 12),
                                                      child: Text(
                                                          "One-Time Trip",
                                                          style: TextStyle(
                                                              fontSize: 13))),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 16),

                                      if (_isRecurring) ...[
                                        Text("Operating Days (Weekly)",
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: textColor)),
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
                                              selectedColor:
                                                  AppTheme.primaryColor,
                                              backgroundColor: isDark
                                                  ? Colors.grey
                                                      .withValues(alpha: 0.2)
                                                  : null,
                                              labelStyle: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : textColor),
                                            );
                                          }).toList(),
                                        ),
                                      ] else ...[
                                        Text("Trip Date",
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: textColor)),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  _tripDate ?? DateTime.now(),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(
                                                  const Duration(days: 365)),
                                            );
                                            if (picked != null) {
                                              setState(
                                                  () => _tripDate = picked);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_month,
                                                    color:
                                                        Colors.grey.shade600),
                                                const SizedBox(width: 12),
                                                Text(
                                                  _tripDate == null
                                                      ? "Select Date"
                                                      : DateFormat(
                                                              'EEE, MMM d, yyyy')
                                                          .format(_tripDate!),
                                                  style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 16,
                                                      color: _tripDate == null
                                                          ? Colors.grey
                                                          : textColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 32),
                                      _buildSeatLayoutEditor(),
                                      const SizedBox(height: 32),
                                      _buildSectionHeader("C) Fare & Bus Info"),

                                      _buildTextField(
                                          "Fare Amount (LKR)", _fareController,
                                          isNumber: true,
                                          icon: Icons.attach_money),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                          "Total Seats", _seatsController,
                                          isNumber: true,
                                          icon: Icons.event_seat),

                                      const SizedBox(height: 48),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _save,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          child: Text(
                                              isEditing
                                                  ? "SAVE CHANGES"
                                                  : "SAVE TRIP",
                                              style: const TextStyle(
                                                  fontFamily: 'Outfit',
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
                        ],
                      ),
                    ),
                  ),
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(height: 60),
                        AdminFooter(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildCityAutocomplete(
      String label, String? initialValue, Function(String) onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final inputFillColor =
        isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.shade50;
    final borderColor =
        isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade300;

    return LayoutBuilder(builder: (context, constraints) {
      return Autocomplete<String>(
        initialValue: TextEditingValue(text: initialValue ?? ''),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
          }
          return kSriLankanCities.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: onSelected,
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            style: TextStyle(color: textColor),
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
            },
            onChanged: (val) {
              // Also update on change to support free text or ensure state capture if not selected from list
              onSelected(val);
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade500),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor)),
              focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppTheme.primaryColor, width: 2)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: inputFillColor,
              suffixIcon: const Icon(Icons.search, color: Colors.grey),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              color: cardColor,
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
                        child: Text(option, style: TextStyle(color: textColor)),
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
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final inputFillColor =
        isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.shade50;
    final borderColor =
        isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade300;

    return LayoutBuilder(builder: (context, constraints) {
      return Autocomplete<String>(
        initialValue: TextEditingValue(text: value ?? ''),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
          }
          return items.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: onChanged,
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          if (value != null &&
              textEditingController.text.isEmpty &&
              value != textEditingController.text) {
            textEditingController.text = value;
          }
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            style: TextStyle(color: textColor),
            onFieldSubmitted: (String val) {
              onFieldSubmitted();
              onChanged(val);
            },
            onChanged: (val) {
              onChanged(val);
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade500),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor)),
              focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppTheme.primaryColor, width: 2)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: inputFillColor,
              suffixIcon: const Icon(Icons.edit_road, color: Colors.grey),
              hintText: "Select or Type New",
              hintStyle: TextStyle(color: Colors.grey.shade500),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              color: cardColor,
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
                        child: Text(option, style: TextStyle(color: textColor)),
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
  }

  Widget _buildTimePicker(
      String label, DateTime time, Function(DateTime) onChanged) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.withValues(alpha: 0.2)
        : Colors.grey.shade300;

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
          labelStyle: TextStyle(color: Colors.grey.shade500),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
        ),
        child: Text(DateFormat('hh:mm a').format(time),
            style: TextStyle(color: textColor)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final inputFillColor =
        isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.shade50;
    final borderColor =
        isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade300;

    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: inputFillColor,
        suffixIcon:
            icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }

  // --- ADDED: Seat Layout Editor ---
  // List of blocked seat IDs
  final List<int> _blockedSeats = [];

  Widget _buildSeatLayoutEditor() {
    // 40 seats: 4 Columns x 10 Rows (plus aisle) => 5 columns visually
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            const Text("Seat Layout (Manage Availability)",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _legendItem(Colors.white, "Available", Colors.grey),
                _legendItem(Colors.orange, "Blocked", null), // Shortened text
                _legendItem(Colors.red.shade100, "Booked", null),
              ],
            )
          ],
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 24),

        // CENTERED COMPACT BUS LAYOUT
        Center(
          child: Container(
            width: 340, // Fixed width to match real bus feel
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(60), bottom: Radius.circular(30)),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Driver / Front Area
                Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Colors.black12))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.exit_to_app, color: Colors.grey),
                      Column(
                        children: [
                          const Icon(Icons.print, size: 20, color: Colors.grey),
                          const SizedBox(height: 8),
                          // Simple Steering Wheel Icon replacement
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey)),
                            child: const Icon(Icons.directions_car,
                                size: 20, color: Colors.grey),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seat Grid
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 10, // 10 Rows
                  itemBuilder: (context, rowIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Side (2 Seats)
                          Row(
                            children: [
                              _seatItem(rowIndex * 4 + 1),
                              const SizedBox(width: 14), // Gap between seats
                              _seatItem(rowIndex * 4 + 2),
                            ],
                          ),
                          // Aisle Text (Middle)
                          if (rowIndex == 4)
                            const Text("EXIT",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),

                          // Right Side (2 Seats)
                          Row(
                            children: [
                              _seatItem(rowIndex * 4 + 3),
                              const SizedBox(width: 14), // Gap between seats
                              _seatItem(rowIndex * 4 + 4),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                // Back of bus line
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4)),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, Color? borderColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
      ],
    );
  }

  Widget _seatItem(int seatNum) {
    bool isBooked = false;
    if (isEditing && widget.trip != null) {
      isBooked = widget.trip!.bookedSeats.contains(seatNum);
    }

    // Check local blocked state first, then initial trip blocked state (if editing)
    bool isBlocked = _blockedSeats.contains(seatNum);
    // If we initialized _blockedSeats in initState, we don't need to check widget.trip.blockedSeats here explicitly
    // because initState logic handles it (see below addition to initState).

    Color bgColor = Colors.white;
    Color? borderColor = Colors.red; // Changed to Red
    Color textColor = Colors.red; // Changed to Red

    if (isBooked) {
      bgColor = Colors.red.shade100;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade700;
    } else if (isBlocked) {
      // AMBER / YELLOW for Blocked
      bgColor = Colors.amber;
      borderColor = Colors.amber.shade700;
      textColor = Colors.black; // High contrast on Yellow
    }

    return InkWell(
      onTap: () {
        if (isBooked) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Cannot block a booked seat."),
            duration: Duration(milliseconds: 1000),
          ));
          return;
        }
        setState(() {
          if (_blockedSeats.contains(seatNum)) {
            _blockedSeats.remove(seatNum);
          } else {
            _blockedSeats.add(seatNum);
          }
        });
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            "$seatNum",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
