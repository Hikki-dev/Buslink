// lib/views/results/bus_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import 'bus_details_screen.dart';

class BusListScreen extends StatelessWidget {
  const BusListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${controller.fromCity} to ${controller.toCity}',
              style: const TextStyle(fontSize: 18),
            ),
            if (controller.travelDate != null)
              Text(
                DateFormat('EEE, MMM d').format(controller.travelDate!),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
      body: Consumer<TripController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.searchResults.isEmpty) {
            return const Center(
              child: Text(
                'No buses found for this route.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: controller.searchResults.length,
            itemBuilder: (context, index) {
              final trip = controller.searchResults[index];
              return _buildBusCard(context, theme, controller, trip);
            },
          );
        },
      ),
    );
  }

  Widget _buildBusCard(
    BuildContext context,
    ThemeData theme,
    TripController controller,
    Trip trip,
  ) {
    bool isFull = trip.isFull;
    bool isCancelled = trip.status == TripStatus.cancelled;
    bool isDelayed = trip.status == TripStatus.delayed;
    Color cardColor =
        isFull || isCancelled ? Colors.grey.shade300 : theme.cardColor;
    Color onCardColor = isFull || isCancelled
        ? Colors.grey.shade600
        : theme.colorScheme.onSurface;

    // 1. REMOVED THE OUTER INKWELL
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. ADDED AN INKWELL HERE to keep the info section tappable
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusDetailsScreen(trip: trip),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(theme, trip, onCardColor, isDelayed),
                  const Divider(height: 20),
                  _buildCardBody(theme, trip, onCardColor),
                ],
              ),
            ),

            // 3. ADDED THE "BOOK NOW" BUTTON
            if (!isFull && !isCancelled) ...[
              const Divider(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusDetailsScreen(trip: trip),
                      ),
                    );
                  },
                  child: const Text('Book Now'),
                ),
              ),
            ],

            // --- (Your existing status warnings are unchanged) ---
            if (isDelayed)
              _buildStatusWarning(
                'Delayed: ${trip.delayMinutes} mins',
                Colors.orange,
              ),
            if (isFull) _buildStatusWarning('This bus is full', Colors.red),
            if (isCancelled)
              _buildStatusWarning('This trip is cancelled', Colors.red),
            if (isFull || isCancelled)
              _buildAlternatives(context, controller, trip),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    ThemeData theme,
    Trip trip,
    Color onCardColor,
    bool isDelayed,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.operatorName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onCardColor,
                ),
              ),
              Text(
                '${trip.busType} (${trip.busNumber})',
                style: theme.textTheme.bodyMedium?.copyWith(color: onCardColor),
              ),
            ],
          ),
        ),
        Text(
          'LKR ${trip.price.toStringAsFixed(0)}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCardBody(ThemeData theme, Trip trip, Color onCardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimeColumn(
          theme,
          'Depart',
          DateFormat('hh:mm a').format(trip.departureTime),
          trip.fromCity,
          onCardColor,
        ),
        Column(
          children: [
            Icon(Icons.directions_bus, color: onCardColor),
            Text(
              '${trip.arrivalTime.difference(trip.departureTime).inHours} hours',
              style: theme.textTheme.bodySmall?.copyWith(color: onCardColor),
            ),
          ],
        ),
        _buildTimeColumn(
          theme,
          'Arrive',
          DateFormat('hh:mm a').format(trip.arrivalTime),
          trip.toCity,
          onCardColor,
        ),
        Column(
          children: [
            Text(
              'Seats',
              style: theme.textTheme.bodyMedium?.copyWith(color: onCardColor),
            ),
            Text(
              '${trip.totalSeats - trip.bookedSeats.length}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: (trip.totalSeats - trip.bookedSeats.length) < 10
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeColumn(
    ThemeData theme,
    String title,
    String time,
    String location,
    Color onCardColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(color: onCardColor),
        ),
        Text(
          time,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: onCardColor,
          ),
        ),
        Text(
          location,
          style: theme.textTheme.bodyMedium?.copyWith(color: onCardColor),
        ),
      ],
    );
  }

  Widget _buildStatusWarning(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildAlternatives(
    BuildContext context,
    TripController controller,
    Trip trip,
  ) {
    // <-- FIX: Renamed to getAlternatives
    final alternatives = controller.getAlternatives(trip);
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Try these alternatives:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...alternatives.map((altTrip) {
            return ListTile(
              title: Text(altTrip.operatorName),
              subtitle: Text(
                'Departs: ${DateFormat('hh:mm a').format(altTrip.departureTime)}',
              ),
              trailing: Text('LKR ${altTrip.price.toStringAsFixed(0)}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusDetailsScreen(trip: altTrip),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
