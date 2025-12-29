import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/trip_model.dart';
import '../../../utils/app_theme.dart';

class OngoingTripCard extends StatelessWidget {
  final Trip trip;
  final int seatCount;
  final double paidAmount;

  const OngoingTripCard({
    super.key,
    required this.trip,
    required this.seatCount,
    required this.paidAmount,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upcoming Trip",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w800, // Extra Bold
                      color: isDark ? Colors.white : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Don't miss your bus!",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
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
                    DateFormat('EEEE').format(trip.departureTime),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
              _buildLocationInfo("ORIGIN", trip.fromCity, isDark),
              Icon(Icons.arrow_right_alt, color: Colors.grey.shade400),
              _buildLocationInfo("DESTINATION", trip.toCity, isDark,
                  alignRight: true),
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
            fontFamily: 'Inter',
            fontSize: 10,
            letterSpacing: 1.0,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          city,
          style: TextStyle(
            fontFamily: 'Inter',
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
    // 3 states: Departed, On Way, Arrived
    // Map TripStatus to these states
    bool departed = status == TripStatus.departed ||
        status == TripStatus.onWay ||
        status == TripStatus.arrived ||
        status == TripStatus.completed ||
        status == TripStatus.boarding;

    bool onWay = status == TripStatus.onWay ||
        status == TripStatus.arrived ||
        status == TripStatus.completed;

    bool arrived =
        status == TripStatus.arrived || status == TripStatus.completed;

    return Row(
      children: [
        Expanded(child: _buildTrackStep("Departed", departed)),
        const SizedBox(width: 8),
        Expanded(child: _buildTrackStep("On Way", onWay)),
        const SizedBox(width: 8),
        Expanded(child: _buildTrackStep("Arrived", arrived)),
      ],
    );
  }

  Widget _buildTrackStep(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE8F5E9) // Light Green
            : const Color(0xFFF5F5F5), // Grey
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
