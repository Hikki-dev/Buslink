import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/trip_model.dart';
import '../../utils/app_theme.dart';
import '../../services/location_service.dart';
import 'package:provider/provider.dart'; // Added
import '../../utils/language_provider.dart'; // Added

class TrackBusScreen extends StatefulWidget {
  final Trip trip;
  const TrackBusScreen({super.key, required this.trip});

  @override
  State<TrackBusScreen> createState() => _TrackBusScreenState();
}

class _TrackBusScreenState extends State<TrackBusScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentBusPos;
  bool _hasCentered = false; // Track if we have auto-centered once

  @override
  Widget build(BuildContext context) {
    // Basic route points (approximate for demo)
    // Ideally we fetch actual route points. For now, straight line.
    // Parsing City locations is hard without a geocoder.
    // We will center map on Bus Location primarily.

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Live Tracking",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color)),
            Text("${widget.trip.fromCity} > ${widget.trip.toCity}",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color)), // Theme color
          ],
        ),
      ),
      body: StreamBuilder<LatLng?>(
        stream: LocationService().getBusLocationStream(widget.trip.id),
        builder: (context, snapshot) {
          final lp = Provider.of<LanguageProvider>(context); // Get Provider
          if (snapshot.hasData && snapshot.data != null) {
            _currentBusPos = snapshot.data!;
            // Auto-center ONLY once when we first get a signal
            if (!_hasCentered) {
              _hasCentered = true;
              // Use a microtask to avoid build collisions
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(_currentBusPos!, 15.0);
              });
            }
          }

          final displayPos = _currentBusPos ??
              (widget.trip.currentLocation != null
                  ? LatLng(widget.trip.currentLocation!['lat']!,
                      widget.trip.currentLocation!['lng']!)
                  : const LatLng(7.8731, 80.7718));

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: displayPos,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.buslink.app',
              ),
              MarkerLayer(
                markers: [
                  if (_currentBusPos != null)
                    Marker(
                      point: _currentBusPos!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4)
                              ],
                              border: Border.all(
                                  color: AppTheme.primaryColor, width: 3),
                            ),
                            child: const Icon(Icons.directions_bus,
                                color: AppTheme.primaryColor, size: 24),
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(widget.trip.busNumber,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)))
                        ],
                      ),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ]),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: _currentBusPos != null
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Icon(Icons.gps_fixed,
                            color: _currentBusPos != null
                                ? Colors.green
                                : Colors.orange),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                _currentBusPos != null
                                    ? lp.translate('signal_active')
                                    : lp.translate('waiting_signal'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold)),
                            Text(
                                _currentBusPos != null
                                    ? lp.translate('bus_moving')
                                    : lp.translate('bus_no_update'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_currentBusPos != null) {
            _mapController.move(_currentBusPos!, 16.0);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    Provider.of<LanguageProvider>(context, listen: false)
                        .translate('waiting_signal'))));
          }
        },
        label: const Text("Recenter"),
        icon: const Icon(Icons.my_location),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
