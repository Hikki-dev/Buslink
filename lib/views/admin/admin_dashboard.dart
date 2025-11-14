// lib/views/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import 'admin_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log Out",
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchCard(context, controller, theme),
          Expanded(
            child: Consumer<TripController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.searchResults.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "Search for a route and date to see trips.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.searchResults.length,
                  itemBuilder: (ctx, i) {
                    final trip = controller.searchResults[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          "${trip.busNumber} - ${trip.fromCity} to ${trip.toCity}",
                        ),
                        subtitle: Text(
                          "Departs: ${DateFormat('MMM d, hh:mm a').format(trip.departureTime)}",
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminScreen(trip: trip),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(
    BuildContext context,
    TripController controller,
    ThemeData theme,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown(
              icon: Icons.departure_board,
              hint: 'From',
              value: controller.fromCity,
              items: AppConstants.cities,
              onChanged: (val) => controller.setFromCity(val),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              icon: Icons.location_on,
              hint: 'To',
              value: controller.toCity,
              items: AppConstants.cities.reversed.toList(),
              onChanged: (val) => controller.setToCity(val),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildDatePicker(context, controller, theme),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => controller.searchTrips(context),
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String hint,
    String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
  }) {
    return DropdownButtonFormField<String>(
      // 1. FIX: Changed 'value' to 'initialValue'
      initialValue: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: theme.primaryColor),
        hintText: hint,
      ),
      items: items.map((city) {
        return DropdownMenuItem(value: city, child: Text(city));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    TripController controller,
    ThemeData theme,
  ) {
    return TextFormField(
      key: Key(controller.travelDate.toString()),
      readOnly: true,
      initialValue: controller.travelDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(controller.travelDate!),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.calendar_today, color: theme.primaryColor),
        hintText: 'Select Date',
      ),
      onTap: () => _selectDate(context, controller),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TripController controller,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: controller.travelDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      controller.setDate(pickedDate);
    }
  }
}
