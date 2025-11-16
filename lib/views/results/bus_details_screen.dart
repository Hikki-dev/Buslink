// lib/views/results/bus_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_constants.dart';
import '../booking/seat_selection_screen.dart';

class BusDetailsScreen extends StatelessWidget {
  final Trip trip;
  const BusDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<TripController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${trip.fromCity} to ${trip.toCity}'),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTripInfo(theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Route & Stops', theme),
                  _buildStopsList(theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Features', theme),
                  _buildFeaturesGrid(theme),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBookingBar(context, theme, controller),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withAlpha(200)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.operatorName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  trip.busType,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'LKR ${trip.price.toStringAsFixed(0)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfo(ThemeData theme) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoColumn(
              theme,
              'Depart',
              DateFormat('hh:mm a').format(trip.departureTime),
              trip.fromCity,
            ),
            const Icon(Icons.arrow_forward, color: Colors.grey),
            _infoColumn(
              theme,
              'Arrive',
              DateFormat('hh:mm a').format(trip.arrivalTime),
              trip.toCity,
            ),
            _infoColumn(
              theme,
              'Platform',
              trip.platformNumber,
              'Est. Duration: ${trip.arrivalTime.difference(trip.departureTime).inHours}h',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(
    ThemeData theme,
    String title,
    String time,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(180),
          ),
        ),
        Text(time, style: theme.textTheme.titleLarge),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(180),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStopsList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: trip.stops.map((stop) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: theme.primaryColor),
                const SizedBox(width: 10),
                Text(stop, style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturesGrid(ThemeData theme) {
    if (trip.features.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No features listed for this bus.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: trip.features.length,
      itemBuilder: (context, index) {
        final feature = trip.features[index];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppConstants.getBusFeatureIcon(feature),
                  size: 18,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingBar(
    BuildContext context,
    ThemeData theme,
    TripController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ElevatedButton(
        style: theme.elevatedButtonTheme.style
            // FIX: Replaced 'MaterialStateProperty' with 'WidgetStateProperty'
            ?.copyWith(
              minimumSize: WidgetStateProperty.all(
                const Size(double.infinity, 50),
              ),
            ),
        onPressed: () {
          controller.selectTrip(trip);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SeatSelectionScreen()),
          );
        },
        child: const Text('Book Seats'),
      ),
    );
  }
}
