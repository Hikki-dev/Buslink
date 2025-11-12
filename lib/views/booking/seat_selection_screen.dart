// lib/views/booking/seat_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart'; // Import the model
import '../ticket/ticket_screen.dart';

class SeatSelectionScreen extends StatelessWidget {
  const SeatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final trip = controller.selectedTrip!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Select Seats")),
      body: Column(
        children: [
          // This is your original, unchanged Legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend(theme.cardColor, "Available"),
                _legend(Colors.red.shade100, "Booked"),
                _legend(theme.primaryColor, "Selected"),
              ],
            ),
          ),
          const Divider(),

          // --- ALL FIXES ARE HERE ---
          Expanded(
            // 1. Use InteractiveViewer to allow optional pinch-to-zoom
            child: InteractiveViewer(
              maxScale: 3.0,
              minScale: 1.0,
              // 2. Center the grid in the middle of the screen (for web)
              child: Center(
                // 3. Use a SingleChildScrollView to handle scrolling on small phones
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  // 4. Build the simple, intuitive seat grid
                  child: _buildSeatGrid(context, trip),
                ),
              ),
            ),
          ),
          // --- END OF FIXES ---

          // This is your original, unchanged Bottom Bar
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
                    onPressed: controller.selectedSeats.isEmpty
                        ? null
                        : () async {
                            bool success = await controller.processBooking(
                              context,
                            );
                            if (success && context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TicketScreen(),
                                ),
                                (r) => false,
                              );
                            }
                          },
                    child: controller.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text("PAY NOW"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the seat grid
  Widget _buildSeatGrid(BuildContext context, Trip trip) {
    // Calculate the number of rows needed (e.g., 40 seats / 4 per row = 10 rows)
    final int numRows = (trip.totalSeats / 4).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min, // Make column wrap its children
      children: List.generate(numRows, (rowIndex) {
        // e.g., 10 rows
        // Calculate seat numbers for this row
        int seatL1 = (rowIndex * 4) + 1; // Left 1: 1, 5, 9...
        int seatL2 = (rowIndex * 4) + 2; // Left 2: 2, 6, 10...
        int seatR1 = (rowIndex * 4) + 3; // Right 1: 3, 7, 11...
        int seatR2 = (rowIndex * 4) + 4; // Right 2: 4, 8, 12...

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Keep rows compact
            children: [
              // Left Side (Seats 1 & 2)
              Row(
                children: [
                  _Seat(seatNumber: seatL1),
                  const SizedBox(width: 12),
                  _Seat(seatNumber: seatL2),
                ],
              ),

              const SizedBox(width: 30), // The Aisle
              // Right Side (Seats 3 & 4)
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
    );
  }

  // Unchanged legend widget
  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

// --- NEW WIDGET FOR A SINGLE SEAT ---
// This handles its own state (booked, selected, available)

class _Seat extends StatelessWidget {
  const _Seat({required this.seatNumber});
  final int seatNumber;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final trip = controller.selectedTrip!;
    final theme = Theme.of(context);

    // Stop building if we're past the total number of seats
    if (seatNumber > trip.totalSeats) {
      return Container(width: 50, height: 50); // Empty placeholder
    }

    // Check seat status
    final bool isBooked = trip.bookedSeats.contains(seatNumber);
    final bool isSelected = controller.selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: isBooked
          ? null // Can't tap if booked
          : () => controller.toggleSeat(seatNumber),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.red.shade100
              : isSelected
              ? theme.primaryColor
              : theme.cardColor, // Use theme color
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.primaryColor.withOpacity(0.5))
              : Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: Center(
          child: isBooked
              ? Icon(Icons.close, size: 16, color: Colors.red.shade900)
              : Text(
                  "$seatNumber",
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.textTheme.bodyMedium!.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
