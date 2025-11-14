// lib/views/booking/seat_selection_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import 'payment_screen.dart';

class SeatSelectionScreen extends StatelessWidget {
  const SeatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final trip = controller.selectedTrip!;
    final theme = Theme.of(context);
    // 3. REMOVE UNUSED USER VARIABLE
    // final user = Provider.of<User?>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Select Seats")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend(theme.cardColor, "Available", theme),
                _legend(Colors.red.shade100, "Booked", theme),
                _legend(theme.primaryColor, "Selected", theme),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: InteractiveViewer(
              maxScale: 3.0,
              minScale: 1.0,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildSeatGrid(context, trip),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${controller.selectedSeats.length} Seats",
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      "LKR ${(controller.selectedSeats.length * trip.price).toStringAsFixed(0)}",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: theme.elevatedButtonTheme.style,
                    // 4. UPDATE onPressed TO GO TO PAYMENT SCREEN
                    onPressed: controller.selectedSeats.isEmpty
                        ? null
                        : () {
                            // This now navigates to your payment summary screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentScreen(),
                              ),
                            );
                          },
                    // 5. UPDATE BUTTON TEXT
                    child: const Text("Proceed to Pay"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid(BuildContext context, Trip trip) {
    final int numRows = (trip.totalSeats / 4).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 25, top: 5),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Driver",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              Icon(Icons.bus_alert, color: Colors.grey.shade600, size: 28),
            ],
          ),
        ),
        ...List.generate(numRows, (rowIndex) {
          int seatL1 = (rowIndex * 4) + 1;
          int seatL2 = (rowIndex * 4) + 2;
          int seatR1 = (rowIndex * 4) + 3;
          int seatR2 = (rowIndex * 4) + 4;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _Seat(seatNumber: seatL1),
                    const SizedBox(width: 12),
                    _Seat(seatNumber: seatL2),
                  ],
                ),
                const SizedBox(width: 30),
                Row(
                  children: [
                    _Seat(seatNumber: seatR1),
                    const SizedBox(width: 12),
                    _Seat(seatNumber: seatR2),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _legend(Color color, String text, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
                color: theme.colorScheme.onSurface.withAlpha(51), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.seatNumber});
  final int seatNumber;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final trip = controller.selectedTrip!;
    final theme = Theme.of(context);

    if (seatNumber > trip.totalSeats) {
      // --- FIX: Linter Warning ---
      // Replaced Container with SizedBox
      return const SizedBox(width: 50, height: 50);
      // --- END OF FIX ---
    }

    final bool isBooked = trip.bookedSeats.contains(seatNumber);
    final bool isSelected = controller.selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: isBooked ? null : () => controller.toggleSeat(seatNumber),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.red.shade100
              : isSelected
                  ? theme.primaryColor
                  : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.primaryColor.withAlpha(128))
              : Border.all(
                  color: theme.colorScheme.onSurface.withAlpha(51), width: 1),
        ),
        child: Center(
          child: isBooked
              ? Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red.shade900,
                )
              : Text(
                  "$seatNumber",
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
