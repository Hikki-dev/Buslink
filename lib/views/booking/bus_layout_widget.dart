import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../utils/app_theme.dart';
import '../../services/firestore_service.dart';

class BusLayoutWidget extends StatefulWidget {
  final Trip trip;
  final List<int> selectedSeats;
  final List<int> highlightedSeats;
  final Function(int)? onSeatToggle;
  final bool isReadOnly;
  final bool isDark;

  const BusLayoutWidget({
    super.key,
    required this.trip,
    this.selectedSeats = const [],
    this.highlightedSeats = const [],
    this.onSeatToggle,
    this.isReadOnly = false,
    required this.isDark,
  });

  @override
  State<BusLayoutWidget> createState() => _BusLayoutWidgetState();
}

class _BusLayoutWidgetState extends State<BusLayoutWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, // Slightly more compact than original 340
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF2D3142) : Colors.white,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(50), bottom: Radius.circular(30)),
        border: Border.all(
            color: widget.isDark ? Colors.white10 : Colors.grey.shade200,
            width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          _buildDriverArea(),
          const SizedBox(height: 24),
          _buildSeatGrid(),
          const SizedBox(height: 20),
          _buildBackOfBus(),
        ],
      ),
    );
  }

  Widget _buildDriverArea() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: widget.isDark ? Colors.white10 : Colors.black12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // FRONT ENTRANCE
          Column(
            children: [
              const Icon(Icons.sensor_door_outlined,
                  color: Colors.green,
                  size: 24), // Changed to Green for Entrance
              const SizedBox(height: 4),
              Text("Entrance",
                  style: TextStyle(
                      fontSize: 10,
                      color: widget.isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.bold)),
            ],
          ),

          // DRIVER (Steering Wheel)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: widget.isDark ? Colors.white24 : Colors.black12,
                      width: 2),
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 24,
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text("Driver",
                  style: TextStyle(
                      fontSize: 10,
                      color: widget.isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    return StreamBuilder<Trip>(
        stream: FirestoreService().getTripStream(widget.trip.id),
        builder: (context, snapshot) {
          final currentTrip = snapshot.data ?? widget.trip;
          final int totalSeats = currentTrip.totalSeats;

          if (totalSeats < 1) return const SizedBox();

          // Calculate number of rows (4 seats per row)
          int rowCount = (totalSeats / 4).ceil();

          return Column(
            children: [
              ...List.generate(rowCount, (rowIndex) {
                int startSeat = rowIndex * 4 + 1;
                bool isLastRow = rowIndex == rowCount - 1;

                // Helper to check if seat exists
                bool seatExists(int offset) =>
                    (startSeat + offset) <= totalSeats;

                // LAST ROW (Back Bench)
                if (isLastRow) {
                  return Column(
                    children: [
                      _buildRearExit(), // REAR EXIT MOVED HERE
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Center them
                          children: [
                            for (int i = 0;
                                i < 5;
                                i++) // Try to fit 5? No, stick to existing logic but tight
                              if (seatExists(i)) ...[
                                _SeatItem(
                                  seatNum: startSeat + i,
                                  trip: currentTrip,
                                  isSelected: widget.selectedSeats
                                      .contains(startSeat + i),
                                  isHighlighted: widget.highlightedSeats
                                      .contains(startSeat + i),
                                  onTap: widget.isReadOnly &&
                                          widget.onSeatToggle == null
                                      ? null
                                      : () => widget.onSeatToggle
                                          ?.call(startSeat + i),
                                  isReadOnly: widget.isReadOnly,
                                ),
                                if (i < 4)
                                  const SizedBox(
                                      width:
                                          8), // Small gap between linked seats
                              ]
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // NORMAL ROWS
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Side (Seat 1 & 2)
                      Row(children: [
                        if (seatExists(0))
                          _SeatItem(
                            seatNum: startSeat,
                            trip: currentTrip,
                            isSelected:
                                widget.selectedSeats.contains(startSeat),
                            isHighlighted:
                                widget.highlightedSeats.contains(startSeat),
                            onTap: widget.isReadOnly &&
                                    widget.onSeatToggle == null
                                ? null
                                : () => widget.onSeatToggle?.call(startSeat),
                            isReadOnly: widget.isReadOnly,
                          )
                        else
                          const SizedBox(width: 44, height: 44),
                        const SizedBox(width: 10),
                        if (seatExists(1))
                          _SeatItem(
                            seatNum: startSeat + 1,
                            trip: currentTrip,
                            isSelected:
                                widget.selectedSeats.contains(startSeat + 1),
                            isHighlighted:
                                widget.highlightedSeats.contains(startSeat + 1),
                            onTap: widget.isReadOnly &&
                                    widget.onSeatToggle == null
                                ? null
                                : () =>
                                    widget.onSeatToggle?.call(startSeat + 1),
                            isReadOnly: widget.isReadOnly,
                          )
                        else
                          const SizedBox(width: 44, height: 44),
                      ]),

                      // Right Side (Seat 3 & 4)
                      Row(children: [
                        if (seatExists(2))
                          _SeatItem(
                            seatNum: startSeat + 2,
                            trip: currentTrip,
                            isSelected:
                                widget.selectedSeats.contains(startSeat + 2),
                            isHighlighted:
                                widget.highlightedSeats.contains(startSeat + 2),
                            onTap: widget.isReadOnly &&
                                    widget.onSeatToggle == null
                                ? null
                                : () =>
                                    widget.onSeatToggle?.call(startSeat + 2),
                            isReadOnly: widget.isReadOnly,
                          )
                        else
                          const SizedBox(width: 44, height: 44),
                        const SizedBox(width: 10),
                        if (seatExists(3))
                          _SeatItem(
                            seatNum: startSeat + 3,
                            trip: currentTrip,
                            isSelected:
                                widget.selectedSeats.contains(startSeat + 3),
                            isHighlighted:
                                widget.highlightedSeats.contains(startSeat + 3),
                            onTap: widget.isReadOnly &&
                                    widget.onSeatToggle == null
                                ? null
                                : () =>
                                    widget.onSeatToggle?.call(startSeat + 3),
                            isReadOnly: widget.isReadOnly,
                          )
                        else
                          const SizedBox(width: 44, height: 44),
                      ]),
                    ],
                  ),
                );
              }),
            ],
          );
        });
  }

  Widget _buildRearExit() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                  color: widget.isDark ? Colors.white24 : Colors.black12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                const Icon(Icons.sensor_door_outlined,
                    color: Colors.green, size: 20),
                const SizedBox(height: 2),
                Text("Exit",
                    style: TextStyle(
                        fontSize: 8,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(), // Empty space to push Exit to left
        ],
      ),
    );
  }

  Widget _buildBackOfBus() {
    return Container(
      height: 10,
      width: double.infinity,
      decoration: BoxDecoration(
          color: widget.isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _SeatItem extends StatefulWidget {
  final int seatNum;
  final Trip trip;
  final bool isSelected;
  final bool isHighlighted; // For Conductor Verification
  final VoidCallback? onTap;
  final bool isReadOnly;

  const _SeatItem({
    required this.seatNum,
    required this.trip,
    required this.isSelected,
    this.isHighlighted = false,
    this.onTap,
    this.isReadOnly = false,
  });

  @override
  State<_SeatItem> createState() => _SeatItemState();
}

class _SeatItemState extends State<_SeatItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.seatNum > widget.trip.totalSeats) {
      return const SizedBox(width: 44, height: 44);
    }

    final isBooked = widget.trip.bookedSeats.contains(widget.seatNum);
    final isBlocked = widget.trip.blockedSeats.contains(widget.seatNum);
    final isUnavailable = isBooked || isBlocked;

    // If we are validating, we want to show the seat as highlighted (Green)
    // even if it is technically 'booked' in the DB.
    // So 'isHighlighted' overrides visual 'booked' state for clarity in that specific dialog.

    // Actually, for verification: The seat IS booked. We want to show "THIS IS YOUR SEAT".
    // So we should colour it distinctively (Green) while others remain Red (Booked).

    Color? seatColor;
    if (widget.isHighlighted) {
      seatColor = Colors.green; // Strong Green for verified seat
    } else if (isBlocked) {
      seatColor = Colors.amber;
    } else if (isBooked) {
      seatColor = Colors.red.shade300;
    } else if (widget.isSelected) {
      seatColor = AppTheme.primaryColor;
    } else {
      seatColor = isHovered
          ? AppTheme.primaryColor.withValues(alpha: 0.1)
          : Colors.white;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: (isUnavailable && !widget.isReadOnly) || widget.isReadOnly
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isUnavailable && !widget.isReadOnly ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: widget.isSelected || widget.isHighlighted
                    ? (widget.isHighlighted
                        ? Colors.green
                        : AppTheme.primaryColor)
                    : isUnavailable
                        ? Colors.transparent
                        : Colors.grey.shade300,
                width: 2),
            boxShadow: widget.isSelected || widget.isHighlighted
                ? [
                    BoxShadow(
                        color: (widget.isHighlighted
                                ? Colors.green
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: isBlocked
                ? const Icon(Icons.block, size: 16, color: Colors.black54)
                : (isBooked && !widget.isHighlighted)
                    ? const Icon(Icons.close, size: 16, color: Colors.white)
                    : Text(
                        "${widget.seatNum}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (widget.isSelected ||
                                  widget.isHighlighted ||
                                  isBooked)
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
