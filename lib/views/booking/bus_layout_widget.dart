import 'package:flutter/material.dart';
import '../../utils/bl_colors.dart';
import '../../models/trip_model.dart';
import '../../utils/app_theme.dart';
import '../../services/firestore_service.dart';

/// Seat button size. 48px meets the usual minimum touch target.
const double _kSeat = 52;

class BusLayoutWidget extends StatefulWidget {
  final Trip trip;
  final int totalSeats;
  final List<int> selectedSeats;
  final List<int> highlightedSeats;
  final Function(int)? onSeatToggle;
  final bool isReadOnly;
  final bool isDark;

  /// Live seat data. Defaults to the trip's Firestore stream; tests can pass
  /// their own.
  final Stream<Trip>? tripStream;

  const BusLayoutWidget({
    super.key,
    required this.trip,
    this.totalSeats = 40,
    this.selectedSeats = const [],
    this.highlightedSeats = const [],
    this.onSeatToggle,
    this.isReadOnly = false,
    required this.isDark,
    this.tripStream,
  });

  @override
  State<BusLayoutWidget> createState() => _BusLayoutWidgetState();
}

class _BusLayoutWidgetState extends State<BusLayoutWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          _buildDriverArea(),
          const SizedBox(height: 16),
          _buildSeatGrid(),
          const SizedBox(height: 8),
          _buildBackOfBus(),
        ],
      ),
    );
  }

  Widget _buildDriverArea() {
    final grey = BL.muted;
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: BL.border, width: 2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text('Front of bus (driver)',
                style: TextStyle(fontSize: 16, color: grey)),
          ),
          Icon(Icons.sports_motorsports_outlined, size: 26, color: grey),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    return StreamBuilder<Trip>(
        stream: widget.tripStream ??
            FirestoreService().getTripStream(widget.trip.id),
        builder: (context, snapshot) {
          final currentTrip = snapshot.data;
          // Use Schedule/Enriched data for setup
          final int totalSeats = widget.totalSeats;
          // Use Trip data for availability (real-time)
          final List<String> booked =
              currentTrip?.bookedSeatNumbers ?? widget.trip.bookedSeatNumbers;

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
                      _buildRearExit(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 5; i++)
                              if (seatExists(i)) ...[
                                _SeatItem(
                                  seatNum: startSeat + i,
                                  isBooked: booked
                                      .contains((startSeat + i).toString()),
                                  isBlocked: false,
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
                                if (i < 4) const SizedBox(width: 8),
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
                      // Left Side
                      Row(children: [
                        if (seatExists(0))
                          _SeatItem(
                            seatNum: startSeat,
                            isBooked: booked.contains(startSeat.toString()),
                            isBlocked: false,
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
                          const SizedBox(width: _kSeat, height: _kSeat),
                        const SizedBox(width: 10),
                        if (seatExists(1))
                          _SeatItem(
                            seatNum: startSeat + 1,
                            isBooked:
                                booked.contains((startSeat + 1).toString()),
                            isBlocked: false,
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
                          const SizedBox(width: _kSeat, height: _kSeat),
                      ]),

                      // Right Side
                      Row(children: [
                        if (seatExists(2))
                          _SeatItem(
                            seatNum: startSeat + 2,
                            isBooked:
                                booked.contains((startSeat + 2).toString()),
                            isBlocked: false,
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
                          const SizedBox(width: _kSeat, height: _kSeat),
                        const SizedBox(width: 10),
                        if (seatExists(3))
                          _SeatItem(
                            seatNum: startSeat + 3,
                            isBooked:
                                booked.contains((startSeat + 3).toString()),
                            isBlocked: false,
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
                          const SizedBox(width: _kSeat, height: _kSeat),
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
                        fontSize: 12,
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

  Widget _buildBackOfBus() => const SizedBox(height: 4);
}

class _SeatItem extends StatefulWidget {
  final int seatNum;
  final bool isBooked;
  final bool isBlocked;
  final bool isSelected;
  final bool isHighlighted; // For Conductor Verification
  final VoidCallback? onTap;
  final bool isReadOnly;

  const _SeatItem({
    required this.seatNum,
    required this.isBooked,
    required this.isBlocked,
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
    // Caller handles existence check

    final isBooked = widget.isBooked;
    final isBlocked = widget.isBlocked;
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
      seatColor = const Color(0xFFD5DAE0); // taken: grey, not an alarming red
    } else if (widget.isSelected) {
      seatColor = AppTheme.primaryColor;
    } else {
      seatColor = isHovered ? BL.tint : Colors.white;
    }

    final String stateLabel = widget.isHighlighted
        ? 'your seat'
        : isBlocked
            ? 'not available'
            : isBooked
                ? 'taken'
                : widget.isSelected
                    ? 'selected'
                    : 'free';
    final bool canTap =
        !(isUnavailable && !widget.isReadOnly) && widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: (isUnavailable && !widget.isReadOnly) || widget.isReadOnly
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: Semantics(
        label: 'Seat ${widget.seatNum}, $stateLabel',
        button: canTap,
        selected: widget.isSelected,
        // excludeSemantics hides the child's own tap, so give it back here:
        // screen readers and switch devices choose seats through this.
        onTap: canTap ? widget.onTap : null,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: isUnavailable && !widget.isReadOnly ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _kSeat,
            height: _kSeat,
            decoration: BoxDecoration(
              color: seatColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: widget.isSelected || widget.isHighlighted
                      ? (widget.isHighlighted
                          ? Colors.green
                          : AppTheme.primaryColor)
                      : isUnavailable
                          ? Colors.transparent
                          : BL.faint,
                  width: 1.5),
            ),
            child: Center(
              child: isBlocked
                  ? Icon(Icons.block, size: 20, color: BL.muted)
                  : (isBooked && !widget.isHighlighted)
                      ? Icon(Icons.close, size: 22, color: BL.muted)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // A tick as well as the colour, so "selected"
                            // never depends on colour alone.
                            if (widget.isSelected && !widget.isHighlighted)
                              const Padding(
                                padding: EdgeInsets.only(right: 2),
                                child: Icon(Icons.check,
                                    size: 16, color: Colors.white),
                              ),
                            Text(
                              "${widget.seatNum}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color:
                                    (widget.isSelected || widget.isHighlighted)
                                        ? Colors.white
                                        : const Color(0xFF0B090A),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
