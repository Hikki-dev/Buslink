import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/trip_model.dart';
import '../../../utils/app_theme.dart';

class OngoingTripCard extends StatelessWidget {
  final Trip trip;
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
      padding: const EdgeInsets.all(24),
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color:
                                isDark ? Colors.white : const Color(0xFF2D3142),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Don't miss your bus!",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(trip.status),
            ],
          ),
          const SizedBox(height: 24),
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
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                  ),
                  Text(
                    "Bus No: ${trip.busNumber}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SEATS",
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  Text("$seatCount",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("PRICE PAID",
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  Text("LKR ${paidAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTrackingBar(trip.status),
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
            fontSize: 10,
            letterSpacing: 1.0,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          city,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(TripStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case TripStatus.departed:
      case TripStatus.onWay:
        bg = Colors.green.withValues(alpha: 0.1);
        text = Colors.green;
        label = "Active";
        break;
      case TripStatus.delayed:
        bg = Colors.orange.withValues(alpha: 0.1);
        text = Colors.orange;
        label = "Delayed";
        break;
      case TripStatus.cancelled:
        bg = Colors.red.withValues(alpha: 0.1);
        text = Colors.red;
        label = "Cancelled";
        break;
      case TripStatus.arrived:
      case TripStatus.completed:
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

  Widget _buildTrackingBar(TripStatus status) {
    // Single Active State Logic as requested by User
    // "if it changes from 1 to another it should remove it... 1 should be greyed out and on 2"

    return Row(
      children: [
        Expanded(
          child: _buildTrackStep(
            "Departed",
            status == TripStatus.departed,
            Colors.green,
            Icons.directions_bus,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrackStep(
            "On Way",
            status == TripStatus.onWay,
            Colors.blue,
            Icons.map,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrackStep(
            "Arrived",
            status == TripStatus.arrived,
            Colors.orange,
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackStep(
      String label, bool isActive, Color activeColor, IconData icon) {
    // If NOT active, grey it out completely
    final color = isActive ? activeColor : Colors.grey.shade300;
    final textColor = isActive ? activeColor : Colors.grey.shade500;
    final bgColor =
        isActive ? activeColor.withValues(alpha: 0.1) : const Color(0xFFF5F5F5);

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
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
