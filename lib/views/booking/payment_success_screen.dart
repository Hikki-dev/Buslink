import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../controllers/trip_controller.dart';
import '../../views/home/home_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _message = "Verifying Payment...";

  @override
  void initState() {
    super.initState();
    _verifyBooking();
  }

  Future<void> _verifyBooking() async {
    // 1. Extract params from URL
    String? bookingId;
    if (kIsWeb) {
      final uri = Uri.base; // Current Browser URL
      bookingId = uri.queryParameters['booking_id'];
      // final sessionId = uri.queryParameters['session_id']; // Can use for Stripe API verification if backend existed
    }

    if (bookingId == null) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = "Invalid booking reference found.";
      });
      return;
    }

    // 2. Confirm Booking via Controller
    final controller = Provider.of<TripController>(context, listen: false);
    final success = await controller.confirmBooking(bookingId);

    if (success && mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _message = "Payment Confirmed!";
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _message = "Could not confirm booking. Please contact support.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(color: Colors.black),
                const SizedBox(height: 24),
                Text(_message,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
              ] else if (_isSuccess) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.green, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  "Booking Confirmed!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your seat has been reserved. You can now view your ticket.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to standard Ticket or Home
                      // Since we are redirected, stack is fresh.
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Back to Home",
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      color: Colors.red, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  "Verification Failed",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Go Home",
                        style: GoogleFonts.outfit(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold)),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
