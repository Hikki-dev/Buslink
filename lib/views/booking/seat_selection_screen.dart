import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../utils/app_theme.dart';
import 'payment_screen.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';
import '../../services/auth_service.dart';
import 'payment_success_screen.dart';

class SeatSelectionScreen extends StatelessWidget {
  final Trip trip;
  final bool showBackButton;
  final bool isConductorMode;

  const SeatSelectionScreen(
      {super.key,
      required this.trip,
      this.showBackButton = false,
      this.isConductorMode = false});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    List<int> selectedSeats = controller.selectedSeats;

    // Determine if we need an AppBar
    // - On Mobile: Yes (unless specific case?)
    // - On Desktop: Only if showBackButton is true
    final bool showAppBar = !isDesktop || showBackButton;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar
          ? AppBar(
              title: const Text("Select Seats",
                  style: TextStyle(fontFamily: 'Outfit', 
                      fontWeight: FontWeight.bold, color: Colors.black)),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              leading: showBackButton
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
                              _buildHeader(context, trip),
                              const SizedBox(height: 40),
                              _buildLegend(),
                              const SizedBox(height: 40),

                              // The Bus Visual
                              Container(
                                width: 340, // Fixed bus width
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(60),
                                      bottom: Radius.circular(30)),
                                  border: Border.all(
                                      color: Colors.grey.shade200, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Driver / Front
                                    Container(
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      decoration: const BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.black12))),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(Icons.exit_to_app,
                                              color: Colors.grey),
                                          Column(
                                            children: [
                                              const Icon(Icons.print,
                                                  size: 20, color: Colors.grey),
                                              const SizedBox(height: 8),
                                              Image.asset(
                                                  "assets/steering_wheel.png",
                                                  width: 34,
                                                  height: 34,
                                                  errorBuilder: (_, __, ___) =>
                                                      Icon(Icons.settings,
                                                          size: 34,
                                                          color: Colors
                                                              .grey.shade400))
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Seat Grid
                                    ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: (trip.totalSeats / 4).ceil(),
                                      itemBuilder: (context, index) {
                                        int rowStart = index * 4;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Left
                                              Row(
                                                children: [
                                                  _SeatItem(
                                                      seatNum: rowStart + 1,
                                                      trip: trip,
                                                      isSelected: selectedSeats
                                                          .contains(
                                                              rowStart + 1)),
                                                  const SizedBox(width: 14),
                                                  _SeatItem(
                                                      seatNum: rowStart + 2,
                                                      trip: trip,
                                                      isSelected: selectedSeats
                                                          .contains(
                                                              rowStart + 2)),
                                                ],
                                              ),
                                              // Aisle text periodically?
                                              if (index == 4)
                                                const Text("EXIT",
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold)),

                                              // Right
                                              Row(
                                                children: [
                                                  _SeatItem(
                                                      seatNum: rowStart + 3,
                                                      trip: trip,
                                                      isSelected: selectedSeats
                                                          .contains(
                                                              rowStart + 3)),
                                                  const SizedBox(width: 14),
                                                  _SeatItem(
                                                      seatNum: rowStart + 4,
                                                      trip: trip,
                                                      isSelected: selectedSeats
                                                          .contains(
                                                              rowStart + 4)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 20),
                                    // Back of bus
                                    Container(
                                      height: 10,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    )
                                  ],
                                ),
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

                // Bottom Selection Bar
                if (selectedSeats.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.white.withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, -5))
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 24), // Reduced padding
                      child: Center(
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
                                        style: TextStyle(fontFamily: 'Inter', 
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(
                                        "LKR ${(trip.price * selectedSeats.length).toStringAsFixed(0)}",
                                        style: const TextStyle(fontFamily: 'Outfit', 
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                    Text(selectedSeats.join(", "),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontFamily: 'Outfit', 
                                            color: AppTheme.primaryColor))
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (isConductorMode) {
                                    _handleConductorBooking(
                                        context, controller);
                                  } else {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const PaymentScreen()));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: isConductorMode
                                        ? Colors.green
                                        : AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 20), // Reduced btn padding
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: Text(
                                    isConductorMode
                                        ? "Issue Ticket (Cash)"
                                        : "Proceed to Pay",
                                    style: const TextStyle(fontFamily: 'Outfit', 
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Trip trip) {
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
            style:
                const TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("${trip.fromCity} ➔ ${trip.toCity}",
            style: const TextStyle(fontFamily: 'Inter', color: Colors.grey, fontSize: 16)),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.white, Colors.grey.shade300, "Available"),
        const SizedBox(width: 30),
        _legendItem(AppTheme.primaryColor, AppTheme.primaryColor, "Selected"),
        const SizedBox(width: 30),
        _legendItem(Colors.red.shade300, Colors.transparent, "Booked",
            icon: Icons.close),
      ],
    );
  }

  Widget _legendItem(Color bg, Color border, String label, {IconData? icon}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border)),
          child: icon != null ? Icon(icon, size: 16, color: Colors.grey) : null,
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500))
      ],
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

    final total = trip.price * controller.selectedSeats.length;
    final TextEditingController nameController = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Issue Cash Ticket",
                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Review Booking:",
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 8),
                  const Text("Collect cash before confirming.",
                      style: TextStyle(color: Colors.red, fontSize: 12))
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final String pName = nameController.text.isEmpty
                          ? "Offline Passenger"
                          : nameController.text;

                      final success = await controller.createOfflineBooking(
                          context, pName, user);

                      if (success && context.mounted) {
                        final ticket = controller.currentTicket;
                        if (ticket != null) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PaymentSuccessScreen(),
                                  settings: RouteSettings(arguments: {
                                    'booking_id': ticket.ticketId
                                  })));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Text("Confirm & Print"))
              ],
            ));
  }
}

