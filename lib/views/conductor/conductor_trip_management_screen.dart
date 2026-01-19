import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Added
// import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../models/trip_model.dart' show TripStatus;
import '../../services/location_service.dart'; // Added
// Added

import '../booking/seat_selection_screen.dart';
import '../../utils/language_provider.dart';

class ConductorTripManagementScreen extends StatefulWidget {
  final EnrichedTrip trip;
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
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high));

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
    // Not used here, fetched in stream builder
    // final currentTrip = widget.trip;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                Provider.of<LanguageProvider>(context)
                    .translate('update_status_title'),
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            if (_isTracking)
              Text(
                  "• ${Provider.of<LanguageProvider>(context).translate('live_tracking_active')}",
                  style: const TextStyle(fontSize: 12, color: Colors.green))
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        actions: [
          // Language Selector
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return PopupMenuButton<String>(
                icon: Icon(Icons.language,
                    color: isDark ? Colors.white : Colors.black),
                tooltip: "Change Language",
                onSelected: (String code) {
                  languageProvider.setLanguage(code);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'en',
                    child: Text('English'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'si',
                    child: Text('සිංහල (Sinhala)'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ta',
                    child: Text('தமிழ் (Tamil)'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<EnrichedTrip?>(
        stream: controller.getTripRealtimeStream(widget.trip.id),
        initialData: widget.trip,
        builder: (context, snapshot) {
          final currentTrip = snapshot.data ?? widget.trip;

          return SingleChildScrollView(
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
                          color:
                              isDark ? Colors.white10 : Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              "${Provider.of<LanguageProvider>(context).translate('trip_label')} T${currentTrip.id.substring(0, 4).toUpperCase()}",
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
                                  color:
                                      isDark ? Colors.white : Colors.black87)),
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
                                  color:
                                      isDark ? Colors.white : Colors.black87)),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // CASHPAYMENT SECTION
                Text(
                    Provider.of<LanguageProvider>(context)
                        .translate('cash_ticketing_title'),
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCashBookingDialog(
                        context, controller, currentTrip),
                    icon: const Icon(Icons.attach_money),
                    label: Text(
                        Provider.of<LanguageProvider>(context)
                            .translate('issue_cash_ticket'),
                        style: const TextStyle(
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

                Text(
                    Provider.of<LanguageProvider>(context)
                        .translate('update_trip_status_section'),
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
                    Provider.of<LanguageProvider>(context)
                        .translate('departed'),
                    TripStatus.departed,
                    Colors.green.shade600,
                    Icons.departure_board),
                const SizedBox(height: 16),
                _buildStatusButton(
                    context,
                    controller,
                    currentTrip,
                    Provider.of<LanguageProvider>(context).translate('on_way'),
                    TripStatus.onWay,
                    Colors.blue.shade600,
                    Icons.directions_bus_filled),
                const SizedBox(height: 16),
                _buildStatusButton(
                    context,
                    controller,
                    currentTrip,
                    Provider.of<LanguageProvider>(context).translate('arrived'),
                    TripStatus.arrived,
                    Colors.green.shade800,
                    Icons.check_circle),
                const SizedBox(height: 16),
                _buildStatusButton(
                    context,
                    controller,
                    currentTrip,
                    Provider.of<LanguageProvider>(context).translate('delayed'),
                    TripStatus.delayed,
                    Colors.red.shade600,
                    Icons.warning_amber_rounded,
                    isDelay: true),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "${Provider.of<LanguageProvider>(context).translate('current_status_label')}: ${_getTranslatedStatus(context, currentTrip.status)}",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(currentTrip.status)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase(); // Normalize
    if (s == 'delayed') return Colors.red;
    if (s == 'arrived' || s == 'departed' || s == 'completed') {
      return Colors.green;
    }
    if (s == 'onway' || s == 'on way') return Colors.blue;
    return Colors.grey;
  }

  Widget _buildStatusButton(
      BuildContext context,
      TripController controller,
      EnrichedTrip trip,
      String label,
      TripStatus status,
      Color color,
      IconData icon,
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
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Updating status...")));
              await controller.updateTripStatusAsConductor(trip.id, status,
                  delayMinutes: delay);
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Trip marked as $label. Passengers notified (Push)."),
                    backgroundColor: Colors.green));

                // Dialog removed for efficiency & privacy (SMS disabled)
                // bool? notify = await showDialog... <- Removed
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Failed to update status: $e"),
                    backgroundColor: Colors.red));
              }
            }
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
      BuildContext context, TripController controller, EnrichedTrip trip) {
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

  String _getTranslatedStatus(BuildContext context, String status) {
    final s = status.toLowerCase();
    final lang = Provider.of<LanguageProvider>(context);
    if (s == 'departed') return lang.translate('departed');
    if (s == 'onway' ||
        s == 'on_way' ||
        s == 'inprogress' ||
        s == 'in_progress') {
      return lang.translate('on_way');
    }
    if (s == 'arrived') return lang.translate('arrived');
    if (s == 'delayed') return lang.translate('delayed');
    if (s == 'scheduled') return lang.translate('scheduled');
    if (s == 'cancelled') return lang.translate('cancelled');
    if (s == 'completed') return lang.translate('stat_completed');
    return status.toUpperCase();
  }
}
