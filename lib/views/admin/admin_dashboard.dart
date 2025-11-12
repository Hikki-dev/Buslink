// lib/views/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
// FIX: Removed unused import for 'trip_model.dart'
import 'admin_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Staff Dashboard")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.allTripsForAdmin.length,
        itemBuilder: (ctx, i) {
          final trip = controller.allTripsForAdmin[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(
                "${trip.busNumber} - ${trip.fromCity} to ${trip.toCity}",
              ),
              subtitle: Text(
                "Platform: ${trip.platformNumber} | Status: ${trip.status.name}",
              ),
              trailing: const Icon(Icons.edit),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminScreen(trip: trip)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
