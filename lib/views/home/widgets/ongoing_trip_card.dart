import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/trip_view_model.dart';
import '../../../utils/app_theme.dart';

class OngoingTripCard extends StatelessWidget {
  final EnrichedTrip trip;
  final int seatCount;
  final double paidAmount;
  final EdgeInsetsGeometry? margin;

  const OngoingTripCard({
    super.key,
    required this.trip,
    required this.seatCount,
    required this.paidAmount,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin:
          margin ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2129) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upcoming Trip",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                    const SizedBox(height: 4),
                    // NEW: Dynamic ETA Display
                    Builder(builder: (context) {
                      final now = DateTime.now();
                      final diff = trip.arrivalTime.difference(now);
                      final s = trip.status.toLowerCase();
                      final isLive = s == 'departed' ||
                          s == 'onway' ||
                          s == 'on way' ||
                          s == 'delayed';

                      if (isLive && diff.inMinutes > 0) {
                        String timeStr = "";
                        if (diff.inHours > 0) {
                          timeStr =
                              "${diff.inHours} hrs ${diff.inMinutes % 60} mins";
                        } else {
                          timeStr = "${diff.inMinutes} mins";
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Arriving in $timeStr",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }),
                  ],
                ),
              ),
              _buildStatusBadge(context, trip),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('E, MMM d • h:mm a').format(trip.departureTime),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Bus No: ${trip.busNumber}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildLocationInfo(
                    context, "Origin", trip.fromCity, isDark),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(Icons.arrow_right_alt),
              ),
              Expanded(
                child: _buildLocationInfo(
                    context, "Destination", trip.toCity, isDark,
                    alignRight: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Seats",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
                  Text("$seatCount",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Price Paid",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface)),
                  Text("LKR ${paidAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTrackingBar(trip.status, isDark),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(
      BuildContext context, String label, String city, bool isDark,
      {bool alignRight = false}) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            letterSpacing: 1.0,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          city,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, EnrichedTrip trip) {
    Color bg;
    Color text;
    String label;
    final status = trip.status;

    switch (status.toLowerCase()) {
      case 'departed':
      case 'onway':
      case 'on way':
        bg = Colors.green.withValues(alpha: 0.1);
        text = Colors.green;
        label = "Active";
        break;
      case 'delayed':
        bg = Colors.orange.withValues(alpha: 0.1);
        text = Colors.orange;
        // Format Delay
        final mins = trip.trip.delayMinutes;
        if (mins > 0) {
          final h = mins ~/ 60;
          final m = mins % 60;
          if (h > 0) {
            label = "$h h $m m Delayed";
          } else {
            label = "$mins m Delayed";
          }
        } else {
          label = "Delayed";
        }
        break;
      case 'cancelled':
        bg = Colors.red.withValues(alpha: 0.1);
        text = Colors.red;
        label = "Cancelled";
        break;
      case 'arrived':
      case 'completed':
        bg = Colors.blue.withValues(alpha: 0.1);
        text = Colors.blue;
        label = "Completed";
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.1);
        text = Colors.grey;
        label = "Scheduled";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTrackingBar(String status, bool isDark) {
    // Logic: Cumulative progress
    final s = status.toLowerCase();

    bool isArrivedState = s == 'arrived' || s == 'completed';
    bool isOnWayState = s == 'onway' || s == 'on way' || s == 'on_way';
    bool isDepartedState = s == 'departed';

    // Cumulative Flags
    bool isArrived = isArrivedState;
    bool isOnWay = isOnWayState || isArrivedState;
    bool isDeparted = isDepartedState || isOnWayState || isArrivedState;

    return Row(
      children: [
        Expanded(
          child: _buildTrackStep(
            "Departed",
            isDeparted,
            Colors.green,
            Icons.directions_bus,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrackStep(
            "On Way",
            isOnWay,
            Colors.blue,
            Icons.map,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrackStep(
            "Arrived",
            isArrived,
            Colors.orange,
            Icons.check_circle,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackStep(String label, bool isActive, Color activeColor,
      IconData icon, bool isDark) {
    Color color;
    Color textColor;
    Color bgColor;

    if (isActive) {
      color = activeColor;
      textColor = activeColor;
      bgColor = activeColor.withValues(alpha: 0.1);
    } else {
      // Inactive (Past or Future) -> Greyed Out
      color = isDark
          ? Colors.white.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.3);
      textColor = isDark
          ? Colors.white.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.3);
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? activeColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
