import 'package:flutter/material.dart';

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

  void _showRouteDialog({RouteModel? route}) {
    final isEditing = route != null;
    final formKey = GlobalKey<FormState>();

    // Controllers
    final fromController = TextEditingController(text: route?.fromCity ?? '');
    final toController = TextEditingController(text: route?.toCity ?? '');
    final priceController =
        TextEditingController(text: route?.price.toString() ?? '');
    final operatorController =
        TextEditingController(text: route?.operatorName ?? 'NTC');
    final busNoController = TextEditingController(text: route?.busNumber ?? '');

    // Time & Duration
    TimeOfDay departureTime = isEditing
        ? TimeOfDay(hour: route.departureHour, minute: route.departureMinute)
        : const TimeOfDay(hour: 8, minute: 0);

    TimeOfDay arrivalTime = isEditing
        ? TimeOfDay(hour: route.arrivalHour, minute: route.arrivalMinute)
        : const TimeOfDay(hour: 12, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? "Edit Route" : "Add New Route"),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: fromController,
                      decoration: const InputDecoration(labelText: "From City"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: toController,
                      decoration: const InputDecoration(labelText: "To City"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            decoration:
                                const InputDecoration(labelText: "Price (LKR)"),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: busNoController,
                            decoration: const InputDecoration(
                                labelText: "Default Bus No"),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: operatorController,
                      decoration:
                          const InputDecoration(labelText: "Operator Name"),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                  context: context, initialTime: departureTime);
                              if (t != null) setState(() => departureTime = t);
                            },
                            child:
                                Text("Dep: ${departureTime.format(context)}"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                  context: context, initialTime: arrivalTime);
                              if (t != null) setState(() => arrivalTime = t);
                            },
                            child: Text("Arr: ${arrivalTime.format(context)}"),
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
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newRoute = RouteModel(
                      id: isEditing
                          ? route.id
                          : '', // ID ignored on create, kept on update
                      fromCity: fromController.text.trim(),
                      toCity: toController.text.trim(),
                      departureHour: departureTime.hour,
                      departureMinute: departureTime.minute,
                      arrivalHour: arrivalTime.hour,
                      arrivalMinute: arrivalTime.minute,
                      price: double.tryParse(priceController.text) ?? 0,
                      operatorName: operatorController.text.trim(),
                      busNumber: busNoController.text.trim(),
                      busType: route?.busType ?? 'Normal',
                      platformNumber: route?.platformNumber ?? '1',
                      stops: route?.stops ?? [],
                      features: route?.features ?? [],
                      recurrenceDays:
                          route?.recurrenceDays ?? [1, 2, 3, 4, 5, 6, 7],
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
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.alt_route,
                        color: AppTheme.primaryColor),
                  ),
                  title: Text("${route.fromCity} ➔ ${route.toCity}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${route.operatorName} • LKR ${route.price.toStringAsFixed(0)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showRouteDialog(route: route),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(route),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRouteDialog(),
        label: const Text("Add Route"),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
