import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart'; // Import Stripe widgets

import '../../controllers/trip_controller.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import '../ticket/ticket_screen.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  CardFieldInputDetails? _cardDetails;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final user = Provider.of<User?>(context);
    final trip = controller.selectedTrip!;
    final seats = controller.selectedSeats;
    final totalAmount = trip.price * seats.length;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: isDesktop
          ? null // No AppBar on desktop if using NavBar
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
              padding: EdgeInsets
                  .zero, // Padding handled inside for full width background
              child: Column(
                children: [
                  // Main Content Area
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
                            // Page Title (Moved here for better spacing)
                            if (isDesktop) ...[
                              Text("Secure Checkout",
                                  style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              const SizedBox(height: 40),
                            ],

                            if (isDesktop) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      flex: 7, // Slightly wider summary
                                      child: _buildOrderSummary(
                                          trip, seats, totalAmount)),
                                  const SizedBox(width: 48), // More spacing
                                  Expanded(
                                      flex: 5,
                                      child: _buildPaymentSection(context,
                                          controller, user, totalAmount)),
                                ],
                              ),
                            ] else ...[
                              _buildOrderSummary(trip, seats, totalAmount),
                              const SizedBox(height: 32),
                              _buildPaymentSection(
                                  context, controller, user, totalAmount),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer appended at the end of scroll view
                  const AppFooter(),
                ],
              ),
            ),
          ),
          // Footer was here, but moving it inside ScrollView allows it to be pushed down
          // actually, keeping it outside or inside depends on sticky vs scroll behavior.
          // User wants it "nicer", usually means normal scroll flow.
        ],
      ),
    );
  }

  Widget _buildOrderSummary(dynamic trip, List<int> seats, double totalAmount) {
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
          _infoRow("Date",
              "${trip.departureTime.day}/${trip.departureTime.month}/${trip.departureTime.year}"),
          _infoRow("Time",
              "${trip.departureTime.hour}:${trip.departureTime.minute.toString().padLeft(2, '0')}"),
          const Divider(height: 32),
          _infoRow("Qty", "${seats.length}"),
          _infoRow("Price per seat", "LKR ${trip.price.toStringAsFixed(0)}"),
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

  Widget _buildPaymentSection(BuildContext context, TripController controller,
      User? user, double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Payment Details",
            style: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.bold)), // Larger font
        const SizedBox(height: 24),

        // WEB: Show CardField explicitly
        if (kIsWeb)
          Container(
            padding: const EdgeInsets.all(24), // More padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Card Information",
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        _cardIcon(Icons.credit_card, Colors.blue),
                        const SizedBox(width: 8),
                        _cardIcon(Icons.credit_card, Colors.orange),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Card Field with explicit constraint
                Container(
                  height: 50, // Explicit height for Web
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50),
                  alignment: Alignment.center,
                  child: CardField(
                    onCardChanged: (card) {
                      setState(() {
                        _cardDetails = card;
                      });
                    },
                    style: TextStyle(
                        fontFamily: GoogleFonts.inter().fontFamily,
                        fontSize: 16,
                        color: Colors.black),
                    decoration: InputDecoration(
                        border: InputBorder
                            .none, // Remove default border as we have container
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        hintText: "Card Number",
                        hintStyle: TextStyle(color: Colors.grey.shade400)),
                  ),
                ),
              ],
            ),
          )
        else
          // MOBILE: Visual Indicator
          Container(
            // ... existing mobile code ...
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: AppTheme.primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Credit / Debit Card",
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      Text("Standard Stripe Checkout",
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle,
                    color: AppTheme.primaryColor, size: 20)
              ],
            ),
          ),

        // ... rest of the section

        const SizedBox(height: 32),

        // Terms & Conditions Section
        _buildTermsAndConditions(),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _handlePayment(
                    context, controller, user, totalAmount.toString()),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Sleek black for premium feel
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
                : Text("Pay LKR ${totalAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
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

  Widget _cardIcon(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 20,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Center(child: Icon(icon, size: 14, color: color)),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Terms & Conditions",
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
              "By clicking 'Pay', you agree to BusLink's cancellation policy. Tickets can be cancelled up to 24 hours before departure for a 90% refund. No refunds for same-day cancellations.",
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.grey.shade600, height: 1.5)),
          const SizedBox(height: 8),
          Text(
            "View full Terms of Service",
            style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline),
          )
        ],
      ),
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
            _badge("3D Secure"),
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

  Future<void> _handlePayment(BuildContext context, TripController controller,
      User? user, String amount) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to continue")));
      return;
    }

    // WEB Check: Ensure card details entered
    if (kIsWeb && (_cardDetails == null || _cardDetails?.complete == false)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter complete card details.")));
      return;
    }

    setState(() => _isProcessing = true);

    final paymentService = PaymentService();
    bool success = false;

    if (kIsWeb) {
      success = await paymentService.processPaymentWeb(context,
          amount: amount, currency: 'lkr');
    } else {
      success = await paymentService.processPaymentMobile(context,
          amount: amount, currency: 'lkr');
    }

    if (success) {
      if (!context.mounted) return;

      // Create Booking Record in Firestore
      final bookingSuccess = await controller.processBooking(context, user);

      if (bookingSuccess && context.mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TicketScreen()),
            (route) => false);
      } else {
        setState(() => _isProcessing = false);
      }
    } else {
      if (context.mounted) {
        setState(() => _isProcessing = false);
        // Error snackbar is handled in service
      }
    }
  }
}
