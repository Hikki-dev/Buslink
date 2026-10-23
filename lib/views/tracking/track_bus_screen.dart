import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../data/city_coords.dart';
import '../../models/trip_model.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';

/// Schedule-based progress of a trip: how long is left and how far along it
/// is. Pure maths (no Trip, no clock) so it is easy to test.
class TripEta {
  final Duration remaining;
  final double progress; // 0.0 - 1.0
  final DateTime expected;
  bool get arrived => remaining == Duration.zero;

  const TripEta._(this.remaining, this.progress, this.expected);

  factory TripEta.compute({
    required DateTime departure,
    required DateTime arrival,
    required int delayMinutes,
    required DateTime now,
  }) {
    final expected = arrival.add(Duration(minutes: delayMinutes));
    final total = expected.difference(departure).inSeconds;
    final done = now.difference(departure).inSeconds;
    final progress = total <= 0 ? 1.0 : (done / total).clamp(0.0, 1.0);
    final left = expected.difference(now);
    return TripEta._(
        left.isNegative ? Duration.zero : left, progress, expected);
  }
}

/// "42 min", "1 h 05 min", "Now".
String formatEta(Duration d) {
  if (d.inMinutes < 1) return 'Now';
  if (d.inHours == 0) return '${d.inMinutes} min';
  return '${d.inHours} h ${(d.inMinutes % 60).toString().padLeft(2, '0')} min';
}

/// Live bus tracking: a full-screen map with one calm bottom card.
class TrackBusScreen extends StatefulWidget {
  final Trip trip;
  const TrackBusScreen({super.key, required this.trip});

  @override
  State<TrackBusScreen> createState() => _TrackBusScreenState();
}

