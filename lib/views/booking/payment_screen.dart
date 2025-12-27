import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // For Redirect

import '../../controllers/trip_controller.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  final PaymentService _paymentService = PaymentService();

  Future<void> _handleCheckoutRedirect() async {
    setState(() => _isProcessing = true);
    final user = Provider.of<User?>(context, listen: false);
    final controller = Provider.of<TripController>(context, listen: false);

    if (user == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to continue")));
      return;
    }

    try {
      // 1. Create Pending Booking in DB (State Persistence)
      final bookingId = await controller.createPendingBooking(user);
      if (bookingId == null) {
        throw Exception("Failed to initialize booking.");
      }

      // 2. Construct Dynamic Redirect URLs
      // Use Uri.base to get the current domain (works for localhost & vercel)
      String origin = Uri.base.origin;
      // Normalize origin: remove trailing slash if present to avoid double slash with /#/
      if (origin.endsWith('/')) {
        origin = origin.substring(0, origin.length - 1);
      }

      // Note: We use a hash-friendly pattern if HashRouting is used, or path if PathUrlStrategy.
      // Default Flutter web uses Hash (#).
      // Stripe Success URL: origin + /#/payment_success?session_id={CHECKOUT_SESSION_ID} ... but Stripe replaces {}
      // We'll point to a clean route.
      String successUrl =
          "$origin/#/payment_success?booking_id=$bookingId&session_id={CHECKOUT_SESSION_ID}";
      String cancelUrl = "$origin/#/";

      final trip = controller.selectedTrip!;
      final seats = controller.selectedSeats;
      final totalAmount = (trip.price * seats.length).toStringAsFixed(2);

      // 3. Create Stripe Checkout Session via API
      final redirectUrl = await _paymentService.createCheckoutSession(
        amount: totalAmount,
        currency: "LKR",
        successUrl: successUrl,
        cancelUrl: cancelUrl,
        bookingId: bookingId,
      );

      if (redirectUrl != null) {
        // 4. Redirect User
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri,
              webOnlyWindowName: '_self'); // Redirect in same tab
        } else {
          throw Exception("Could not launch Stripe Checkout.");
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint("Checkout Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        if (e.toString().contains("Seat(s) no longer available")) {
          // Navigate back to seat selection after a brief delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    }
    // Note: If redirect happens, state generally dies here, which is why we saved PendingBooking.
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final trip = controller.selectedTrip!;
    final seats = controller.selectedSeats;

    // Calculate total: Price * Seats * Days
    int days = 1;
    if (controller.isBulkBooking && controller.bulkDates.isNotEmpty) {
      days = controller.bulkDates.length;
    }
    final totalAmount = trip.price * seats.length * days;

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text("Secure Checkout",
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
      body: Column(
        children: [
          if (isDesktop)
            DesktopNavBar(
                selectedIndex: -1, onTap: (i) => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: isDesktop
                        ? const EdgeInsets.symmetric(
                            vertical: 60, horizontal: 24)
                        : const EdgeInsets.all(24),
                    constraints: const BoxConstraints(minHeight: 600),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          children: [
                            if (isDesktop) ...[
                              Text("Secure Checkout",
                                  style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              const SizedBox(height: 40),
                            ],
                            // Layout
                            if (isDesktop) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      flex: 7,
                                      child: _buildOrderSummary(trip, seats,
                                          totalAmount, controller)),
                                  const SizedBox(width: 48),
                                  Expanded(
                                      flex: 5,
                                      child: _buildRedirectAction(
                                          context, totalAmount)),
                                ],
                              ),
                            ] else ...[
                              _buildOrderSummary(
                                  trip, seats, totalAmount, controller),
                              const SizedBox(height: 32),
                              _buildRedirectAction(context, totalAmount),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const AppFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(dynamic trip, List<int> seats, double totalAmount,
      TripController controller) {
    final bool isBulk =
        controller.isBulkBooking && controller.bulkDates.length > 1;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 24, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text("Order Summary",
                  style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          _infoRow("Bus Operator", trip.operatorName),
          const Divider(height: 32),
          _infoRow("From", trip.fromCity),
          _infoRow("To", trip.toCity),
          const Divider(height: 32),
          if (isBulk) ...[
            Text("Multi-Day Booking (${controller.bulkDates.length} Days)",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            // Show simplified range or list
            _infoRow("Start Date",
                "${controller.bulkDates.first.day}/${controller.bulkDates.first.month}/${controller.bulkDates.first.year}"),
            _infoRow("End Date",
                "${controller.bulkDates.last.day}/${controller.bulkDates.last.month}/${controller.bulkDates.last.year}"),
            _infoRow("Total Days", "${controller.bulkDates.length}"),
          ] else ...[
            _infoRow("Date",
                "${trip.departureTime.day}/${trip.departureTime.month}/${trip.departureTime.year}"),
          ],
          _infoRow("Time",
              "${trip.departureTime.hour}:${trip.departureTime.minute.toString().padLeft(2, '0')}"),
          const Divider(height: 32),
          _infoRow("Qty (Seats per trip)", "${seats.length}"),
          _infoRow("Base Price", "LKR ${trip.price.toStringAsFixed(0)}"),
          _infoRow("Selected Seats", seats.join(", ")),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Amount",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text("LKR ${totalAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey.shade500)),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRedirectAction(BuildContext context, double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Finalize Payment",
            style:
                GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          "You will be redirected to the secure Stripe Checkout page to complete your payment.",
          style: GoogleFonts.inter(
              fontSize: 14, color: Colors.grey.shade600, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleCheckoutRedirect,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shadowColor: Colors.black26,
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 18, color: Colors.white),
                      const SizedBox(width: 10),
                      Text("Proceed to Checkout",
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Back",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade700)),
          ),
        ),
        const SizedBox(height: 24),
        _buildSecurityBadges(),
      ],
    );
  }

  Widget _buildSecurityBadges() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 14, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text("SSL Encrypted Transaction",
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _badge("Powered by Stripe"),
            _badge("PCI DSS Compliant"),
            _badge("Cards, Apple Pay, Google Pay"),
          ],
        )
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style:
                GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)));
  }
}
