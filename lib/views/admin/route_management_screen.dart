import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import '../../models/schedule_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _service = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route & Schedule Management",
            style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: "Routes (Paths)", icon: Icon(Icons.map)),
            Tab(text: "Schedules (Operations)", icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRouteTab(),
          _buildScheduleTab(),
        ],
      ),
    );
  }

  // --- TAB 1: ROUTES ---

  Widget _buildRouteTab() {
    return StreamBuilder<List<RouteModel>>(
      stream: _service.getRoutesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final routes = snapshot.data!;
        if (routes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No routes defined."),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showRouteDialog(),
                  child: const Text("Add First Route"),
                )
              ],
            ),
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'addRouteBtn',
            onPressed: () => _showRouteDialog(),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.directions, color: Colors.white),
                  ),
                  title: Text("${route.originCity} ➝ ${route.destinationCity}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Via: ${route.via.isEmpty ? 'Direct' : route.via}\nDuration: ${_formatDuration(route.estimatedDurationMins)} • Stops: ${route.stops.length}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showRouteDialog(route: route),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(routeId: route.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes <= 0) return "0m";
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) {
      if (m > 0) return "${h}h ${m}m";
      return "${h}h";
    }
    return "${m}m";
  }

  void _showRouteDialog({RouteModel? route}) {
    final formKey = GlobalKey<FormState>();
    final fromCtrl = TextEditingController(text: route?.originCity ?? '');
    final toCtrl = TextEditingController(text: route?.destinationCity ?? '');
    final viaCtrl = TextEditingController(text: route?.via ?? '');

    // Duration Logic
    final initialMins = route?.estimatedDurationMins ?? 0;
    final initialH = initialMins ~/ 60;
    final initialM = initialMins % 60;

    final durationHoursCtrl =
        TextEditingController(text: initialH == 0 ? '' : initialH.toString());
    final durationMinsCtrl =
        TextEditingController(text: initialM == 0 ? '' : initialM.toString());

    // Stops could be a list, simplifying for now

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route == null ? "Add Route" : "Edit Route"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAutocomplete("From City", fromCtrl),
                const SizedBox(height: 12),
                _buildAutocomplete("To City", toCtrl),
                const SizedBox(height: 12),
                TextFormField(
                  controller: viaCtrl,
                  decoration:
                      const InputDecoration(labelText: "Via (Optional)"),
                ),
                const SizedBox(height: 12),
                // Duration Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: durationHoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: "Hours",
                            hintText: "4",
                            suffixText: "h",
                            border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: durationMinsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: "Minutes",
                            hintText: "30",
                            suffixText: "m",
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final h = int.tryParse(durationHoursCtrl.text) ?? 0;
                final m = int.tryParse(durationMinsCtrl.text) ?? 0;
                final totalMins = (h * 60) + m;

                final newRoute = RouteModel(
                  id: route?.id ?? '', // Ensure ID is handled (empty for new)
                  originCity: fromCtrl.text,
                  destinationCity: toCtrl.text,
                  stops: [], // Todo: Add stops UI
                  distanceKm: 0, // Todo: Add distance UI
                  estimatedDurationMins: totalMins,
                  isActive: true,
                  via: viaCtrl.text,
                );

                try {
                  if (route == null) {
                    await _service.addRoute(newRoute);
                  } else {
                    await _service.updateRoute(newRoute);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- TAB 2: SCHEDULES ---

  Widget _buildScheduleTab() {
    return StreamBuilder<List<ScheduleModel>>(
      stream: _service.getSchedulesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final schedules = snapshot.data!;
        // Need to fetch routes to display from/to
        // Ideally we would join this data. For now, we will just show schedule ID or fetch async.
        // Actually, fetching all routes to map ID -> Name is better.

        return StreamBuilder<List<RouteModel>>(
          stream: _service.getRoutesStream(),
          builder: (context, routeSnap) {
            if (!routeSnap.hasData) return const SizedBox();
            final routeMap = {for (var r in routeSnap.data!) r.id!: r};

            if (schedules.isEmpty) {
              return Center(
                child: ElevatedButton(
                  onPressed: () =>
                      _showScheduleDialog(routeMap.values.toList()),
                  child: const Text("Create First Schedule"),
                ),
              );
            }

            return Scaffold(
              floatingActionButton: FloatingActionButton(
                heroTag: 'addScheduleBtn',
                onPressed: () => _showScheduleDialog(routeMap.values.toList()),
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.add),
              ),
              body: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  final route = routeMap[schedule.routeId];
                  final routeName = route != null
                      ? "${route.originCity} ➝ ${route.destinationCity}"
                      : "Unknown Route (${schedule.routeId})";

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(routeName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(schedule.departureTime,
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              "Operator: ${schedule.operatorName} • Bus: ${schedule.busNumber}"),
                          Text("Price: LKR ${schedule.basePrice}"),
                          Text(
                              "Days: ${_getDaysString(schedule.recurrenceDays)}"),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.autorenew, size: 18),
                                label: const Text("Generate Trips"),
                                onPressed: () =>
                                    _showGenerateDialog(schedule, route),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showScheduleDialog(
                                    routeMap.values.toList(),
                                    schedule: schedule),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _confirmDelete(scheduleId: schedule.id),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showScheduleDialog(List<RouteModel> routes, {ScheduleModel? schedule}) {
    if (routes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please create a Route first.")));
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? selectedRouteId = schedule?.routeId ?? routes.first.id;
    final operatorCtrl =
        TextEditingController(text: schedule?.operatorName ?? '');
    final busNumCtrl = TextEditingController(text: schedule?.busNumber ?? '');
    final priceCtrl = TextEditingController(
        text: schedule?.basePrice.toStringAsFixed(0) ?? '');
    final conductorIdCtrl =
        TextEditingController(text: schedule?.conductorId ?? '');
    TimeOfDay selectedTime = schedule != null
        ? TimeOfDay(
            hour: int.parse(schedule.departureTime.split(':')[0]),
            minute: int.parse(schedule.departureTime.split(':')[1]))
        : const TimeOfDay(hour: 8, minute: 0);

    List<int> selectedDays = schedule != null
        ? List.from(schedule.recurrenceDays)
        : [1, 2, 3, 4, 5, 6, 7];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(schedule == null ? "Add Schedule" : "Edit Schedule"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRouteId,
                    items: routes.map((r) {
                      return DropdownMenuItem(
                          value: r.id,
                          child:
                              Text("${r.originCity} - ${r.destinationCity}"));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedRouteId = v),
                    decoration: const InputDecoration(labelText: "Route"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                        controller: operatorCtrl,
                        decoration:
                            const InputDecoration(labelText: "Operator"),
                        validator: (v) =>
                            v?.isEmpty ?? true ? "Required" : null,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextFormField(
                        controller: busNumCtrl,
                        decoration: const InputDecoration(labelText: "Bus No"),
                        validator: (v) =>
                            v?.isEmpty ?? true ? "Required" : null,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: "Price (LKR)"),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: conductorIdCtrl,
                    decoration: const InputDecoration(
                        labelText: "Conductor ID (Optional)"),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text("Departure Time"),
                    trailing: Text(selectedTime.format(context)),
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: selectedTime);
                      if (t != null) setState(() => selectedTime = t);
                    },
                    tileColor: Colors.grey.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  const SizedBox(height: 12),
                  const Text("Operating Days",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = selectedDays.contains(day);
                      final dayName =
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
                      return FilterChip(
                        label: Text(dayName),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }),
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final timeStr =
                      "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
                  final newSchedule = ScheduleModel(
                    id: schedule?.id ?? '',
                    routeId: selectedRouteId!,
                    busNumber: busNumCtrl.text,
                    operatorName: operatorCtrl.text,
                    departureTime: timeStr,
                    basePrice: double.parse(priceCtrl.text),
                    recurrenceDays: selectedDays,
                    amenities: [],
                    busType: 'Standard',
                    totalSeats: 40,
                    conductorId: conductorIdCtrl.text.isNotEmpty
                        ? conductorIdCtrl.text
                        : null,
                  );

                  try {
                    if (schedule == null) {
                      await _service.addSchedule(newSchedule);
                    } else {
                      await _service.updateSchedule(newSchedule);
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text("Save"),
            )
          ],
        );
      }),
    );
  }

  void _showGenerateDialog(ScheduleModel schedule, RouteModel? route) {
    if (route == null) return;
    final daysCtrl = TextEditingController(text: "30");
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Generate Trips"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "Generate trips for ${schedule.busNumber} on route ${route.originCity}-${route.destinationCity}."),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: daysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Days Ahead"),
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final days = int.parse(daysCtrl.text);
                      final count = await _service.generateTripsForSchedule(
                          schedule, route, days);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Generated $count trips.")));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Generate"),
                )
              ],
            ));
  }

  void _confirmDelete({String? routeId, String? scheduleId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                if (routeId != null) await _service.deleteRoute(routeId);
                if (scheduleId != null) {
                  await _service.deleteSchedule(scheduleId);
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocomplete(String label, TextEditingController controller) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return const Iterable<String>.empty();
        return AppConstants.cities.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) => controller.text = selection,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        if (controller.text.isNotEmpty && textEditingController.text.isEmpty) {
          textEditingController.text = controller.text;
        }
        // Use onChanged to keep controller in sync if user types manually
        // Simplified for brevity
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (v) => controller.text = v,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? "Required" : null,
        );
      },
    );
  }

  String _getDaysString(List<int> days) {
    if (days.length == 7) return "Daily";
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[d - 1]).join(', ');
  }
}
