import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Added
// import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../services/location_service.dart'; // Added

import '../booking/seat_selection_screen.dart';

class ConductorTripManagementScreen extends StatefulWidget {
  final Trip trip;
  const ConductorTripManagementScreen({super.key, required this.trip});

  @override
  State<ConductorTripManagementScreen> createState() =>
      _ConductorTripManagementScreenState();
}

class _ConductorTripManagementScreenState
    extends State<ConductorTripManagementScreen> {
  Timer? _locationTimer;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    // 1. Permission Check
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      // Cannot track
      return;
    }

    // 2. Start Timer
    // We poll every 15s. The LocationService handles the "Moved enough?" logic.
    setState(() => _isTracking = true);

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!mounted) return;
      try {
        // High accuracy is fine because we throttle writes
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        await LocationService().updateBusLocation(
            widget.trip.id,
            position.latitude,
            position.longitude,
            position.speed,
            position.heading);
      } catch (e) {
        debugPrint("GPS Error: $e");
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);

    // If trip status updates, we want to reflect it.
    final currentTrip = controller.conductorSelectedTrip?.id == widget.trip.id
        ? (controller.conductorSelectedTrip ?? widget.trip)
        : widget.trip;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update Status",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            if (_isTracking)
              const Text("• Live Tracking Active",
                  style: TextStyle(fontSize: 12, color: Colors.green))
          ],
        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "Trip T${currentTrip.id.substring(0, 4).toUpperCase()}",
                          style: TextStyle(
                              fontFamily: 'Inter',
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.bold)),
                      if (_isTracking)
                        const Icon(Icons.gps_fixed,
                            color: Colors.green, size: 16)
                    ],
                  ),
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

            const SizedBox(height: 32),

            // CASHPAYMENT SECTION
            Text("Cash Ticketing",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showCashBookingDialog(context, controller, currentTrip),
                icon: const Icon(Icons.attach_money),
                label: const Text("Issue Cash Ticket",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4),
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

  void _showCashBookingDialog(
      BuildContext context, TripController controller, Trip trip) {
    // Initialize Controller State
    controller.selectedTrip = trip;
    controller.selectedSeats = [];

    // Navigate to Visual Seat Selection in Conductor Mode
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(
          trip: trip,
          isConductorMode: true,
        ),
      ),
    );
  }
}
