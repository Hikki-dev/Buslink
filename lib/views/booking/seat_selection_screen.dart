import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/bus_controller.dart';
import '../ticket/ticket_screen.dart';

class SeatSelectionScreen extends StatelessWidget {
  const SeatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BusController>(context);
    final trip = controller.currentTrip!;

    return Scaffold(
      appBar: AppBar(title: const Text("Select Seats")),
      body: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend(Colors.grey.shade300, "Available"),
                _legend(Colors.red.shade100, "Booked"),
                _legend(Theme.of(context).primaryColor, "Selected"),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: trip.totalSeats,
              itemBuilder: (ctx, i) {
                int seat = i + 1;
                bool isBooked = trip.bookedSeats.contains(seat);
                bool isSelected = controller.selectedSeats.contains(seat);
                
                if (i % 4 == 2) return const SizedBox(); // Aisle

                return GestureDetector(
                  onTap: isBooked ? null : () => controller.toggleSeat(seat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBooked ? Colors.red.shade100 : isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.black12) : null,
                    ),
                    child: Center(
                      child: isBooked 
                        ? Icon(Icons.close, size: 16, color: Colors.red.shade300)
                        : Text("$seat", style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          ),
          // Checkout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${controller.selectedSeats.length} Seats", style: const TextStyle(fontSize: 16)),
                    Text("LKR ${(controller.selectedSeats.length * trip.price).toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFA726))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.selectedSeats.isEmpty ? null : () async {
                      // BL-19: Digital Payment
                      bool success = await controller.processBooking();
                      if (success && context.mounted) {
                         Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const TicketScreen()), (r) => false);
                      }
                    },
                    child: controller.isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) 
                      : const Text("PAY NOW"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(children: [Container(width: 16, height: 16, color: color), const SizedBox(width: 8), Text(text)]);
  }
}