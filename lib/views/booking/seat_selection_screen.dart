import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../utils/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart'; // Added for SMS

import 'payment_screen.dart';
import 'bulk_confirmation_screen.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';
import '../../services/auth_service.dart';
import 'payment_success_screen.dart';
import 'bus_layout_widget.dart';
import '../auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeatSelectionScreen extends StatefulWidget {
  final EnrichedTrip trip;
  final bool showBackButton;
  final bool isConductorMode;

  const SeatSelectionScreen(
      {super.key,
      required this.trip,
      this.showBackButton = true,
      this.isConductorMode = false});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _autoSelectForBulk(); // User requested manual selection only
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    List<int> selectedSeats =
        controller.selectedSeats.map((e) => int.tryParse(e) ?? 0).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine if we need an AppBar
    // - On Mobile: Yes (unless specific case?)
    // - On Desktop: Only if showBackButton is true
    final bool showAppBar = !isDesktop || widget.showBackButton;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: Text("Select Seats",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
              centerTitle: true,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
                  Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              iconTheme:
                  IconThemeData(color: isDark ? Colors.white : Colors.black),
              leading: widget.showBackButton
                  ? const BackButton()
                  : null, // Default auto-leading is usually fine
            )
          : null,
      body: Column(
        children: [
          if (isDesktop) const DesktopNavBar(),
          Expanded(
            child: Stack(
              children: [
                // Scrollable Content
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 140),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            children: [
                              _buildHeader(context, widget.trip, isDark),
                              const SizedBox(height: 40),
                              _buildLegend(isDark),
                              const SizedBox(height: 40),

                              // The Bus Visual (Refactored)
                              StreamBuilder<EnrichedTrip?>(
                                stream: controller
                                    .getTripRealtimeStream(widget.trip.trip.id),
                                initialData: widget.trip,
                                builder: (context, snapshot) {
                                  final currentTrip =
                                      snapshot.data?.trip ?? widget.trip.trip;
                                  return BusLayoutWidget(
                                    trip: currentTrip,
                                    totalSeats: widget.trip.totalSeats,
                                    selectedSeats: selectedSeats,
                                    isDark: isDark,
                                    onSeatToggle: (seatNum) {
                                      controller.toggleSeat(seatNum.toString());
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      if (isDesktop) const AppFooter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: selectedSeats.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, -5))
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${selectedSeats.length} Seats Selected",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black
                                        .withValues(alpha: 0.7), // No Grey
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "LKR ${(widget.trip.price * selectedSeats.length).toStringAsFixed(0)}",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black, // Strict
                              ),
                            ),
                            Text(
                              selectedSeats.join(", "),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.isConductorMode) {
                            _handleConductorBooking(context, controller);
                          } else {
                            final user =
                                Provider.of<User?>(context, listen: false);
                            if (user == null) {
                              // GUEST BOOKING ATTEMPT
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Theme.of(context).cardColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: Text("Sign In Required",
                                      style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black)),
                                  content: Text(
                                      "To confirm your booking, you need to sign in to your BusLink account.",
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black)),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text("Close",
                                            style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black))),
                                    ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const LoginScreen()));
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8))),
                                        child: const Text("Sign In"))
                                  ],
                                ),
                              );
                            } else {
                              if (controller.isBulkBooking) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => BulkConfirmationScreen(
                                            trip: widget.trip)));
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const PaymentScreen()));
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isConductorMode
                                ? Colors.green
                                : AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text(
                            widget.isConductorMode
                                ? "Issue Ticket (Cash)"
                                : "Proceed to Pay",
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, EnrichedTrip trip, bool isDark) {
    final controller = Provider.of<TripController>(context);
    final isBulk = controller.isBulkBooking && controller.bulkDates.length > 1;

    return Column(
      children: [
        if (isBulk)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
                "Multi-Day Booking (${controller.bulkDates.length} Days)",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        Text(trip.operatorName,
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 8),
        Text("${trip.fromCity} ➔ ${trip.toCity}",
            style: TextStyle(
                fontFamily: 'Inter',
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7), // No Grey
                fontSize: 16)),
      ],
    );
  }

  // Helper for legend items
  Widget _buildLegendItem(
      Color color, Color borderColor, String label, bool isDark,
      {IconData? icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, // Increased size for visibility
          height: 32,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
                color: borderColor.withValues(alpha: 0.5),
                width: 2), // High contrast border
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon != null
              ? Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9))
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.7), // No Grey
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem(
              isDark ? Colors.transparent : Colors.white,
              isDark ? Colors.white : Colors.black, // High contrast border
              "Available",
              isDark,
            ),
            _buildLegendItem(
              AppTheme.primaryColor,
              AppTheme.primaryColor,
              "Selected",
              isDark,
            ),
            _buildLegendItem(
              Colors.red.shade300,
              Colors.red.shade300,
              "Booked",
              isDark,
              icon: Icons.close,
            ),
            _buildLegendItem(
              Colors.amber,
              Colors.amber,
              "Blocked",
              isDark,
              icon: Icons.block,
            ),
          ],
        ),
      ),
    );
  }

  void _handleConductorBooking(
      BuildContext context, TripController controller) {
    // We need to resolve auth service here to get the 'Conductor' user
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Conductor not logged in?")));
      return;
    }

    final total = widget.trip.price * controller.selectedSeats.length;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneNumberController = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Issue Cash Ticket",
                  style: TextStyle(
                      fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Review Booking:",
                        style: TextStyle(
                            fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Seats: ${controller.selectedSeats.join(', ')}"),
                    Text("Total Amount: LKR ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: "Passenger Name (Optional)",
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: "Mobile Number (Required)",
                          hintText: "07xxxxxxxx or +947xxxxxxxx",
                          helperText: "For SMS Ticket",
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    const Text("Collect cash before confirming.",
                        style: TextStyle(color: Colors.red, fontSize: 12))
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      // 1. Validation for SL Number
                      String phone = phoneNumberController.text.trim();
                      if (phone.startsWith('94')) phone = '+$phone';

                      bool isValid = false;
                      if (phone.startsWith('07') && phone.length == 10) {
                        isValid = true;
                      }
                      if (phone.startsWith('+947') && phone.length == 12) {
                        isValid = true;
                      }

                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                "Invalid SL Number. Use 07xxxxxxxx or +947xxxxxxxx"),
                            backgroundColor: Colors.red));
                        return;
                      }

                      Navigator.pop(ctx);
                      final String pName = nameController.text.isEmpty
                          ? "Offline Passenger"
                          : nameController.text;

                      try {
                        final ticket = await FirestoreService()
                            .createOfflineBooking(
                                widget.trip.trip,
                                controller.selectedSeats
                                    .map((e) => int.tryParse(e) ?? 0)
                                    .toList(),
                                pName,
                                user,
                                phoneNumber: phone);

                        if (context.mounted) {
                          Provider.of<TripController>(context, listen: false)
                              .selectTrip(widget.trip);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "Ticket Issued! ID: ${ticket.ticketId.substring(0, 5)}... SMS Sending...")));

                          await SmsService.sendTicketCopy(ticket);

                          if (context.mounted) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PaymentSuccessScreen(),
                                    settings: RouteSettings(arguments: {
                                      'booking_id': ticket.ticketId,
                                      'phone_number': phone
                                    })));
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Text("Confirm & Send SMS"))
              ],
            ));
  }
}
