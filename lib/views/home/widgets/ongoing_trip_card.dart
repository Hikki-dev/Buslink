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
      padding: const EdgeInsets.all(16), // Reduced from 24
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
                                fontSize: 22,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black, // Strict Black
                              ),
                    ),
                    const SizedBox(height: 6),
                    // NEW: Dynamic ETA Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Arriving in 15 mins", // Hardcoded for demo, normally calc
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // Bumped
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(trip.status),
            ],
          ),
          const SizedBox(height: 16), // Reduced from 24
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
                          fontSize: 18, // Bumped from 16
                          color: isDark
                              ? Colors.white70
                              : Colors.black87, // Darker
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Bus No: ${trip.busNumber}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.white : Colors.black, // Strict Black
                    ),
                  ),
                ],
              ),
              // NEW: "Call Conductor" Button
              // Button Removed as per User Request
            ],
          ),
          const SizedBox(height: 16), // Reduced from 24
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildLocationInfo("ORIGIN", trip.fromCity, isDark),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_right_alt, color: Colors.grey.shade400),
              ),
              Expanded(
                child: _buildLocationInfo("DESTINATION", trip.toCity, isDark,
                    alignRight: true),
              ),
            ],
          ),
          const SizedBox(height: 16), // Reduced from 16/24
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SEATS",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black)), // Strict Black
                  Text("$seatCount",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("PRICE PAID",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black)), // Strict Black
                  Text("LKR ${paidAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16), // Reduced from 24
          _buildTrackingBar(trip.status, isDark),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, String city, bool isDark,
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
            color: isDark ? Colors.white : Colors.black, // Strict Black
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
            color: isDark ? Colors.white : Colors.black, // Strict Black
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'departed':
      case 'onWay':
        bg = Colors.green.withValues(alpha: 0.1);
        text = Colors.green;
        label = "Active";
        break;
      case 'delayed':
        bg = Colors.orange.withValues(alpha: 0.1);
        text = Colors.orange;
        label = "Delayed";
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
    // Logic: Only the CURRENT active status should be colored.
    // Past statuses should be greyed out (inactive).
    // Future statuses should be greyed out.

    bool isDeparted = status == 'departed';
    bool isOnWay = status == 'onWay';
    bool isArrived = status == 'arrived' || status == 'completed';

    return Row(
      children: [
        Expanded(
          child: _buildTrackStep(
            "Departed",
            isDeparted, // Only active if EXACTLY departed
            Colors.green,
            Icons.directions_bus,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrackStep(
            "On Way",
            isOnWay, // Only active if EXACTLY on way
            Colors.blue,
            Icons.map,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrackStep(
            "Arrived",
            isArrived, // Only active if arrived/completed
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
