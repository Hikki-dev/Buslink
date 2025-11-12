import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../utils/app_theme.dart';
import 'bus_details_screen.dart';

/// BL-02: Available Bus List
/// BL-12: Alternative Bus Suggestions
class BusListScreen extends StatelessWidget {
  const BusListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("${controller.fromCity} ➔ ${controller.toCity}"),
      ),
      body: controller.searchResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  const Text("No buses found for this route."),
                  const Text(
                    "Try Colombo to Jaffna/Badulla for Demo.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                return _TripCard(trip: controller.searchResults[index]);
              },
            ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context, listen: false);
    final bool isDelayed = trip.status == TripStatus.delayed;
    final bool isCancelled = trip.status == TripStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.operatorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      trip.busType,
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Status Badges
                if (isCancelled)
                  const Chip(
                    label: Text(
                      "CANCELLED",
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  )
                else if (isDelayed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Delayed +${trip.delayMinutes} min",
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Times
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeColumn(trip.departureTime, trip.fromCity),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                _timeColumn(trip.arrivalTime, trip.toCity),
              ],
            ),
            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "LKR ${trip.price.toStringAsFixed(0)}",
                  style: AppTheme.priceText,
                ),

                // Action Button
                trip.isFull || isCancelled
                    ? OutlinedButton(
                        onPressed: () =>
                            _showAlternatives(context, controller, trip),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: Text(
                          isCancelled ? "View Options" : "Full - Alternatives",
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          controller.selectTrip(trip);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusDetailsScreen(),
                            ),
                          );
                        },
                        child: const Text("View Details"),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeColumn(DateTime time, String city) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('hh:mm a').format(time),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(city, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showAlternatives(
    BuildContext context,
    TripController controller,
    Trip trip,
  ) {
    final alternatives = controller.getAlternativeBuses(trip);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Alternative Buses",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (alternatives.isEmpty)
              const Text("No other buses found.")
            else
              ...alternatives.map(
                (alt) => ListTile(
                  title: Text(alt.operatorName),
                  subtitle: Text(
                    "${DateFormat('hh:mm a').format(alt.departureTime)} • LKR ${alt.price}",
                  ),
                  trailing: ElevatedButton(
                    child: const Text("View"),
                    onPressed: () {
                      Navigator.pop(ctx);
                      controller.selectTrip(alt);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusDetailsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
