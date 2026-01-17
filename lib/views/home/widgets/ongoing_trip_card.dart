import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/trip_view_model.dart';
import '../../../utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../utils/language_provider.dart';

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
    final lp = Provider.of<LanguageProvider>(context);

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
                      lp.translate('upcoming_trip'),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w800,
                                fontSize: 20, // Reduced from 22
                                color: isDark
                                    ? Colors.white
                                    : Colors.black, // Strict Black
                              ),
                    ),
                    const SizedBox(height: 4), // Reduced from 6
                    // NEW: Dynamic ETA Display
                    Builder(builder: (context) {
                      final now = DateTime.now();
                      final diff = trip.arrivalTime.difference(now);
                      final isLive = trip.status == 'departed' ||
                          trip.status == 'onWay' ||
                          trip.status == 'delayed';

                      // Only show if active and in future (or slightly late)
                      if (isLive && diff.inMinutes > 0) {
                        String timeStr = "";
                        if (diff.inHours > 0) {
                          timeStr =
                              "${diff.inHours} ${lp.translate('hrs')} ${diff.inMinutes % 60} ${lp.translate('mins')}";
                        } else {
                          timeStr = "${diff.inMinutes} ${lp.translate('mins')}";
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2), // Reduced
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${lp.translate('arriving_in')} $timeStr",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Reduced form 14
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
              _buildStatusBadge(trip.status),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 16
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
                          fontSize: 16, // Reduced from 18
                          color: isDark
                              ? Colors.white70
                              : Colors.black87, // Darker
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${lp.translate('bus_no')}: ${trip.busNumber}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13, // Reduced from 14
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.white : Colors.black, // Strict Black
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 16
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildLocationInfo(
                    lp.translate('origin'), trip.fromCity, isDark),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced
                child: Icon(Icons.arrow_right_alt),
              ),
              Expanded(
                child: _buildLocationInfo(
                    lp.translate('destination'), trip.toCity, isDark,
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
                  Text(lp.translate('seats'),
                      style: TextStyle(
                          fontSize: 11, // Reduced
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black)), // Strict Black
                  Text("$seatCount",
                      style: TextStyle(
                          fontSize: 16, // Reduced
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(lp.translate('price_paid'),
                      style: TextStyle(
                          fontSize: 11, // Reduced
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black)), // Strict Black
                  Text("LKR ${paidAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontSize: 16, // Reduced
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24), // Increased for better separation
          _buildTrackingBar(trip.status, isDark, lp),
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

    // Since _buildStatusBadge is a method, we cannot access 'lp' directly unless passed or fetched.
    // Fetching here for labels.
    // However, this method is called inside build where we can pass translated strings or just fetch context.
    // Wait, this method doesn't have context.
    // I need to add context to arguments or just use a helper.
    // But it's inside the class, so 'context' is NOT available unless passed.
    // Wait, StatelessWidget methods don't have 'context' unless passed.
    // I should modify the call site or use Provider in build and pass the result.
    // Actually, simply using context inside build and passing the label is best.
    // But this logic is inside the method.
    // I will refactor: move logic to build or pass context.
    // Let's pass `lp` to this method.
    // But `multi_replace` makes it hard to change signature and call sites simultaneously if I don't see them all.
    // Call site is line 104: `_buildStatusBadge(trip.status),`
    // I will update call site to `_buildStatusBadge(context, trip.status)` and method to `_buildStatusBadge(BuildContext context, String status)`.
    // Then use `Provider.of` inside.
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

  Widget _buildTrackingBar(String status, bool isDark, LanguageProvider lp) {
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
            lp.translate('departed'),
            isDeparted, // Only active if EXACTLY departed
            Colors.green,
            Icons.directions_bus,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrackStep(
            lp.translate('on_way'),
            isOnWay, // Only active if EXACTLY on way
            Colors.blue,
            Icons.map,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrackStep(
            lp.translate('arrived'),
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
      padding: const EdgeInsets.symmetric(vertical: 8), // Reduced from 12
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
