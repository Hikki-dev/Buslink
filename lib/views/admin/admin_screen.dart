import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../../controllers/trip_controller.dart';
import '../../data/cities.dart';
import '../../models/trip_model.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../models/route_model.dart';
import '../../utils/app_theme.dart';
import 'layout/admin_navbar.dart';
import 'layout/admin_footer.dart';

class AdminScreen extends StatefulWidget {
  final EnrichedTrip? trip;
  const AdminScreen({super.key, required this.trip});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();

  // A) Route Details
  RouteModel? _selectedRoute;
  String? _originCity;
  String? _destinationCity;
  String? _viaRoute;
  final TextEditingController _durationController = TextEditingController();

  // B) Schedule
  DateTime _departureTime = DateTime.parse("2023-01-01 08:00:00");
  DateTime _arrivalTime = DateTime.parse("2023-01-01 12:00:00");
  final List<String> _operatingDays = []; // Mon, Tue...
  bool _isRecurring = true;
  DateTime? _tripDate;
  TripStatus _tripStatus = TripStatus.scheduled;

  // C) Fare
  final TextEditingController _fareController = TextEditingController();

  // Extra (Bus)
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _operatorController = TextEditingController();
  final TextEditingController _seatsController =
      TextEditingController(text: "40");
  final TextEditingController _platformController = TextEditingController();
  final List<String> _blockedSeats = [];

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
      _originCity = t.originCity;
      _destinationCity = t.destinationCity;
      _viaRoute = t.via.isNotEmpty ? t.via : null;

      // Duration formatting for UI (HH:mm)
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      // Duration getter might need helper on EnrichedTrip or calculate
      // EnrichedTrip has duration (from Route)? OR we rely on departure/arrival diff?
      // TripModel (Step 887) does NOT have duration.
      // EnrichedTrip (Step 788) has duration getter?
      // Let's assume we use diff.
      final d = t.arrivalTime.difference(t.departureTime);
      _durationController.text =
          "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}";

      _departureTime = t.departureTime;
      _arrivalTime = t.arrivalTime;

      // OperatingDays is List<int>
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

      // Map bookedSeats to _blockedSeats
      _blockedSeats.addAll(t.bookedSeats);

