import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/bus_controller.dart';
import '../../models/trip_model.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BusController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Staff Dashboard")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.allTrips.length,
        itemBuilder: (ctx, i) {
          final trip = controller.allTrips[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${trip.busNumber} - ${trip.toCity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  
                  // ADM-14: Platform Assignment
                  TextFormField(
                    initialValue: trip.platformNumber,
                    decoration: const InputDecoration(labelText: "Platform No.", prefixIcon: Icon(Icons.signpost)),
                    onChanged: (val) => controller.updatePlatform(trip.id, val),
                  ),
                  const SizedBox(height: 16),

                  // ADM-05: Delay/Cancel Panel
                  const Text("Trip Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _statusBtn(
                          context, 
                          "On Time", 
                          Colors.green, 
                          trip.status == TripStatus.onTime,
                          () => controller.updateStatus(trip.id, TripStatus.onTime, 0)
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusBtn(
                          context, 
                          "Delay", 
                          Colors.orange, 
                          trip.status == TripStatus.delayed,
                          () => controller.updateStatus(trip.id, TripStatus.delayed, 30)
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusBtn(
                          context, 
                          "Cancel", 
                          Colors.red, 
                          trip.status == TripStatus.cancelled,
                          () => controller.updateStatus(trip.id, TripStatus.cancelled, 0)
                        ),
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
  }

  Widget _statusBtn(BuildContext context, String label, Color color, bool isActive, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}