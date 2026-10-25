import 'layout/admin_shell.dart';
import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import '../../models/schedule_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';
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
  Widget build(BuildContext context) =>
      AdminShell(selected: 2, child: _buildPage(context));

  int _tab = 0; // 0 routes, 1 schedules

  Widget _pill(String label, bool on, VoidCallback onTap) => Semantics(
        button: true,
        selected: on,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? BL.crimson : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: on ? BL.crimson : BL.border, width: 1.5),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : BL.ink)),
          ),
        ),
      );

  Widget _obtn(String label, VoidCallback onTap, {Color color = BL.ink}) =>
      SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          child: Text(label),
        ),
      );

  /// A bordered table: [head] titles with flex widths, then one row per item.
  Widget _table(List<(String, int)> head, List<List<Widget>> rows) {
    final box = Container(
      decoration: BoxDecoration(
        border: Border.all(color: BL.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          color: const Color(0xFFF5F3F4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            for (final h in head)
              Expanded(
                flex: h.$2,
                child: Text(h.$1,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: BL.muted)),
              ),
          ]),
        ),
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEDE6E7)))),
            child: Row(children: [
              for (var i = 0; i < r.length; i++)
                Expanded(flex: head[i].$2, child: r[i]),
            ]),
          ),
      ]),
    );
    if (MediaQuery.sizeOf(context).width >= 700) return box;
    // On a phone the columns keep their width and the table slides sideways.
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 720, child: box));
  }

  Widget _buildPage(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        if (!desktop) const BlHeader(title: 'Routes and schedules'),
        Expanded(
            child: SingleChildScrollView(
          padding: desktop
              ? const EdgeInsets.fromLTRB(36, 32, 36, 48)
              : const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Route & Schedule Management',
                          style: TextStyle(
                              fontSize: desktop ? 34 : 24,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                          'A route is the path. A schedule says which bus runs it and when.',
                          style: TextStyle(fontSize: 17, color: BL.muted)),
                    ],
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _showRouteDialog(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BL.crimson,
                          side: const BorderSide(color: BL.crimson, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.w800),
                        ),
                        child: const Text('Add Route'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () async {
                          final routes = await _service.getRoutesStream().first;
                          if (mounted) _showScheduleDialog(routes);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: BL.crimson,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.w800),
                        ),
                        child: const Text('Add Schedule'),
                      ),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _pill('Routes (Paths)', _tab == 0,
                      () => setState(() => _tab = 0)),
                  const SizedBox(width: 8),
                  _pill('Schedules (Operations)', _tab == 1,
                      () => setState(() => _tab = 1)),
                ]),
              ),
              const SizedBox(height: 18),
              _tab == 0 ? _buildRouteTab() : _buildScheduleTab(),
            ],
          ),
        ))
      ]),
    );
  }

  // --- ROUTES ---

  Widget _buildRouteTab() {
    return StreamBuilder<List<RouteModel>>(
      stream: _service.getRoutesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const BlEmpty(
              icon: Icons.cloud_off,
              title: 'We could not load the routes',
              message: 'Check the connection and try again.');
        }
        if (!snapshot.hasData) {
          return const Padding(
              padding: EdgeInsets.all(40),
              child:
                  Center(child: CircularProgressIndicator(color: BL.crimson)));
        }
        final routes = snapshot.data!;
        if (routes.isEmpty) {
          return Column(children: [
            const BlEmpty(
                icon: Icons.map_outlined, title: 'No routes defined.'),
            FilledButton(
              onPressed: () => _showRouteDialog(),
              style: FilledButton.styleFrom(backgroundColor: BL.crimson),
              child: const Text('Add First Route'),
            ),
          ]);
        }
        return _table(const [
          ('Route', 4),
          ('Via', 3),
          ('Duration', 2),
          ('Actions', 3)
        ], [
          for (final r in routes)
            [
              Text('${r.originCity} to ${r.destinationCity}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(r.via.isEmpty ? 'Direct' : r.via,
                  style: const TextStyle(fontSize: 16, color: BL.muted)),
              Text(_formatDuration(r.estimatedDurationMins),
                  style: const TextStyle(fontSize: 16)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _obtn('Edit', () => _showRouteDialog(route: r)),
                _obtn('Delete', () => _confirmDelete(routeId: r.id),
                    color: const Color(0xFFA3281C)),
              ]),
            ]
        ]);
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
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Route saved successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
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
          return const BlEmpty(
              icon: Icons.cloud_off,
              title: 'We could not load the schedules',
              message: 'Check the connection and try again.');
        }
        if (!snapshot.hasData) {
          return const Padding(
              padding: EdgeInsets.all(40),
              child:
                  Center(child: CircularProgressIndicator(color: BL.crimson)));
        }
        final schedules = snapshot.data!;
        return StreamBuilder<List<RouteModel>>(
          stream: _service.getRoutesStream(),
          builder: (context, routeSnap) {
            if (!routeSnap.hasData) return const SizedBox();
            final routeMap = {for (var r in routeSnap.data!) r.id: r};
            if (schedules.isEmpty) {
              return Column(children: [
                const BlEmpty(icon: Icons.schedule, title: 'No schedules yet.'),
                FilledButton(
                  onPressed: () =>
                      _showScheduleDialog(routeMap.values.toList()),
                  style: FilledButton.styleFrom(backgroundColor: BL.crimson),
                  child: const Text('Create First Schedule'),
                ),
              ]);
            }
            return _table(const [
              ('Route', 3),
              ('Operator', 2),
              ('Bus No', 2),
              ('Departure', 2),
              ('Operating Days', 3),
              ('Price', 2),
              ('Actions', 4)
            ], [
              for (final sc in schedules)
                () {
                  final route = routeMap[sc.routeId];
                  return <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            route != null
                                ? '${route.originCity} to ${route.destinationCity}'
                                : 'A route that was deleted',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        if (route != null)
                          Text(route.via.isEmpty ? 'Direct' : route.via,
                              style: const TextStyle(
                                  fontSize: 15, color: BL.muted)),
                      ],
                    ),
                    Text(sc.operatorName, style: const TextStyle(fontSize: 16)),
                    Text(sc.busNumber, style: const TextStyle(fontSize: 16)),
                    Text(sc.departureTime,
                        style: const TextStyle(fontSize: 16)),
                    Text(_getDaysString(sc.recurrenceDays),
                        style: const TextStyle(fontSize: 16)),
                    Text('LKR ${sc.basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16)),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _obtn(
                          'Edit',
                          () => _showScheduleDialog(routeMap.values.toList(),
                              schedule: sc)),
                      _obtn('Generate Trips',
                          () => _showGenerateDialog(sc, route),
                          color: BL.crimson),
                      _obtn('Delete', () => _confirmDelete(scheduleId: sc.id),
                          color: const Color(0xFFA3281C)),
                    ]),
                  ];
                }()
            ]);
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
    // Validate initial selectedRouteId
    if (routes.isNotEmpty && !routes.any((r) => r.id == selectedRouteId)) {
      selectedRouteId = routes.first.id;
    }

    final operatorCtrl =
        TextEditingController(text: schedule?.operatorName ?? '');
    final busNumCtrl = TextEditingController(text: schedule?.busNumber ?? '');
    final platformCtrl = TextEditingController(text: schedule?.platform ?? '');
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
                    initialValue: selectedRouteId,
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
                  TextFormField(
                    controller: platformCtrl,
                    decoration: const InputDecoration(
                        labelText: "Platform (optional)",
                        helperText: "Shown on tickets when set"),
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
                    platform: platformCtrl.text.trim(),
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
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Schedule saved successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
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
                      if (context.mounted) {
                        String err = "Error: $e";
                        if (e.toString().contains("failed-precondition") ||
                            e.toString().contains("index")) {
                          err =
                              "Configuration Error: Missing Database Index. Please contact support.";
                        }
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(err)));
                      }
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
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Item deleted successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Error: $e")));
                }
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
