// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../results/bus_list_screen.dart';
import '../admin/admin_dashboard.dart';
import '../../utils/app_constants.dart'; // <-- FIX: This import will now work

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BusLink',
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontFamily: 'Magiya',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              controller.isAdminMode
                  ? Icons.person
                  : Icons.admin_panel_settings,
            ),
            onPressed: () {
              controller.toggleAdminMode();
              if (controller.isAdminMode) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchHeader(context, controller, theme),
            _buildQuickActions(context, theme),
            _buildPromotions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(
    BuildContext context,
    TripController controller,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0).copyWith(bottom: 40),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withAlpha(200)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown(
                icon: Icons.departure_board,
                hint: 'From',
                value: controller.fromCity,
                // <-- FIX: This now works
                items: AppConstants.cities,
                onChanged: (val) => controller.setFromCity(val),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                icon: Icons.arrival_board,
                hint: 'To',
                value: controller.toCity,
                // <-- FIX: This now works
                items: AppConstants.cities.reversed.toList(),
                onChanged: (val) => controller.setToCity(val),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildDatePicker(context, controller, theme),
              const SizedBox(height: 20),
              ElevatedButton(
                style: theme.elevatedButtonTheme.style,
                onPressed: () {
                  controller.searchTrips(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusListScreen()),
                  );
                },
                child: controller.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Search Buses'),
              ),
            ],
          ),
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
      value: value,
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
      readOnly: true,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.calendar_today, color: theme.primaryColor),
        hintText: controller.travelDate == null
            ? 'Select Date'
            : DateFormat('yyyy-MM-dd').format(controller.travelDate!),
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null) {
      // <-- FIX: Renamed to setDate
      controller.setDate(pickedDate);
    }
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionButton(
            context,
            theme,
            Icons.confirmation_number,
            'My Tickets',
          ),
          _quickActionButton(context, theme, Icons.cancel, 'Cancellations'),
          _quickActionButton(context, theme, Icons.support_agent, 'Support'),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.primaryColor.withAlpha(30),
          child: Icon(icon, size: 28, color: theme.primaryColor),
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildPromotions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0).copyWith(top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Offers & Promotions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.secondary.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Get 20% OFF your first ride!\nUse code: FIRSTBUS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
