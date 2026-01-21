import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import 'admin_screen.dart';
import 'layout/admin_navbar.dart';
import 'layout/admin_footer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          const AdminNavBar(selectedIndex: 0),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 40 : 20,
                horizontal: isDesktop ? 40 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header & Welcome
                        Text("Dashboard",
                            style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText)),
                        Text("Welcome back, Admin",
                            style: GoogleFonts.inter(
                                color: Colors.grey.shade600, fontSize: 16)),
                        const SizedBox(height: 30),

                        // 2. Quick Actions Row (Scrollable)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _quickActionButton(
                                context,
                                "Add New Trip",
                                Icons.add,
                                Colors.red.shade700,
                                Colors.white,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminScreen(trip: null))),
                              ),
                              const SizedBox(width: 12),
                              _quickActionButton(
                                context,
                                "Add Route",
                                Icons.alt_route,
                                const Color(0xFF1E1E1E), // Dark
                                Colors.white,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminScreen(trip: null))),
                              ),
                              const SizedBox(width: 12),
                              _quickActionButton(
                                context,
                                "Manage Routes",
                                Icons.map_outlined,
                                Colors.white,
                                Colors.black87,
                                hasBorder: true,
                              ),
                              const SizedBox(width: 12),
                              _quickActionButton(
                                context,
                                "Refunds",
                                Icons.monetization_on_outlined,
                                Colors.white,
                                Colors.black87,
                                hasBorder: true,
                              ),
                              const SizedBox(width: 12),
                              _quickActionButton(
                                context,
                                "Bookings",
                                Icons.confirmation_number_outlined,
                                Colors.white,
                                Colors.black87,
                                hasBorder: true,
                              ),
                              const SizedBox(width: 12),
                              _quickActionButton(
                                context,
                                "Analytics",
                                Icons.bar_chart_outlined,
                                Colors.white,
                                Colors.black87,
                                hasBorder: true,
                              ),
                              const SizedBox(width: 12),
                              _quickActionButton(
                                context,
                                "App Feedback",
                                Icons.feedback_outlined,
                                Colors.white,
                                Colors.black87,
                                hasBorder: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 3. Search Section
                        _buildSearchSection(context, controller, isDesktop),
                        const SizedBox(height: 30),

                        // 4. Results
                        StreamBuilder<List<Trip>>(
                          stream: controller.searchResultsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(),
                              ));
                            }

                            final trips = snapshot.data ?? [];

                            if (trips.isEmpty) {
                              return _buildEmptyState();
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: trips.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return _buildResultCard(
                                    context, trips[index], controller);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  const AdminFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
      BuildContext context, String label, IconData icon, Color bg, Color fg,
      {bool hasBorder = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30), // Pill shape
          border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
          boxShadow: hasBorder
              ? []
              : [
                  BoxShadow(
                      color: bg.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(
      BuildContext context, TripController controller, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("FIND ROUTES",
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.2)),
          const SizedBox(height: 20),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildSearchInput(context, controller, true)),
                const SizedBox(width: 16),
                _buildSearchButton(context, controller),
              ],
            )
          else
            Column(
              children: [
                _buildSearchInput(context, controller, false),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _buildSearchButton(context, controller),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, TripController controller) {
    return SizedBox(
      height: 54, // Match input height
      child: ElevatedButton(
        onPressed: () => controller.searchTrips(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Search"),
      ),
    );
  }

  Widget _buildSearchInput(
      BuildContext context, TripController controller, bool isDesktop) {
    final originField = _dropdown(
        hint: "From",
        icon: Icons.flight_takeoff,
        value: controller.fromCity,
        items: AppConstants.cities,
        onChanged: (v) => controller.setFromCity(v));

    final destField = _dropdown(
        hint: "To",
        icon: Icons.flight_land,
        value: controller.toCity,
        items: AppConstants.cities,
        onChanged: (v) => controller.setToCity(v));

    final dateField = InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: controller.travelDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: AppTheme.primaryColor,
                colorScheme:
                    const ColorScheme.light(primary: AppTheme.primaryColor),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) controller.setDate(picked);
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              controller.travelDate != null
                  ? DateFormat('EEE, MMM d').format(controller.travelDate!)
                  : "Select Date",
              style: GoogleFonts.inter(
                  color: controller.travelDate != null
                      ? Colors.black87
                      : Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: originField),
          const SizedBox(width: 16),
          Expanded(child: destField),
          const SizedBox(width: 16),
          Expanded(child: dateField),
        ],
      );
    } else {
      return Column(
        children: [
          originField,
          const SizedBox(height: 12),
          destField,
          const SizedBox(height: 12),
          dateField,
        ],
      );
    }
  }

  Widget _dropdown(
      {required String hint,
      required IconData icon,
      required String? value,
      required List<String> items,
      required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded,
                size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text("No routes found",
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Try adjusting your search criteria",
              style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildResultCard(
      BuildContext context, Trip trip, TripController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Time & Icon
          Column(
            children: [
              Text(DateFormat('HH:mm').format(trip.departureTime),
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 40,
                width: 2,
                color: Colors.grey.shade200,
              ),
              Text(DateFormat('HH:mm').format(trip.arrivalTime),
                  style: GoogleFonts.outfit(
                      fontSize: 16, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(width: 24),

          // Middle: Route Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("${trip.fromCity} ➝ ${trip.toCity}",
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    _tag(trip.busType, Colors.blue.shade50,
                        Colors.blue.shade700),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_bus_outlined,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(trip.operatorName,
                        style: GoogleFonts.inter(color: Colors.grey.shade600)),
                    const SizedBox(width: 16),
                    if (trip.via.isNotEmpty) ...[
                      Icon(Icons.alt_route_outlined,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text("Via ${trip.via}",
                          style:
                              GoogleFonts.inter(color: Colors.grey.shade600)),
                    ]
                  ],
                )
              ],
            ),
          ),

          // Right: Actions
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AdminScreen(trip: trip)));
                },
                icon: const Icon(Icons.edit_outlined),
                tooltip: "Edit",
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, controller, trip.id),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "Delete",
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  void _confirmDelete(
      BuildContext context, TripController controller, String tripId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Bus?"),
        content: const Text(
            "Are you sure you want to delete this route? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                controller.deleteTrip(context, tripId);
              },
              child: const Text("Delete")),
        ],
      ),
    );
  }
}
