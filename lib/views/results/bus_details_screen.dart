import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../booking/seat_selection_screen.dart';

/// BL-03: Bus Details View
/// Shows detailed route, stops, fare breakdown, and refund policy
class BusDetailsScreen extends StatelessWidget {
  const BusDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final trip = controller.selectedTrip!;

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
                  // ==================== TRIP HEADER ====================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            style: TextStyle(color: AppTheme.textGrey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Operator: ${trip.operatorName}",
                            style: TextStyle(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================== TIMING INFO ====================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _timeInfo(
                            "Departure",
                            DateFormat('hh:mm a').format(trip.departureTime),
                            trip.fromCity,
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            size: 32,
                            color: AppTheme.primaryBlue,
                          ),
                          _timeInfo(
                            "Arrival",
                            DateFormat('hh:mm a').format(trip.arrivalTime),
                            trip.toCity,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================== STOPS ====================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Stops Along Route",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: trip.stops.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      if (i != 0)
                                        Container(
                                          width: 2,
                                          height: 10,
                                          color: AppTheme.borderLight,
                                        ),
                                      Icon(
                                        i == 0
                                            ? Icons.circle
                                            : i == trip.stops.length - 1
                                            ? Icons.location_on
                                            : Icons.circle_outlined,
                                        size: 12,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      if (i != trip.stops.length - 1)
                                        Container(
                                          width: 2,
                                          height: 20,
                                          color: AppTheme.borderLight,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    trip.stops[i],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          i == 0 || i == trip.stops.length - 1
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================== FARE BREAKDOWN ====================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Fare Details",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Base Fare",
                                style: TextStyle(color: AppTheme.textGrey),
                              ),
                              Text(
                                "LKR ${trip.price.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total per Seat",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "LKR ${trip.price.toStringAsFixed(2)}",
                                style: AppTheme.priceText,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================== REFUND POLICY ====================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Cancellation & Refund Policy",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.refundPolicy,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================== STICKY BUTTON ====================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SeatSelectionScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.event_seat, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "CONTINUE TO SEAT SELECTION",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeInfo(String label, String time, String city) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(city, style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
      ],
    );
  }
}
