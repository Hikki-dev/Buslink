import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

import '../../models/route_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  final FirestoreService _service = FirestoreService();

  // Helper for Time Picking
  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) async {
    return showTimePicker(context: context, initialTime: initial);
  }

  void _showRouteDialog({RouteModel? route}) {
    final isEditing = route != null;
    final formKey = GlobalKey<FormState>();

    // Controllers
    final fromController = TextEditingController(text: route?.fromCity ?? '');
    final toController = TextEditingController(text: route?.toCity ?? '');
    final viaController = TextEditingController(text: route?.via ?? '');
    // final priceController = TextEditingController(text: route?.price.toStringAsFixed(0) ?? '0'); // Price Removed
    final platformController =
        TextEditingController(text: route?.platformNumber ?? '1');

    // State Variables for Dialog
    TimeOfDay departureTime = isEditing
        ? TimeOfDay(hour: route.departureHour, minute: route.departureMinute)
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay arrivalTime = isEditing
        ? TimeOfDay(hour: route.arrivalHour, minute: route.arrivalMinute)
        : const TimeOfDay(hour: 12, minute: 0);

    List<int> selectedDays =
        isEditing ? List.from(route.recurrenceDays) : [1, 2, 3, 4, 5, 6, 7];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          // final isDark = Theme.of(context).brightness == Brightness.dark; - Unused

          return AlertDialog(
            title: Text(isEditing ? "Edit Route" : "Add New Route",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 500, // Wider dialog
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- A. Basic Route Info ---
                      Text("A) Route Details",
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: fromController,
                              decoration: const InputDecoration(
                                  labelText: "From (City)",
                                  isDense: true,
                                  border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: toController,
                              decoration: const InputDecoration(
                                  labelText: "To (City)",
                                  isDense: true,
                                  border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: viaController,
                        decoration: const InputDecoration(
                            labelText: "Via / Route Variant",
                            hintText: "e.g. Expressway, Galle Road",
                            isDense: true,
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),

                      // --- B. Schedule & Days ---
                      Text("B) Schedule",
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t =
                                    await _pickTime(context, departureTime);
                                if (t != null)
                                  setState(() => departureTime = t);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: "Departure",
                                    border: OutlineInputBorder()),
                                child: Text(departureTime.format(context)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await _pickTime(context, arrivalTime);
                                if (t != null) setState(() => arrivalTime = t);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: "Arrival",
                                    border: OutlineInputBorder()),
                                child: Text(arrivalTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("Operating Days:",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Wrap(
                        spacing: 4,
                        children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                          final isSelected = selectedDays.contains(day);
                          final dayName =
                              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day - 1];
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
                                selectedDays.sort();
                              });
                            },
                            checkmarkColor: Colors.white,
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // --- C. Bus & Details ---
                      Text("C) Details",
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          /* 
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: "Price (LKR)",
                                  isDense: true,
                                  border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                          const SizedBox(width: 12), 
                          */
                          Expanded(
                            child: TextFormField(
                              controller: platformController,
                              decoration: const InputDecoration(
                                  labelText: "Platform",
                                  isDense: true,
                                  border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newRoute = RouteModel(
                      id: isEditing ? route.id : '',
                      fromCity: fromController.text.trim(),
                      toCity: toController.text.trim(),
                      departureHour: departureTime.hour,
                      departureMinute: departureTime.minute,
                      arrivalHour: arrivalTime.hour,
                      arrivalMinute: arrivalTime.minute,
                      price: 0, // Default to 0 as field is removed
                      operatorName: 'BusLink Official', // Default
                      busNumber: 'Standard', // Default
                      busType: route?.busType ?? 'Normal',
                      platformNumber: platformController.text.trim(),
                      stops: route?.stops ?? [],
                      features: route?.features ?? [],
                      via: viaController.text.trim(),
                      recurrenceDays: selectedDays,
                    );

                    if (isEditing) {
                      await _service.updateRoute(newRoute);
                    } else {
                      await _service.addRoute(newRoute);
                    }
                    if (context.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white),
                child: Text(isEditing ? "Update" : "Create"),
              )
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(RouteModel route) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Delete Route?"),
              content: Text(
                  "Are you sure you want to delete ${route.fromCity} - ${route.toCity}?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      await _service.deleteRoute(route.id);
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                    child: const Text("Delete"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route Management"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<RouteModel>>(
        stream: _service.getRoutesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No routes defined."));
          }

          final routes = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final route = routes[index];
              return _RouteCard(
                route: route,
                onEdit: () => _showRouteDialog(route: route),
                onDelete: () => _confirmDelete(route),
              );
            },
          );
        },
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RouteCard(
      {required this.route, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Format Time
    final dep =
        TimeOfDay(hour: route.departureHour, minute: route.departureMinute)
            .format(context);
    final arr = TimeOfDay(hour: route.arrivalHour, minute: route.arrivalMinute)
        .format(context);

    // Format Days
    String daysStr = "Daily";
    if (route.recurrenceDays.length < 7) {
      daysStr = route.recurrenceDays
          .map((d) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d - 1])
          .join(",");
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child:
                      const Icon(Icons.alt_route, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${route.fromCity} ➔ ${route.toCity}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (route.via.isNotEmpty)
                        Text("Via: ${route.via}",
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    //   Text("LKR ${route.price.toStringAsFixed(0)}",
                    //       style: const TextStyle(
                    //           fontWeight: FontWeight.bold,
                    //           color: Colors.green,
                    //           fontSize: 16)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text("$dep - $arr",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(daysStr,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text("Edit"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                    label: const Text("Delete",
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
