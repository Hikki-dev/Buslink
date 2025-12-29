import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';

class ConductorTripManagementScreen extends StatelessWidget {
  final Trip trip;
  const ConductorTripManagementScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);

    // If trip status updates, we want to reflect it.
    // Ideally we stream the specific trip, but for now we rely on the passed trip or controller state.
    // If the controller holds state for 'conductorSelectedTrip', use that.
    final currentTrip = controller.conductorSelectedTrip?.id == trip.id
        ? (controller.conductorSelectedTrip ?? trip)
        : trip;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Update Status",
            style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Trip T${currentTrip.id.substring(0, 4).toUpperCase()}",
                      style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark ? Colors.white70 : Colors.grey.shade500,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("${currentTrip.fromCity} ➔ ${currentTrip.toCity}",
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                          DateFormat('hh:mm a')
                              .format(currentTrip.departureTime),
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(width: 24),
                      Icon(Icons.directions_bus,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 8),
                      Text(currentTrip.busNumber,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),

            Text("Update Trip Status",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),

            // STATUS BUTTONS
            _buildStatusButton(
                context,
                controller,
                currentTrip,
                "Departed",
                TripStatus.departed,
                Colors.green.shade600,
                Icons.departure_board),
            const SizedBox(height: 16),
            _buildStatusButton(
                context,
                controller,
                currentTrip,
                "On Way",
                TripStatus.onWay,
                Colors.blue.shade600,
                Icons.directions_bus_filled),
            const SizedBox(height: 16),
            _buildStatusButton(context, controller, currentTrip, "Arrived",
                TripStatus.arrived, Colors.green.shade800, Icons.check_circle),
            const SizedBox(height: 16),
            _buildStatusButton(
                context,
                controller,
                currentTrip,
                "Delayed",
                TripStatus.delayed,
                Colors.red.shade600,
                Icons.warning_amber_rounded,
                isDelay: true),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "Current Status: ${currentTrip.status.name.toUpperCase()}",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(currentTrip.status)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    if (status == TripStatus.delayed) {
      return Colors.red;
    }
    if (status == TripStatus.arrived || status == TripStatus.departed) {
      return Colors.green;
    }
    if (status == TripStatus.onWay) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  Widget _buildStatusButton(BuildContext context, TripController controller,
      Trip trip, String label, TripStatus status, Color color, IconData icon,
      {bool isDelay = false}) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () async {
          int delay = 0;
          if (isDelay) {
            // Show dialog to ask for delay minutes
            final int? newDelay = await showDialog<int>(
              context: context,
              builder: (ctx) {
                final TextEditingController delayController =
                    TextEditingController();
                return AlertDialog(
                  title: const Text("Report Delay"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Enter delay duration in minutes:"),
                      const SizedBox(height: 10),
                      TextField(
                        controller: delayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), hintText: "e.g. 15"),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (delayController.text.isNotEmpty) {
                          Navigator.pop(
                              ctx, int.tryParse(delayController.text));
                        }
                      },
                      child: const Text("Confirm"),
                    ),
                  ],
                );
              },
            );

            if (newDelay == null) return; // Cancelled
            delay = newDelay;
          }
          if (context.mounted) {
            controller.updateTripStatusAsConductor(
                context, trip, status, delay);
          }
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4),
      ),
    );
  }
}
