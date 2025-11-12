import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/bus_controller.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BusController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Staff Dashboard")),
      body: ListView.builder(
        itemCount: controller.searchResults.length,
        itemBuilder: (ctx, i) {
          final trip = controller.searchResults[i];
          return ExpansionTile(
            title: Text("${trip.busNumber} - ${trip.toCity}"),
            subtitle: Text(
              "Status: ${trip.status} | Platform: ${trip.platformNumber}",
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ADM-14: Platform Assignment
                    TextFormField(
                      initialValue: trip.platformNumber,
                      decoration: const InputDecoration(
                        labelText: "Update Platform",
                      ),
                      onFieldSubmitted: (val) {
                        controller.updateTrip(
                          trip.id,
                          trip.status,
                          trip.delayMinutes,
                          val,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // ADM-05: Delay/Cancel Panel
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () => controller.updateTrip(
                              trip.id,
                              'onTime',
                              0,
                              trip.platformNumber,
                            ),
                            child: const Text("On Time"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: () => controller.updateTrip(
                              trip.id,
                              'delayed',
                              15,
                              trip.platformNumber,
                            ),
                            child: const Text("Delay 15m"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => controller.updateTrip(
                              trip.id,
                              'cancelled',
                              0,
                              trip.platformNumber,
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
