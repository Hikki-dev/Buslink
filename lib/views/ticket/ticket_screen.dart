import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart'; // Added
import 'dart:io'; // Added
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:google_fonts/google_fonts.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart'; // Added
import '../tracking/track_bus_screen.dart'; // Added
 // Added

// import '../home/home_screen.dart'; // Unused

class TicketScreen extends StatefulWidget {
  final Trip? tripArg;
  final Ticket? ticketArg;
  final List<Ticket>? ticketsArg; // Added for Bulk

  const TicketScreen(
      {super.key, this.tripArg, this.ticketArg, this.ticketsArg});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
     // Added
    // final authService = Provider.of<AuthService>(context, listen: false); // Unused
    // final user = authService.currentUser; // Unused
    final Trip? trip = widget.tripArg ?? controller.selectedTrip?.trip;

    // Determine if single or bulk
    List<Ticket> tickets = [];
    if (widget.ticketsArg != null && widget.ticketsArg!.isNotEmpty) {
      tickets = widget.ticketsArg!;
    } else if (widget.ticketArg != null) {
      tickets = [widget.ticketArg!];
    } else if (controller.currentTicket != null) {
      tickets = [controller.currentTicket!];
    }

    if (trip == null || tickets.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(child: Text("Error loading ticket details.")),
      );
    }

    final isBulk = tickets.length > 1;
    final mainTicket = tickets.first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon:
              Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            isBulk
                ? "${"Bulk Booking"} (${tickets.length})"
                : "Route",
            style: TextStyle(
                fontFamily: 'Outfit',
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => _showFeedbackDialog(context),
            tooltip: "App Feedback",
          ),
          IconButton(
            icon: Icon(Icons.download_rounded,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => _downloadPdf(context, trip, tickets),
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
              Text(
                  isBulk
                      ? "${"Bundle"} (${tickets.length})"
                      : "E-Ticket",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.5))),
              const SizedBox(height: 16),
              if (isBulk)
                SizedBox(
                  height: 600,
                  child: PageView.builder(
                    itemCount: tickets.length,
                    controller: PageController(viewportFraction: 0.9),
                    itemBuilder: (ctx, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SingleChildScrollView(
                          child:
                              _buildTicketCard(context, trip, tickets[index]),
                        ),
                      );
                    },
                  ),
                )
              else
                _buildTicketCard(context, trip, mainTicket),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadPdf(context, trip, tickets),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(isBulk
                      ? "Download Consolidated PDF"
                      : "Download PDF"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
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

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _FeedbackDialog(),
    );
  }

  Widget _buildTicketCard(BuildContext context, Trip trip, Ticket ticket) {
     // Added
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text("Confirmed".toUpperCase(),
                      style: TextStyle(
                          fontFamily: 'Inter',
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
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        Text(
                            
                                trip.fromCity.toLowerCase(), // Translated City
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.directions_bus,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.3),
                            size: 32),
                        if (trip.via.isNotEmpty && trip.via != 'Direct')
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Via ${trip.via}",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("TO",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        Text(
                            
                                trip.toCity.toLowerCase(), // Translated City
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 32),

                // Info Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCol("TRAVEL DATES",
                        DateFormat('MMM d').format(trip.departureTime)),
                    _infoCol("TIME",
                        DateFormat('hh:mm a').format(trip.departureTime)),
                    _infoCol(
                        "SEATS", "${ticket.seatNumbers.length}"),
                  ],
                ),

                const SizedBox(height: 32),
                Container(
                    height: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.1)),
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
                const SizedBox(height: 16),
                Text(
                  "Show QR Code",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                      height: 1.2),
                ),
                const SizedBox(height: 8),
                // Code Removed
                const SizedBox(height: 24),

                // TRACK BUS BUTTON (New Feature)
                if (trip.status != 'completed' &&
                    trip.status != 'cancelled') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TrackBusScreen(trip: trip)));
                      },
                      icon: const Icon(Icons.gps_fixed, color: Colors.blue),
                      label: Text("Track Bus Live",
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Passenger & Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PASSENGER",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        Text(ticket.passengerName,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("TOTAL PRICE",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        Text(
                          "LKR ${ticket.totalAmount.toStringAsFixed(0)}",
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primaryColor),
                        ),
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
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.3))))
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
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val,
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface))
      ],
    );
  }

  Future<void> _downloadPdf(
      BuildContext context, Trip trip, List<Ticket> tickets) async {
    
    final doc = pw.Document();
    final isBulk = tickets.length > 1;
    // Use the first ticket for common details
    final mainTicket = tickets.first;

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
                          pw.Text(isBulk ? "BULK RECEIPT" : "E-TICKET",
                              style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey)),
                        ])),
                pw.SizedBox(height: 20),

                // Trip Details Box
                pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey100),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text("TRIP DETAILS",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10)),
                                pw.SizedBox(height: 5),
                                pw.Text("${trip.fromCity}  ->  ${trip.toCity}",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 14)),
                                pw.Text(
                                    "Date: ${DateFormat('yyyy-MM-dd').format(trip.departureTime)}"),
                                pw.Text(
                                    "Time: ${DateFormat('hh:mm a').format(trip.departureTime)}"),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text("TICKETS: ${tickets.length}",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 12)),
                                pw.Text(
                                    "Total Paid: LKR ${tickets.fold(0.0, (s, t) => s + t.totalAmount).toStringAsFixed(0)}",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.red900)),
                              ])
                        ])),

                pw.SizedBox(height: 20),

                if (isBulk)
                  pw.TableHelper.fromTextArray(
                      headers: [
                        'Ticket ID',
                        'Passenger',
                        'Phone',
                        'Seat(s)',
                        'Code'
                      ],
                      data: tickets
                          .map((t) => [
                                t.ticketId.substring(0, 8).toUpperCase(),
                                t.passengerName,
                                t.passengerPhone,
                                t.seatNumbers.join(','),
                                t.shortId ?? '-'
                              ])
                          .toList(),
                      headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white),
                      headerDecoration:
                          const pw.BoxDecoration(color: PdfColors.red900),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                      cellAlignments: {
                        0: pw.Alignment.centerLeft,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.centerLeft,
                        3: pw.Alignment.center,
                        4: pw.Alignment.center,
                      })
                else
                  // Single Ticket Layout (Preserve Original Look)
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
                                  // Ticket ID Removed
                                  pw.Text(
                                      "Ticket Code: ${mainTicket.shortId ?? 'N/A'}",
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold)),
                                  pw.Text(
                                      "Date: ${DateFormat('yyyy-MM-dd').format(trip.departureTime)}"),
                                ]),
                            pw.Divider(),
                            pw.Text("Passenger: ${mainTicket.passengerName}"),
                            pw.Text(
                                "Seats: ${mainTicket.seatNumbers.join(', ')}"),
                            pw.Divider(),
                            pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                    "Total: LKR ${mainTicket.totalAmount.toStringAsFixed(0)}",
                                    style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.red900)))
                          ])),

                pw.SizedBox(height: 20),
                pw.SizedBox(height: 20),
                pw.Text("SHOW CODE TO CONDUCTOR",
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900)),
                pw.SizedBox(height: 5),
                // For bulk, maybe show first code or just list them
                pw.Text(
                    isBulk ? "See table above" : "CODE: ${mainTicket.shortId}",
                    style: pw.TextStyle(
                        fontSize: 32, fontWeight: pw.FontWeight.bold)),

                if (!isBulk) ...[
                  pw.SizedBox(height: 10),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: mainTicket.ticketId,
                    width: 120,
                    height: 120,
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );

    try {
      final bytes = await doc.save();
      final fileName = 'buslink_ticket_${mainTicket.shortId}.pdf';

      if (kIsWeb) {
        // Web: Us printing's built-in share/download (browser handles it)
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else if (Platform.isAndroid) {
        // Android: Save to Downloads folder directly

        // 1. Permission Check
        if (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted) {
          try {
            // 2. Get Path
            Directory? directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }

            if (directory != null) {
              final file = File('${directory.path}/$fileName');
              await file.writeAsBytes(bytes);

              // Success Feedback
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text("${"Saved to Downloads"}: $fileName"),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: "OPEN",
                    textColor: Colors.white,
                    onPressed: () {
                      OpenFilex.open(file.path);
                    },
                  ),
                ));

                // Notification
                NotificationService.showLocalNotification(
                    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    title: "Ticket Downloaded",
                    body:
                        "Your ticket ($fileName) has been saved to Downloads.");
              }
            } else {
              await Printing.sharePdf(bytes: bytes, filename: fileName);
            }
          } catch (e) {
            debugPrint("Download Error: $e. Fallback to Share.");
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          }
        } else {
          // Permission denied
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Permission Denied"),
                backgroundColor: Colors.red));
          }
        }
      } else {
        // iOS: Share is the standard way (Save to Files)
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      debugPrint("PDF Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving PDF")));
      }
    }
  }
}

class _FeedbackDialog extends StatefulWidget {
  @override
  __FeedbackDialogState createState() => __FeedbackDialogState();
}

class __FeedbackDialogState extends State<_FeedbackDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Give Feedback",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text("Rate your experience",
                  style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors
                          .grey)), // Revert to generic grey or access theme if possible. accessing theme in Dialog might require removing const.

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text("Tell us more (Max 200 chars)",
                  style: TextStyle(fontFamily: 'Inter', color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                    hintText: "Review...",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Please provide a rating")));
                      return;
                    }

                    final user =
                        Provider.of<AuthService>(context, listen: false)
                            .currentUser;
                    if (user != null) {
                      Provider.of<TripController>(context, listen: false)
                          .submitFeedback(_rating,
                              _commentController.text.trim(), user.uid);
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Thank you for your feedback.")));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white),
                  child: const Text("Submit Feedback"),
                ),
              )
            ],
          ),
        ));
  }
}
