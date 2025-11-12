// lib/views/booking/seat_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend(Colors.grey.shade300, "Available"),
                _legend(Colors.red.shade100, "Booked"),
                _legend(theme.primaryColor, "Selected"),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 2 seats, aisle, 2 seats
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: trip.totalSeats + (trip.totalSeats ~/ 4), // Add aisles
              itemBuilder: (ctx, i) {
                final int aisleIndex = 2; // Aisle position
                final int itemsInRow = 5;
                if (i % itemsInRow == aisleIndex) {
                  return const Icon(
                    Icons.event_seat,
                    color: Colors.transparent,
                  ); // Aisle
                }

                int seat = i - (i ~/ itemsInRow);
                // FIX: Added curly braces
                if (seat >= trip.totalSeats) {
                  return const SizedBox();
                }

                int seatNumber = seat + 1;
                bool isBooked = trip.bookedSeats.contains(seatNumber);
                bool isSelected = controller.selectedSeats.contains(seatNumber);

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () => controller.toggleSeat(seatNumber),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.red.shade100
                          : isSelected
                          ? theme.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.black12)
                          : null,
                    ),
                    child: Center(
                      child: isBooked
                          ? Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red.shade300,
                            )
                          : Text(
                              "$seatNumber",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                );
              },
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
                    onPressed: controller.selectedSeats.isEmpty
                        ? null
                        : () async {
                            // BL-19: Digital Payment
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

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
