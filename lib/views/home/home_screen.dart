import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../results/bus_list_screen.dart';
import '../admin/admin_dashboard.dart';

/// BL-01: Home Page + Quick Search
/// Main landing screen with hero section and search form
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);

    return Scaffold(
      body: Stack(
        children: [
          // ==================== HERO SECTION ====================
          _buildHeroSection(context, controller),

          // ==================== SEARCH CARD (Floating) ====================
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            child: _buildSearchCard(context, controller),
          ),
        ],
      ),
    );
  }

  /// Hero Section with Gradient Background (Magiya Style)
  Widget _buildHeroSection(BuildContext context, TripController controller) {
    return Container(
      height: 300,
      decoration: AppTheme.heroGradient,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (Logo + Admin Toggle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Logo
                  Row(
                    children: [
                      Icon(Icons.directions_bus, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(AppConstants.appName, style: AppTheme.heroTitle),
                    ],
                  ),

                  // Admin Toggle Button (ADM-01)
                  IconButton(
                    icon: Icon(
                      controller.isAdminMode
                          ? Icons.admin_panel_settings
                          : Icons.person_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      controller.toggleAdminMode();
                      if (controller.isAdminMode) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboard(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Hero Text
              Text(AppConstants.appTagline, style: AppTheme.heroTitle),
              const SizedBox(height: 8),
              Text(AppConstants.appSubtitle, style: AppTheme.heroSubtitle),
            ],
          ),
        ),
      ),
    );
  }

  /// Search Card (BL-01: Search Form)
  Widget _buildSearchCard(BuildContext context, TripController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Demo Mode Notice
            if (AppConstants.isDemoMode)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningAmber.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppTheme.secondaryOrangeDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppConstants.demoNotice,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryOrangeDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (AppConstants.isDemoMode) const SizedBox(height: 16),

            // From City Dropdown
            _buildCityDropdown(
              context: context,
              label: 'From',
              icon: Icons.my_location,
              value: controller.fromCity,
              onChanged: controller.setFromCity,
            ),

            const SizedBox(height: 16),

            // To City Dropdown
            _buildCityDropdown(
              context: context,
              label: 'To',
              icon: Icons.location_on,
              value: controller.toCity,
              onChanged: controller.setToCity,
            ),

            const SizedBox(height: 16),

            // Date Picker
            _buildDatePicker(context, controller),

            const SizedBox(height: 24),

            // Search Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        await controller.searchTrips(context);
                        if (context.mounted &&
                            controller.searchResults.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusListScreen(),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'SEARCH BUSES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// City Dropdown Builder
  Widget _buildCityDropdown({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: AppConstants.sriLankanCities
          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
          .toList(),
      onChanged: onChanged,
    );
  }

  /// Date Picker Field
  Widget _buildDatePicker(BuildContext context, TripController controller) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.primaryBlue,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppTheme.textDark,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          controller.setTravelDate(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Travel',
          prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          controller.travelDate == null
              ? 'Select Date'
              : DateFormat('EEEE, MMM dd, yyyy').format(controller.travelDate!),
          style: TextStyle(
            color: controller.travelDate == null
                ? AppTheme.textGrey
                : AppTheme.textDark,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
