// lib/views/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// <-- FIX: Import the new TripController
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';

class AdminScreen extends StatefulWidget {
  final Trip trip;
  const AdminScreen({super.key, required this.trip});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late TextEditingController _platformController;
  late TextEditingController _delayController;
  TripStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _platformController = TextEditingController(
      text: widget.trip.platformNumber,
    );
    _delayController = TextEditingController(
      text: widget.trip.delayMinutes.toString(),
    );
    _selectedStatus = widget.trip.status;
  }

  @override
  Widget build(BuildContext context) {
    // <-- FIX: Use the new TripController
    final controller = Provider.of<TripController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Edit: ${widget.trip.busNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Platform Update
          TextField(
            controller: _platformController,
            decoration: const InputDecoration(
              labelText: 'Platform Number',
              border: OutlineInputBorder(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // <-- FIX: Call the correct method
              controller.updatePlatform(
                widget.trip.id,
                _platformController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Update Platform'),
          ),
          const Divider(height: 30),

          // Status Update
          DropdownButtonFormField<TripStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Trip Status',
              border: OutlineInputBorder(),
            ),
            items: TripStatus.values
                .map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status.name)),
                )
                .toList(),
            onChanged: (status) {
              setState(() {
                _selectedStatus = status;
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _delayController,
            decoration: const InputDecoration(
              labelText: 'Delay (minutes)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedStatus != null) {
                final delay = int.tryParse(_delayController.text) ?? 0;
                // <-- FIX: Call the correct method
                controller.updateStatus(
                  widget.trip.id,
                  _selectedStatus!,
                  delay,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }
}
