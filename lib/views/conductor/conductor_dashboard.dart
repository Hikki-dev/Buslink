// lib/views/conductor/conductor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart'; // Import HomeScreen
import 'conductor_trip_management_screen.dart'; // Import new screen

// Convert to StatefulWidget to hold the text controller
class ConductorDashboard extends StatefulWidget {
  const ConductorDashboard({super.key});

  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard> {
  final _busNumberController = TextEditingController();

  @override
  void dispose() {
    _busNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final controller = Provider.of<TripController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Conductor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log Out",
            onPressed: () {
              authService.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- New Search Section ---
                TextField(
                  controller: _busNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Your Bus Number (e.g., NP-7788)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<TripController>(
                  builder: (context, consumerController, child) {
                    return ElevatedButton(
                      onPressed: consumerController.isLoading
                          ? null
                          : () async {
                              final busNumber =
                                  _busNumberController.text.trim();
                              bool success =
                                  await controller.findTripByBusNumber(
                                context,
                                busNumber,
                              );
                              if (success && context.mounted) {
                                // Navigate to the management screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ConductorTripManagementScreen(
                                      trip: controller.conductorSelectedTrip!,
                                    ),
                                  ),
                                );
                              }
                            },
                      child: consumerController.isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Find My Bus"),
                    );
                  },
                ),
                const Divider(height: 40),

                // --- "Book a Bus Now" Button ---
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the customer's home screen for booking
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Text("Book a Bus Now"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
