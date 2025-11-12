// lib/views/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import 'admin_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Staff Dashboard")),
      body: Consumer<TripController>(
        // <-- 1. WRAP with Consumer
        builder: (context, controller, child) {
          // 2. SHOW loading spinner
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. SHOW empty message
          if (controller.allTripsForAdmin.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "No trips found. Add trips to your Firestore 'trips' collection to see them here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // 4. SHOW the list (your original code)
          return ListView.builder(
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
                      MaterialPageRoute(
                        builder: (_) => AdminScreen(trip: trip),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
