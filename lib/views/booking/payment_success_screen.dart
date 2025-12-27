import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/trip_controller.dart';
import '../../views/home/home_screen.dart';
import '../../models/trip_model.dart';

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

    // Strategy A: Check standard URL query parameters (Works for PathUrlStrategy)
    if (kIsWeb) {
      bookingId = Uri.base.queryParameters['booking_id'];
    }

    // Strategy B: Check Flutter Route Name (Works for HashUrlStrategy & Deep Links)
    // The route name often contains the path + query, e.g. "/payment_success?booking_id=123"
    // This is checking if the previous check failed OR we want to be robust
    if (bookingId == null) {
      final routeName = ModalRoute.of(context)?.settings.name;
      if (routeName != null) {
        // Parse as a URI. We prepend a dummy scheme/host to ensure parsing works if it's just a path
        final uri = Uri.parse("https://dummy.com$routeName");
        bookingId = uri.queryParameters['booking_id'];
      }
    }

    // Strategy C: Direct Fragment Parsing (Web Hash Routing Fallback)
    // If route settings failed (e.g. onGenerateRoute didn't pass them), try raw URL fragment
    if (bookingId == null && kIsWeb && Uri.base.hasFragment) {
      // Fragment usually looks like "/payment_success?booking_id=..."
      final fragment = Uri.base.fragment;
      // Handle cases where fragment might not start with /
      final safeFragment = fragment.startsWith('/') ? fragment : '/$fragment';
      final uri = Uri.parse("https://dummy.com$safeFragment");
      bookingId = uri.queryParameters['booking_id'];
    }

    // Strategy D: Brute Force Regex (Failsafe)
    // If all else fails, look for booking_id=... pattern in the full URL string
    if (bookingId == null && kIsWeb) {
      final fullUrl = Uri.base.toString();
      final regExp = RegExp(r'booking_id=([^&]*)');
      final match = regExp.firstMatch(fullUrl);
      if (match != null) {
        bookingId = match.group(1);
      }
    }

    // Fallback: Check arguments if passed directly (e.g. internal navigation)
    if (bookingId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        bookingId = args['booking_id'];
      }
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

  Future<void> _downloadPdf(
      BuildContext context, Trip trip, Ticket ticket) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              children: [
                pw.Header(
                    level: 0,
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("BusLink",
                              style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red900)),
                          pw.Text("E-TICKET",
                              style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey)),
                        ])),
                pw.SizedBox(height: 20),
                pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300)),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                    "Ticket ID: ${ticket.ticketId.toUpperCase().substring(0, 8)}",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(
                                    "Date: ${DateFormat('yyyy-MM-dd').format(trip.departureTime)}"),
                              ]),
                          pw.Divider(),
                          pw.Text(
                              "FROM: ${trip.fromCity}  ->  TO: ${trip.toCity}",
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 10),
                          pw.Text("Bus: ${trip.busNumber}"),
                          pw.Text(
                              "Departure: ${DateFormat('hh:mm a').format(trip.departureTime)}"),
                          pw.Text("Platform: ${trip.platformNumber}"),
                          pw.SizedBox(height: 10),
                          pw.Text("Passenger: ${ticket.passengerName}"),
                          pw.Text("Seats: ${ticket.seatNumbers.join(', ')}"),
                          pw.Text("Quantity: ${ticket.seatNumbers.length}"),
                          pw.Divider(),
                          pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                  "Total Paid: LKR ${ticket.totalAmount.toStringAsFixed(0)}",
                                  style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.red900)))
                        ])),
                pw.SizedBox(height: 20),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: ticket.ticketId,
                  width: 150,
                  height: 150,
                ),
                pw.SizedBox(height: 20),
                pw.Text("Please show this QR code to the conductor.",
                    style: const pw.TextStyle(color: PdfColors.grey)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'ticket_${ticket.ticketId}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    // Need access to controller for trip/ticket details
    final controller = Provider.of<TripController>(context);
    final ticket = controller.currentTicket;

    // Attempt to recover Trip from Ticket if State was lost (Refresh/Redirect)
    Trip? trip = controller.selectedTrip;

    // If provider trip is missing but we have a ticket with data, reconstruct it
    if (trip == null && ticket != null && ticket.tripData.isNotEmpty) {
      try {
        final tData = ticket.tripData;
        trip = Trip(
          id: ticket.tripId,
          operatorName: tData['operatorName'] ?? 'Operator',
          busNumber: tData['busNumber'] ?? '',
          fromCity: tData['fromCity'] ?? '',
          toCity: tData['toCity'] ?? '',
          // Timestamp handling
          departureTime: tData['departureTime'] is Timestamp
              ? (tData['departureTime'] as Timestamp).toDate()
              : DateTime.now(),
          arrivalTime: tData['arrivalTime'] is Timestamp
              ? (tData['arrivalTime'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(hours: 4)),
          // Handle price safely (can be int or double)
          price: (tData['price'] != null)
              ? (tData['price'] as num).toDouble()
              : 0.0,
          totalSeats: 0,
          platformNumber: tData['platformNumber'] ?? '',
          bookedSeats: [],
          stops: [],
        );
      } catch (e) {
        debugPrint("Error reconstructing trip from ticket: $e");
      }
    }

    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 500),
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
              ] else if (_isSuccess && trip != null && ticket != null) ...[
                // --- SUCCESS VIEW WITH QR & PDF ---
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
                  "Your seat has been reserved.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // QR Code
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        QrImageView(
                          data: ticket.ticketId,
                          version: QrVersions.auto,
                          size: 150,
                        ),
                        const SizedBox(height: 8),
                        Text(
                            "Ticket ID: ${ticket.ticketId.substring(0, 8).toUpperCase()}",
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey))
                      ],
                    )),
                const SizedBox(height: 24),

                Text(
                  "HERE IS YOUR BOOKING QR\nSHOW THIS TO CONDUCTOR",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1.2),
                ),
                const SizedBox(height: 24),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadPdf(context, trip!, ticket!),
                    icon:
                        const Icon(Icons.download_rounded, color: Colors.white),
                    label: Text("Download PDF Ticket",
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Home Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false);
                    },
                    child: Text("Back to Home",
                        style: GoogleFonts.outfit(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold)),
                  ),
                )
              ] else ...[
                // --- FAILURE VIEW ---
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
                const SizedBox(height: 16),
                // --- DEBUG INFO ---
                if (kIsWeb)
                  SelectableText(
                    "DEBUG INFO:\nURL: ${Uri.base}\nFragment: ${Uri.base.fragment}\nRoute: ${ModalRoute.of(context)?.settings.name}\nArgs: ${ModalRoute.of(context)?.settings.arguments}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceCodePro(
                        fontSize: 10, color: Colors.grey.shade400),
                  ),
                // ------------------
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
