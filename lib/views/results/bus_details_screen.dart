import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';

class BusDetailsScreen extends StatelessWidget {
  final Trip trip;
  const BusDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                ],
              ),
            ),
          ],
        ),
      ),
      // --- ADDED STATIC NAVBAR HERE ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0, // Keeps 'Search' highlighted
        onDestinationSelected: (index) {
          // Static: Does nothing
        },
        backgroundColor: theme.cardColor,
        elevation: 3,
        indicatorColor: theme.primaryColor.withAlpha(60),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            label: 'Support',
          ),
        ],
      ),
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
            // Depart
            Expanded(
              child: _infoColumn(
                theme,
                'Depart',
                DateFormat('hh:mm a').format(trip.departureTime),
                trip.fromCity,
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
            ),

            // Arrive
            Expanded(
              child: _infoColumn(
                theme,
                'Arrive',
                DateFormat('hh:mm a').format(trip.arrivalTime),
                trip.toCity,
              ),
            ),

            // Platform / Duration
            Expanded(
              child: _infoColumn(
                theme,
                'Platform',
                trip.platformNumber,
                'Est: ${trip.arrivalTime.difference(trip.departureTime).inHours}h',
              ),
            ),
            Expanded(
              child: _infoColumn(
                theme,
                'Total KM',
                '122 KM',
                '',
              ),
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(180),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(180),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
