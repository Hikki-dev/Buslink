import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/bus_controller.dart';
import '../booking/seat_selection_screen.dart';

class BusDetailsScreen extends StatelessWidget {
  const BusDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<BusController>(context).currentTrip!;

    return Scaffold(
      appBar: AppBar(title: const Text("Trip Details")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BL-03: Bus Details
                  Text(
                    "${trip.fromCity} to ${trip.toCity}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bus No: ${trip.busNumber} | Type: ${trip.busType}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Stops",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Stepper for Stops
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trip.stops.length,
                    itemBuilder: (ctx, i) => Row(
                      children: [
                        Column(
                          children: [
                            Container(width: 2, height: 10, color: Colors.grey),
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: Theme.of(context).primaryColor,
                            ),
                            if (i != trip.stops.length - 1)
                              Container(
                                width: 2,
                                height: 30,
                                color: Colors.grey,
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Text(
                          trip.stops[i],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BL-03: Refund Policy
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Refund Policy",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "• Cancel ≥ 48h: 100% Refund\n• Cancel ≥ 12h: 50% Refund\n• No-shows: No Refund",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SeatSelectionScreen(),
                  ),
                ),
                child: const Text("CONTINUE TO SEATS"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
