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
  List<Ticket> _verifiedTickets = [];

  @override
  void initState() {
    super.initState();
    _verifyBooking();
  }

  Future<void> _verifyBooking() async {
    String? bookingIdParam;

    // Strategy A: Check standard URL query parameters
    if (kIsWeb) {
      bookingIdParam = Uri.base.queryParameters['booking_id'];
    }

    // Strategy B: Check Flutter Route Name
    if (bookingIdParam == null) {
      final routeName = ModalRoute.of(context)?.settings.name;
      if (routeName != null) {
        final uri = Uri.parse("https://dummy.com$routeName");
        bookingIdParam = uri.queryParameters['booking_id'];
      }
    }

    // Strategy C: Fragment Parsing
    if (bookingIdParam == null && kIsWeb && Uri.base.hasFragment) {
      final fragment = Uri.base.fragment;
      final safeFragment = fragment.startsWith('/') ? fragment : '/$fragment';
      final uri = Uri.parse("https://dummy.com$safeFragment");
      bookingIdParam = uri.queryParameters['booking_id'];
    }

    // Strategy D: Fallback Args
    if (bookingIdParam == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        bookingIdParam = args['booking_id'];
      }
    }

    if (bookingIdParam == null) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = "Invalid booking reference found.";
      });
      return;
    }

    // Handle comma-separated IDs for Bulk Booking
    final List<String> bookingIds = bookingIdParam.split(',');

    final controller = Provider.of<TripController>(context, listen: false);
    bool allSuccess = true;
    List<Ticket> tickets = [];

    try {
      for (final id in bookingIds) {
        if (id.trim().isEmpty) continue;
        final success = await controller.confirmBooking(id.trim());
        if (!success) {
          allSuccess = false;
          break;
        }
        // Fetch the verified ticket details
        // Note: confirmBooking updates currentTicket, but we need to collect them
        final ticket = await controller.verifyTicket(id.trim());
        if (ticket != null) {
          tickets.add(ticket);
        }
      }
    } catch (e) {
      allSuccess = false;
      debugPrint("Error verifying bookings: $e");
    }

    if (allSuccess && tickets.isNotEmpty && mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _verifiedTickets = tickets;
        _message = "Payment Confirmed!";
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _message = "Could not verify all bookings. Please contact support.";
        });
      }
    }
  }

  Future<void> _downloadPdf(Ticket ticket) async {
    final doc = pw.Document();

    // Construct Trip from Ticket Data (Snapshot)
    final tData = ticket.tripData;
    final tripDate = tData['departureTime'] is Timestamp
        ? (tData['departureTime'] as Timestamp).toDate()
        : DateTime.parse(tData['departureTime'].toString());

    final fromCity = tData['fromCity'] ?? '';
    final toCity = tData['toCity'] ?? '';
    final busNum = tData['busNumber'] ?? '';
    final platform = tData['platformNumber'] ?? 'TBD';

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
                                    "Date: ${DateFormat('yyyy-MM-dd').format(tripDate)}"),
                              ]),
                          pw.Divider(),
                          pw.Text("FROM: $fromCity  ->  TO: $toCity",
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 10),
                          pw.Text("Bus: $busNum"),
                          pw.Text(
                              "Departure: ${DateFormat('hh:mm a').format(tripDate)}"),
                          pw.Text("Platform: $platform"),
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
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600), // Slightly wider
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 800),
            child: SingleChildScrollView(
              // Allow scrolling for multiple tickets
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading) ...[
                    const CircularProgressIndicator(color: Colors.black),
                    const SizedBox(height: 24),
                    Text(_message,
                        style: GoogleFonts.inter(
                            fontSize: 16, color: Colors.grey)),
                  ] else if (_isSuccess && _verifiedTickets.isNotEmpty) ...[
                    // --- SUCCESS VIEW ---
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
                      "HERE IS YOUR BOOKING QR\nSHOW THIS TO CONDUCTOR",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.2),
                    ),
                    const SizedBox(height: 24),

                    // List of Tickets
                    ..._verifiedTickets
                        .map((ticket) => _buildTicketCard(ticket)),

                    const SizedBox(height: 24),

                    // Home Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
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
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
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
        ),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    // Extract date for display
    final tData = ticket.tripData;
    final dateStr = tData['departureTime'] is Timestamp
        ? DateFormat('MMM d, yyyy')
            .format((tData['departureTime'] as Timestamp).toDate())
        : "Date unavailable";

    return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(dateStr,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text("${tData['fromCity']} ➔ ${tData['toCity']}",
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            QrImageView(
              data: ticket.ticketId,
              version: QrVersions.auto,
              size: 150,
            ),
            const SizedBox(height: 8),
            Text("Ticket ID: ${ticket.ticketId.substring(0, 8).toUpperCase()}",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _downloadPdf(ticket),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text("Download PDF"),
              ),
            ),
          ],
        ));
  }
}