class _SeatItem extends StatefulWidget {
  final int seatNum;
  final Trip trip;
  final bool isSelected;

  const _SeatItem(
      {required this.seatNum, required this.trip, required this.isSelected});

  @override
  State<_SeatItem> createState() => _SeatItemState();
}

class _SeatItemState extends State<_SeatItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);

    // --- BULK AVAILABILITY LOGIC ---
    // If bulk mode is on, we must check if seat is booked in ANY of the qualifying trips
    bool isBooked = false;
    bool isBlocked = false;

    if (controller.isBulkBooking &&
        controller.bulkSearchResults.isNotEmpty &&
        controller.bulkDates.length > 1) {
      // We need to find the "corresponding" trip in each day for the currently viewed trip.
      // The `widget.trip` is the "Day 0" trip.

      // Iterate through all days 0..duration-1
      for (int i = 0; i < controller.bulkSearchResults.length; i++) {
        final dayTrips = controller.bulkSearchResults[i];

        // Find matching bus
        final match = dayTrips
                .where((t) =>
                    t.busNumber == widget.trip.busNumber &&
                    t.operatorName == widget.trip.operatorName)
                .firstOrNull ??
            widget.trip;

        if (match.bookedSeats.contains(widget.seatNum)) {
          isBooked = true;
        }
        if (match.blockedSeats.contains(widget.seatNum)) {
          isBlocked = true;
        }
        if (isBooked || isBlocked) break; // Optimization
      }
    } else {
      // Standard single trip check
      isBooked = widget.trip.bookedSeats.contains(widget.seatNum);
      isBlocked = widget.trip.blockedSeats.contains(widget.seatNum);
    }
    // -------------------------------

    if (widget.seatNum > widget.trip.totalSeats) {
      return const SizedBox(width: 44, height: 44);
    }

    final isUnavailable = isBooked || isBlocked;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: isUnavailable
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap:
            isUnavailable ? null : () => controller.toggleSeat(widget.seatNum),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isBlocked
                ? Colors.amber // Blocked = Yellow
                : isBooked
                    ? Colors.red.shade300 // Booked = Red
                    : widget.isSelected
                        ? null
                        : isHovered
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.white,
            gradient: widget.isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.8)
                      ])
                : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: widget.isSelected
                    ? AppTheme.primaryColor
                    : isUnavailable
                        ? Colors.transparent
                        : isHovered
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                width: widget.isSelected || isHovered ? 2 : 1),
            boxShadow: widget.isSelected || isHovered
                ? [
                    BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: isBlocked
                ? const Icon(Icons.block, size: 16, color: Colors.black54)
                : isBooked
                    ? const Icon(Icons.close, size: 16, color: Colors.grey)
                    : Text(
                        "${widget.seatNum}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.isSelected
                              ? Colors.white
                              : isHovered
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade700,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
