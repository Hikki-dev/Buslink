// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../../services/auth_service.dart'; 
import '../results/bus_list_screen.dart';
import '../admin/admin_dashboard.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../placeholder/my_tickets_screen.dart';
import '../placeholder/cancellations_screen.dart';
import '../placeholder/support_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(
      context,
      listen: false,
    ); // <-- 3. GET AUTH SERVICE

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
          // Theme Toggle Button
          Consumer<ThemeController>(
            builder: (context, themeController, child) {
              bool isDark =
                  themeController.themeMode == ThemeMode.dark ||
                  (themeController.themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness ==
                          Brightness.dark);

              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: "Toggle Theme",
                onPressed: () {
                  if (isDark) {
                    themeController.setTheme(ThemeMode.light);
                  } else {
                    themeController.setTheme(ThemeMode.dark);
                  }
                },
              );
            },
          ),

          // Admin Panel Button
          IconButton(
            icon: Icon(
              controller.isAdminMode
                  ? Icons.person
                  : Icons.admin_panel_settings,
            ),
            tooltip: "Admin Panel",
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

          // --- 4. ADD LOGOUT BUTTON ---
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log Out",
            onPressed: () {
              authService.signOut(); // <-- This fixes the "unused import"
            },
          ),
          // --- END OF LOGOUT BUTTON ---
        ],
      ),
      body: SingleChildScrollView(
        // ... (rest of the file is unchanged)
        // ... (The rest of your home_screen.dart file is correct)
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
                items: AppConstants.cities,
                onChanged: (val) => controller.setFromCity(val),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                icon: Icons.location_on, // Corrected Icon
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
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
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
            ),
          ),
          _quickActionButton(
            context,
            theme,
            Icons.cancel,
            'Cancellations',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CancellationsScreen()),
            ),
          ),
          _quickActionButton(
            context,
            theme,
            Icons.support_agent,
            'Support',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.primaryColor.withAlpha(30),
            child: Icon(icon, size: 28, color: theme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
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
