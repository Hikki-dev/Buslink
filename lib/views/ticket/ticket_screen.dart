import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';

class TicketScreen extends StatelessWidget {
  final Trip? tripArg;
  final Ticket? ticketArg;

  const TicketScreen({super.key, this.tripArg, this.ticketArg});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final trip = tripArg ?? controller.selectedTrip;
    final ticket = ticketArg ?? controller.currentTicket;

    if (trip == null || ticket == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(child: Text("Error loading ticket details.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (r) => false,
          ),
        ),
        title: Text(
            "Course", // "Course" or "Trip" - kept distinct as requested, maybe "Your Ticket" is better
            style: GoogleFonts.outfit(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.black),
            onPressed: () => _downloadPdf(context, trip, ticket),
            tooltip: "Download PDF",
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("E-TICKET",
                  style: GoogleFonts.outfit(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400)),
              const SizedBox(height: 16),
              _buildTicketCard(context, trip, ticket),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadPdf(context, trip, ticket),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Download PDF"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Trip trip, Ticket ticket) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Boarding Pass",
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text("CONFIRMED",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Route
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("FROM",
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.grey)),
                        Text(trip.fromCity,
                            style: GoogleFonts.outfit(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Icon(Icons.directions_bus,
                        color: Colors.grey.shade300, size: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("TO",
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.grey)),
                        Text(trip.toCity,
                            style: GoogleFonts.outfit(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 32),

                // Info Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCol(
                        "Date", DateFormat('MMM d').format(trip.departureTime)),
                    _infoCol("Time",
                        DateFormat('hh:mm a').format(trip.departureTime)),
                    _infoCol("Bus", trip.busNumber),
                    _infoCol("Seats", "${ticket.seatNumbers.length}"),
                  ],
                ),

                const SizedBox(height: 32),
                Container(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 32),

                // QR
                QrImageView(
                  data: ticket.ticketId,
                  version: QrVersions.auto,
                  size: 140,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText("ID: ${ticket.ticketId}",
                    style: GoogleFonts.inter(
                        letterSpacing: 1, fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 32),
                Text(
                  "HERE IS YOUR BOOKING QR\nSHOW THIS TO CONDUCTOR",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1.2),
                ),

                // Passenger & Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Passenger",
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.grey)),
                        Text(ticket.passengerName,
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Total Price",
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.grey)),
                        Text("LKR ${ticket.totalAmount.toStringAsFixed(0)}",
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.1))),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),

          // Cutout Effect
          SizedBox(
            height: 20,
            child: Stack(
              children: [
                Positioned(
                    bottom: -10,
                    left: -10,
                    child: CircleAvatar(
                        radius: 10, backgroundColor: Colors.grey.shade100)),
                Positioned(
                    bottom: -10,
                    right: -10,
                    child: CircleAvatar(
                        radius: 10, backgroundColor: Colors.grey.shade100)),
                // Dashed line
                Center(
                    child: Text("- - - - - - - - - - - - - - - - - - - -",
                        style: TextStyle(color: Colors.grey.shade300)))
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14))
      ],
    );
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
                          pw.Text("Bus: ${trip.busNumber} (${trip.busType})"),
                          pw.Text(
                              "Departure: ${DateFormat('hh:mm a').format(trip.departureTime)}"),
                          pw.Text("Platform: ${trip.platformNumber}"),
                          pw.SizedBox(height: 10),
                          pw.Text("Passenger: ${ticket.passengerName}"),
                          pw.Text("Seats: ${ticket.seatNumbers.join(', ')}"),
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

    // Share/Print the PDF
    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'ticket_${ticket.ticketId}.pdf');
  }
}
