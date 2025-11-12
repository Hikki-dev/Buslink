import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/bus_controller.dart';
import '../results/bus_list_screen.dart';
import '../admin/admin_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<String> cities = const ['Colombo', 'Jaffna', 'Badulla', 'Kandy', 'Galle'];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BusController>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Hero Background (Magiya Style)
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0056D2), Color(0xFF003B8F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("BusLink", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        // ADM-01: Admin Toggle
                        IconButton(
                          icon: Icon(controller.isAdminMode ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
                          onPressed: () {
                            controller.toggleAdmin();
                            if (controller.isAdminMode) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("For a Seamless Journey.", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text("Effortless travel starts with our trusted service.", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),

          // 2. Search Card (Floating)
          Padding(
            padding: const EdgeInsets.only(top: 220, left: 20, right: 20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BL-01: Search Fields
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("From", Icons.my_location),
                      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => controller.fromCity = val,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("To", Icons.location_on),
                      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => controller.toCity = val,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) controller.travelDate = date;
                      },
                      child: InputDecorator(
                        decoration: _inputDecoration("Date", Icons.calendar_today),
                        child: Text(
                          controller.travelDate == null ? "Select Date" : DateFormat('yyyy-MM-dd').format(controller.travelDate!)
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller.searchTrips(context);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const BusListScreen()));
                          }
                        },
                        child: controller.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SEARCH BUSES"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}