// lib/views/conductor/conductor_trip_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';

class ConductorTripManagementScreen extends StatelessWidget {
  final Trip trip;
  const ConductorTripManagementScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<TripController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Manage Trip: ${trip.busNumber}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display Trip Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${trip.fromCity} to ${trip.toCity}",
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      "Departing: ${DateFormat('MMM d, hh:mm a').format(trip.departureTime)}",
                      style: theme.textTheme.titleMedium,
                    ),
                    Consumer<TripController>(
                      builder: (context, consumerController, child) {
                        final currentTrip =
                            consumerController.conductorSelectedTrip ?? trip;
                        return Text(
                          "Current Status: ${currentTrip.status.name}",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 30),

            // --- Status Buttons ---
            ElevatedButton(
              onPressed: () => _showDelayDialog(context, controller, trip),
              child: const Text("Set Bus Delayed"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.updateTripStatusAsConductor(
                  context,
                  trip,
                  TripStatus.arrived,
                  0,
                );
              },
              child: const Text("Set Bus Arrived"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.updateTripStatusAsConductor(
                  context,
                  trip,
                  TripStatus
                      .departed, // You'll need to add 'departed' to your TripStatus enum
                  0,
                );
              },
              child: const Text("Set Bus Departed"),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper to show delay dialog ---
  Future<void> _showDelayDialog(
      BuildContext context, TripController controller, Trip trip) async {
    final delayController = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Delay"),
        content: TextField(
          controller: delayController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Delay in minutes",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final delay = int.tryParse(delayController.text) ?? 0;
              controller.updateTripStatusAsConductor(
                context,
                trip,
                TripStatus.delayed,
                delay,
              );
              Navigator.pop(ctx);
            },
            child: const Text("Set Delay"),
          ),
        ],
      ),
    );
  }
}
