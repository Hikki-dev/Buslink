import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/bus_controller.dart';
import '../home/home_screen.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BusController>(context);
    final trip = controller.currentTrip!;

    return Scaffold(
      backgroundColor: const Color(0xFF0056D2),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()))),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                const Text("Booking Confirmed!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 20),
                
                // BL-06: QR Code
                QrImageView(data: "${trip.id}-${controller.selectedSeats.join(',')}", size: 180),
                const SizedBox(height: 10),
                Text("Ticket ID: BL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}", style: const TextStyle(color: Colors.grey)),
                
                const Divider(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Bus Number", style: TextStyle(color: Colors.grey)),
                      Text(trip.busNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                    // BL-13: Platform (Dynamic)
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text("Platform", style: TextStyle(color: Colors.grey)),
                      Text(trip.platformNumber, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0056D2))),
                    ]),
                  ],
                ),
                const SizedBox(height: 20),
                _row("Route", "${trip.fromCity} ➔ ${trip.toCity}"),
                _row("Seats", controller.selectedSeats.join(", ")),
                _row("Passenger", "Saman Perera"), // Mock User
                
                const SizedBox(height: 20),
                const Text("Show this QR code to the conductor.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}