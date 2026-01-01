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
          // FRONT EXIT
          Column(
            children: [
              const Icon(Icons.sensor_door_outlined,
                  color: Colors.red, size: 24),
              const SizedBox(height: 4),
              Text("EXIT",
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold)),
            ],
          ),

          // DRIVER (Steering Wheel)
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
              size: 28,
              color: widget.isDark ? Colors.white54 : Colors.black54,
            ),
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

          if (totalSeats < 4) return const SizedBox();

          // Standard Bus Logic: Last row has 5 seats, others have 4.
          // IF total seats doesn't fit 4xN + 5, we assume the remainder is in the last row.
          // e.g. 49 seats -> 11 rows of 4 (44) + 5 seats = 49.
          int normalRowsCount = (totalSeats - 5) ~/ 4;
          if (normalRowsCount < 0) normalRowsCount = 0; // Safety

          // Calculate how many seats are actually left for the last row
          int seatsInLastRow = totalSeats - (normalRowsCount * 4);

          return Column(
            children: [
              // 1. Normal Rows
              ...List.generate(normalRowsCount, (index) {
                int rowStart = index * 4;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        _SeatItem(
                          seatNum: rowStart + 1,
                          trip: currentTrip,
                          isSelected:
                              widget.selectedSeats.contains(rowStart + 1),
                          isHighlighted:
                              widget.highlightedSeats.contains(rowStart + 1),
                          onTap: widget.isReadOnly &&
                                  widget.onSeatToggle == null
                              ? null
                              : () => widget.onSeatToggle?.call(rowStart + 1),
                          isReadOnly: widget.isReadOnly,
                        ),
                        const SizedBox(width: 10),
                        _SeatItem(
                          seatNum: rowStart + 2,
                          trip: currentTrip,
                          isSelected:
                              widget.selectedSeats.contains(rowStart + 2),
                          isHighlighted:
                              widget.highlightedSeats.contains(rowStart + 2),
                          onTap: widget.isReadOnly &&
                                  widget.onSeatToggle == null
                              ? null
                              : () => widget.onSeatToggle?.call(rowStart + 2),
                          isReadOnly: widget.isReadOnly,
                        ),
                      ]),
                      Row(children: [
                        _SeatItem(
                          seatNum: rowStart + 3,
                          trip: currentTrip,
                          isSelected:
                              widget.selectedSeats.contains(rowStart + 3),
                          isHighlighted:
                              widget.highlightedSeats.contains(rowStart + 3),
                          onTap: widget.isReadOnly &&
                                  widget.onSeatToggle == null
                              ? null
                              : () => widget.onSeatToggle?.call(rowStart + 3),
                          isReadOnly: widget.isReadOnly,
                        ),
                        const SizedBox(width: 10),
                        _SeatItem(
                          seatNum: rowStart + 4,
                          trip: currentTrip,
                          isSelected:
                              widget.selectedSeats.contains(rowStart + 4),
                          isHighlighted:
                              widget.highlightedSeats.contains(rowStart + 4),
                          onTap: widget.isReadOnly &&
                                  widget.onSeatToggle == null
                              ? null
                              : () => widget.onSeatToggle?.call(rowStart + 4),
                          isReadOnly: widget.isReadOnly,
                        ),
                      ]),
                    ],
                  ),
                );
              }),

              // 2. Rear Exit Area (MOVED TO LEFT)
              if (normalRowsCount > 0)
                Container(
                  alignment: Alignment.centerLeft, // Left alignment
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // Start aligned
                    children: [
                      const Icon(Icons.sensor_door_outlined,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Text("EXIT",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.withValues(alpha: 0.8),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // 3. Last Row (Dynamic Seat Count, usually 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Distribute evenly
                  children: List.generate(seatsInLastRow, (i) {
                    // Start numbers after all normal rows
                    int seatNum = (normalRowsCount * 4) + i + 1;

                    // Dynamic width calculation to fit 5 seats
                    // Available width ~260px. 5 seats -> ~48px each max including gap.
                    // If we have 5 seats, we need them smaller or less gap.
                    // Let's use a flexible/expanded approach or fixed smaller size for dense rows.
                    double seatWidth = seatsInLastRow > 4 ? 40 : 44;

                    return _SeatItem(
                      seatNum: seatNum,
                      trip: currentTrip,
                      isSelected: widget.selectedSeats.contains(seatNum),
                      isHighlighted: widget.highlightedSeats.contains(seatNum),
                      onTap: widget.isReadOnly && widget.onSeatToggle == null
                          ? null
                          : () => widget.onSeatToggle?.call(seatNum),
                      isReadOnly: widget.isReadOnly,
                      width: seatWidth,
                    );
                  }),
                ),
              ),
            ],
          );
        });
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
  final double width;
  final bool isReadOnly;

  const _SeatItem({
    required this.seatNum,
    required this.trip,
    required this.isSelected,
    this.isHighlighted = false,
    this.onTap,
    this.width = 44,
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
      return SizedBox(width: widget.width, height: 44);
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
          width: widget.width,
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