class _TrackBusScreenState extends State<TrackBusScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final Stream<LatLng?> _busStream =
      LocationService().getBusLocationStream(widget.trip.id);
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));
  Timer? _clock;
  LatLng? _busPos;
  bool _centered = false;

  Trip get _trip => widget.trip;
  LatLng? get _origin => kCityCoords[_trip.fromCity];
  LatLng? get _destination => kCityCoords[_trip.toCity];

  @override
  void initState() {
    super.initState();
    // Keep the "minutes left" fresh without hitting the network.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect "reduce motion": no pulsing ring.
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _recenter() {
    final pos = _busPos;
    if (pos != null) {
      _mapController.move(pos, 13);
    } else {
      _snack('Waiting for the bus to share its location.');
    }
  }

  void _share(TripEta eta) {
    final text = '${_trip.fromCity} to ${_trip.toCity}: arriving in '
        '${formatEta(eta.remaining)} '
        '(about ${DateFormat('h:mm a').format(eta.expected)}).';
    Clipboard.setData(ClipboardData(text: text));
    _snack('Trip update copied. Paste it into a message.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final eta = TripEta.compute(
      departure: _trip.departureTime,
      arrival: _trip.arrivalTime,
      delayMinutes: _trip.delayMinutes,
      now: DateTime.now(),
    );

    return Scaffold(
      body: StreamBuilder<LatLng?>(
        stream: _busStream,
        builder: (context, snapshot) {
          final live = snapshot.data;
          if (live != null) {
            _busPos = live;
            if (!_centered) {
              _centered = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _mapController.move(live, 13);
              });
            }
          }
          return Stack(
            children: [
              _buildMap(),
              _buildTopControls(eta),
              _buildSheet(context, eta),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    final origin = _origin;
    final destination = _destination;
    final fit = (origin != null && destination != null)
        ? CameraFit.coordinates(
            coordinates: [origin, destination],
            padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width > 900 ? 520 : 48,
                140,
                48,
                MediaQuery.of(context).size.width > 900 ? 140 : 420),
          )
        : null;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _busPos ?? const LatLng(7.8731, 80.7718),
        initialZoom: 7.5,
        initialCameraFit: fit,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.buslink.app',
        ),
        if (origin != null && destination != null)
          PolylineLayer(polylines: [
            // Straight line between the two cities: an outline of the trip,
            // not the road itself.
            Polyline(
              points: [origin, destination],
              strokeWidth: 5,
              color: AppTheme.primaryColor,
              pattern: StrokePattern.dashed(segments: const [12, 9]),
            ),
          ]),
        MarkerLayer(markers: [
          if (origin != null)
            Marker(
              point: origin,
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 4),
                ),
              ),
            ),
          if (destination != null)
            Marker(
              point: destination,
              width: 44,
              height: 44,
              alignment: Alignment.topCenter,
              child: const Icon(Icons.location_on,
                  size: 44, color: Colors.black87),
            ),
          if (_busPos != null)
            Marker(
              point: _busPos!,
              width: 64,
              height: 64,
              child: _BusMarker(
                pulse: _pulse,
                etaLabel: formatEta(TripEta.compute(
                  departure: _trip.departureTime,
                  arrival: _trip.arrivalTime,
                  delayMinutes: _trip.delayMinutes,
                  now: DateTime.now(),
                ).remaining),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _buildTopControls(TripEta eta) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RoundButton(
              icon: Icons.arrow_back,
              tooltip: 'Go back',
              onTap: () => Navigator.maybePop(context),
            ),
            Row(children: [
              _RoundButton(
                icon: Icons.ios_share,
                tooltip: 'Share trip update',
                onTap: () => _share(eta),
              ),
              const SizedBox(width: 10),
              _RoundButton(
                icon: Icons.my_location,
                tooltip: 'Centre the map on the bus',
                color: AppTheme.primaryColor,
                onTap: _recenter,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, TripEta eta) {
    final theme = Theme.of(context);
    final status = _trip.status.toLowerCase();
    final cancelled = status.contains('cancel');
    final late =
        !cancelled && (_trip.delayMinutes > 0 || status.contains('delay'));
    final hasSignal = _busPos != null;

    final headline = cancelled
        ? 'This trip was cancelled'
        : eta.arrived
            ? 'Arrived in ${_trip.toCity}'
            : 'Arriving in ${_trip.toCity}';

    // Wide screens: a floating card on the left, so the map stays the star.
    final wide = MediaQuery.of(context).size.width > 900;
    return Align(
      alignment: wide ? Alignment.centerLeft : Alignment.bottomCenter,
      child: Container(
        width: wide ? 440 : null,
        margin: wide ? const EdgeInsets.all(24) : null,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: wide
              ? BorderRadius.circular(28)
              : const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 24, offset: Offset(0, -6)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(headline,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 17, color: Colors.grey.shade700)),
                  if (!cancelled)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            eta.arrived ? 'Arrived' : formatEta(eta.remaining),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 44,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Expected',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700)),
                              Text(DateFormat('h:mm a').format(eta.expected),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (!cancelled) ...[
                    const SizedBox(height: 14),
                    _ProgressBar(progress: eta.progress),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_trip.fromCity,
                            style: TextStyle(color: Colors.grey.shade700)),
                        Text(_trip.toCity,
                            style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ],
                  const Divider(height: 30),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.directions_bus,
                            color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_trip.busNumber,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                            Text(_trip.operatorName,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                      _StatusPill(
                        cancelled: cancelled,
                        late: late,
                        delayMinutes: _trip.delayMinutes,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SignalRow(hasSignal: hasSignal),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: color ?? Colors.black87),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final x = c.maxWidth * progress;
      return SizedBox(
        height: 26,
        child: Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: x,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              left: (x - 13).clamp(0.0, c.maxWidth - 26),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StatusPill extends StatelessWidget {
  final bool cancelled;
  final bool late;
  final int delayMinutes;
  const _StatusPill({
    required this.cancelled,
    required this.late,
    required this.delayMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = cancelled
        ? (
            'Cancelled',
            Icons.cancel,
            const Color(0xFFFBE0DC),
            const Color(0xFF7F1D14)
          )
        : late
            ? (
                delayMinutes > 0 ? 'Late $delayMinutes min' : 'Delayed',
                Icons.schedule,
                const Color(0xFFFFF1DB),
                const Color(0xFF7A4300)
              )
            : (
                'On time',
                Icons.check_circle,
                const Color(0xFFDDF1E3),
                const Color(0xFF14532D)
              );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

class _SignalRow extends StatelessWidget {
  final bool hasSignal;
  const _SignalRow({required this.hasSignal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(hasSignal ? Icons.gps_fixed : Icons.gps_not_fixed,
            size: 22,
            color: hasSignal ? Colors.green.shade700 : Colors.orange.shade800),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            hasSignal
                ? 'Live location. The bus is sharing its position.'
                : 'Waiting for the bus to share its location. The time above comes from the timetable.',
            style: const TextStyle(fontSize: 16, height: 1.3),
          ),
        ),
      ]),
    );
  }
}

class _BusMarker extends StatelessWidget {
  final Animation<double> pulse;
  final String etaLabel;
  const _BusMarker({required this.pulse, required this.etaLabel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (_, __) {
            final t = pulse.value;
            return Opacity(
              opacity: (1 - t) * 0.5,
              child: Container(
                width: 44 + 40 * t,
                height: 44 + 40 * t,
                decoration: const BoxDecoration(
                    color: AppTheme.primaryColor, shape: BoxShape.circle),
              ),
            );
          },
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
          ),
          child:
              const Icon(Icons.directions_bus, color: Colors.white, size: 22),
        ),
        Positioned(
          top: -30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(etaLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}