      // Status mapping string -> enum
      _tripStatus = TripStatus.values.firstWhere((e) => e.name == t.status,
          orElse: () => TripStatus.scheduled);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripController>(context, listen: false)
          .fetchAvailableCities();
      Provider.of<TripController>(context, listen: false)
          .fetchAvailableRoutes();
    });
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

    // Validation
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

    // Verify Duration Format
    final durationStr = _durationController.text;
    if (!durationStr.contains(':')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid duration (00:00).")));
      return;
    }

    final controller = Provider.of<TripController>(context, listen: false);

    // Prepare Base Data
    final tripData = {
      'fromCity': _originCity,
      'toCity': _destinationCity,
      'via': _viaRoute,
      'duration': durationStr,
      'operatingDays': _isRecurring ? _operatingDays : [],
      'price': double.tryParse(_fareController.text) ?? 0.0,
      'busNumber': _busNumberController.text.isNotEmpty
          ? _busNumberController.text
          : 'Standard Bus',
      'operatorName': _operatorController.text.isNotEmpty
          ? _operatorController.text
          : 'BusLink',
      'totalSeats': int.tryParse(_seatsController.text) ?? 40,
      'platformNumber': _platformController.text.isNotEmpty
          ? _platformController.text
          : 'TBD',
      'blockedSeats': _blockedSeats,
      'status': _tripStatus.name,
      'routeId': _selectedRoute?.id, // Saving Route ID
    };

    try {
      if (isEditing) {
        // UPDATE EXISTING TRIP
        if (_tripDate != null) {
          final d = _tripDate!;
          final newDep = DateTime(d.year, d.month, d.day, _departureTime.hour,
              _departureTime.minute);

          // Re-calculate arrival based on new duration
          final parts = durationStr.split(':');
          final durH = int.tryParse(parts[0]) ?? 0;
          final durM = int.tryParse(parts[1]) ?? 0;
          final newArr = newDep.add(Duration(hours: durH, minutes: durM));

          tripData['departureTime'] = newDep;
          tripData['arrivalTime'] = newArr;
        } else {
          // If no tripDate (e.g. recurring template fallback or just keeping old dates but changing time)
          // We generally expect _tripDate to be set for single trips.
          // For editing a generic recurring route "template" (if that existed), it's different.
          // But here we are usually editing a specific Trip Instance.
          tripData['departureTime'] = _departureTime;
          // Recalc arrival
          final parts = durationStr.split(':');
          final durH = int.tryParse(parts[0]) ?? 0;
          final durM = int.tryParse(parts[1]) ?? 0;
          final newArr =
              _departureTime.add(Duration(hours: durH, minutes: durM));
          tripData['arrivalTime'] = newArr;
        }

        await controller.updateTrip(widget.trip!.id, tripData);
      } else {
        // ADD NEW
        if (_isRecurring) {
          // RECURRING ROUTE GENERATION
          tripData['departureTime'] = _departureTime;
          // Arrival calc is done inside createRecurringRoute or here?
          // createRecurringRoute handles it based on Duration string.
          // We just pass the base time.
          tripData['arrivalTime'] = _arrivalTime; // Placeholder

          List<int> recurrenceDays =
              _operatingDays.map((d) => _daysOfWeek.indexOf(d) + 1).toList();
          await controller
              .createRecurringRoute({'data': tripData, 'days': recurrenceDays});
        } else {
          // SINGLE TRIP
          final d = _tripDate!;
          final newDep = DateTime(d.year, d.month, d.day, _departureTime.hour,
              _departureTime.minute);

          final parts = durationStr.split(':');
          final durH = int.tryParse(parts[0]) ?? 0;
          final durM = int.tryParse(parts[1]) ?? 0;
          DateTime newArr = newDep.add(Duration(hours: durH, minutes: durM));

          if (newArr.isBefore(newDep)) {
            newArr = newArr.add(const Duration(days: 1));
          }

          tripData['departureTime'] = newDep;
          tripData['arrivalTime'] = newArr;
          tripData['isGenerated'] = false;

          await controller.addTrip(tripData);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving: ${e.toString()}")));
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

                                      _buildRouteSelector(),
                                      const SizedBox(height: 24),

                                      _buildSectionHeader("A) Route Details"),

                                      // From / To
                                      Row(
                                        children: [
                                          Expanded(
                                              child: _buildCityAutocomplete(
                                                  "From (Origin)",
                                                  _originCity,
                                                  (v) => _originCity = v)),
                                          const SizedBox(width: 16),
                                          Expanded(
                                              child: _buildCityAutocomplete(
                                                  "To (Destination)",
                                                  _destinationCity,
                                                  (v) => _destinationCity = v)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Via / Duration
                                      _buildViaDurationRow(
                                          isDesktop,
                                          _viaOptions,
                                          _viaRoute,
                                          _durationController, (val) {
                                        setState(() {
                                          _viaRoute = val;
                                        });
                                      }),

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

                                      // Status Dropdown (Edits Only)
                                      if (isEditing) ...[
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<TripStatus>(
                                          key: ValueKey(_tripStatus),
                                          initialValue: _tripStatus,
                                          decoration: InputDecoration(
                                            labelText: "Trip Status",
                                            filled: true,
                                            fillColor: isDark
                                                ? Colors.grey
                                                    .withValues(alpha: 0.1)
                                                : Colors.grey.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          items: TripStatus.values.map((s) {
                                            return DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s.name.toUpperCase(),
                                                style:
                                                    TextStyle(color: textColor),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _tripStatus = val);
                                            }
                                          },
                                        ),
                                      ],

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
          final controller = Provider.of<TripController>(context);
          final cities = controller.availableCities.isNotEmpty
              ? controller.availableCities
              : kSriLankanCities;

          return cities.where((String option) {
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
              labelStyle: const TextStyle(),
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
          // Fix: Ensure controller matches initial value if not edited yet
          if (value != null &&
              textEditingController.text.isEmpty &&
              value != textEditingController.text) {
            // Only set if completely empty to avoid overwriting user typing?
            // Actually initialValue handles start.
            // This logic tracks external updates (setState) to the field.
            // Use a PostFrameCallback or just text assignment if safe.
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
              // Allow free text or filtering
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor)),
              focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppTheme.primaryColor, width: 2)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: inputFillColor,
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
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

  Widget _buildRouteSelector() {
    return Consumer<TripController>(builder: (context, controller, _) {
      final routes = controller.availableRoutes;
      if (routes.isEmpty) {
        return const SizedBox(); // Hide if no routes
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = Theme.of(context).colorScheme.onSurface;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route,
                    color: AppTheme.primaryColor.withValues(alpha: 0.8),
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  "Load details from saved route",
                  style: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RouteModel>(
              key: ValueKey(_selectedRoute),
              initialValue: _selectedRoute,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor:
                    isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.white,
                hintText: "Select a Route...",
                hintStyle: const TextStyle(),
              ),
              items: routes.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(
                    "${r.originCity} ➔ ${r.destinationCity} (Via: ${r.via.isNotEmpty ? r.via : 'Direct'})",
                    style: TextStyle(color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (RouteModel? route) {
                if (route != null) {
                  setState(() {
                    _selectedRoute = route;
                    _originCity = route.originCity;
                    _destinationCity = route.destinationCity;
                    _viaRoute = route.via;

                    // Calculate Duration String for the controller
                    final dH = route.estimatedDurationMins ~/ 60;
                    final dM = route.estimatedDurationMins % 60;
                    _durationController.text =
                        "${dH.toString().padLeft(2, '0')}:${dM.toString().padLeft(2, '0')}";
                  });
                }
              },
            ),
          ],
        ),
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
          labelStyle: const TextStyle(),
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
        labelStyle: const TextStyle(),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // FRONT EXIT
                      Column(
                        children: [
                          const Icon(Icons.sensor_door_outlined,
                              color: Colors.red, size: 24),
                          const SizedBox(height: 4),
                          Text("EXIT",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),

                      // Steering Wheel
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey)),
                        child: const Icon(Icons.directions_car,
                            size: 20, color: Colors.grey),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seat Grid
                // We use a Builder to calculate rows based on current input
                Builder(builder: (context) {
                  int totalSeats = int.tryParse(_seatsController.text) ?? 40;
                  // If less than 5, just show empty or basic
                  if (totalSeats < 5) return const SizedBox();

                  int normalRows = (totalSeats - 2) ~/ 4;
                  // Total items = Normal Rows + Last Row (which is handled manually)
                  // We'll just generate the normal rows list + exit + last row

                  return Column(
                    children: [
                      ...List.generate(normalRows, (index) {
                        int rowStart = index * 4;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                _seatItem(rowStart + 1),
                                const SizedBox(width: 14),
                                _seatItem(rowStart + 2),
                              ]),
                              Row(children: [
                                _seatItem(rowStart + 3),
                                const SizedBox(width: 14),
                                _seatItem(rowStart + 4),
                              ]),
                            ],
                          ),
                        );
                      }),

                      // Rear Exit
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(bottom: 12, left: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.sensor_door_outlined,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 4),
                            Text("EXIT",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      // Last Row (5 seats or remaining)
                      Builder(builder: (context) {
                        int start = normalRows * 4;
                        int seatsToShow = totalSeats - start;

                        // If exactly 4 seats, maintain aisle layout
                        if (seatsToShow == 4) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  _seatItem(start + 1),
                                  const SizedBox(width: 14),
                                  _seatItem(start + 2),
                                ]),
                                Row(children: [
                                  _seatItem(start + 3),
                                  const SizedBox(width: 14),
                                  _seatItem(start + 4),
                                ]),
                              ],
                            ),
                          );
                        }

                        // Otherwise (usually 5), spread them out
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(seatsToShow, (i) {
                            return _seatItem(start + i + 1);
                          }),
                        );
                      })
                    ],
                  );
                }),

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
    final seatStr = seatNum.toString();
    bool isBooked = false;
    if (isEditing && widget.trip != null) {
      isBooked = widget.trip!.bookedSeats.contains(seatStr);
    }

    // Check local blocked state first, then initial trip blocked state (if editing)
    bool isBlocked = _blockedSeats.contains(seatStr);
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
          if (_blockedSeats.contains(seatStr)) {
            _blockedSeats.remove(seatStr);
          } else {
            _blockedSeats.add(seatStr);
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

  Widget _buildViaDurationRow(bool isDesktop, List<String> items, String? value,
      TextEditingController durationCtrl, Function(String?) onViaChanged) {
    // Via Dropdown
    final viaWidget = _buildDropdown(
        "Via / Route Variant", value, items, (v) => onViaChanged(v));

    // Duration Fields (H & M)
    final durationWidget = Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final inputFillColor =
          isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.shade50;
      final borderColor =
          isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade300;

      // Parse current duration controller text (HH:MM) to init fields
      String initH = "";
      String initM = "";
      if (durationCtrl.text.contains(':')) {
        final parts = durationCtrl.text.split(':');
        if (parts.length == 2) {
          initH = parts[0];
          initM = parts[1];
        }
      }

      // Local controllers for the small fields
      // NOTE: We can't easily rely on local controllers if we want to sync perfectly with parent state
      // without keeping them in State. But since this is a build method, we'll initialize them
      // and update the main controller on change.
      // Ideally these should be in State, but for quick fix:
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: initH,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Hrs",
                filled: true,
                fillColor: inputFillColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor)),
              ),
              onChanged: (v) {
                final m = durationCtrl.text.contains(':')
                    ? durationCtrl.text.split(':')[1]
                    : "00";
                durationCtrl.text = "${v.padLeft(2, '0')}:$m";
                _calculateArrival();
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(":", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextFormField(
              initialValue: initM,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Mins",
                filled: true,
                fillColor: inputFillColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor)),
              ),
              onChanged: (v) {
                final h = durationCtrl.text.contains(':')
                    ? durationCtrl.text.split(':')[0]
                    : "00";
                durationCtrl.text = "$h:${v.padLeft(2, '0')}";
                _calculateArrival();
              },
            ),
          ),
        ],
      );
    });

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: viaWidget),
          const SizedBox(width: 16),
          Expanded(child: durationWidget), // Now holds the Row of H:M
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          viaWidget,
          const SizedBox(height: 16),
          durationWidget,
        ],
      );
    }
  }
}
