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
import '../../utils/bl_colors.dart';
import '../home/home_sections.dart' show cityPhoto;
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
  int _index = 0;
  int _favTick = 0;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final Trip? trip = widget.tripArg ?? controller.selectedTrip?.trip;

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
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: BL.ink)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
                'We could not open this ticket. Go back to My Trips and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18)),
          ),
        ),
      );
    }

    final isBulk = tickets.length > 1;
    final ticket = tickets[_index.clamp(0, tickets.length - 1)];
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final live = trip.status != 'completed' && trip.status != 'cancelled';
    final code = ticket.shortId ?? ticket.ticketId.substring(0, 4);

    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l, style: const TextStyle(fontSize: 16, color: BL.muted)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(v,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    final seats = (ticket.seatNumbers.toList()..sort()).join(', ');
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          SizedBox(
            height: 98,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: Image.asset(cityPhoto(trip.toCity),
                      fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 46,
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: BL.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              children: [
                Text(
                    isBulk
                        ? 'Ticket ${_index + 1} of ${tickets.length}'
                        : 'Your ticket',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                const Text(
                    'Show the 4-digit code or let the conductor scan the QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: BL.muted)),
                const SizedBox(height: 10),
                Semantics(
                  label: 'QR code for your ticket',
                  image: true,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: BL.hairline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: ticket.ticketId,
                      version: QrVersions.auto,
                      size: isDesktop ? 180 : 130,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFDEEEE),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('4-DIGIT CODE',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: BL.crimsonDark)),
                      const SizedBox(width: 12),
                      Semantics(
                        label: 'Verified code $code',
                        excludeSemantics: true,
                        child: Text(code,
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 5,
                                color: BL.crimson)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28, color: BL.hairline),
                row('Trip', '${trip.fromCity} to ${trip.toCity}'),
                if (trip.via.isNotEmpty && trip.via != 'Direct')
                  row('Via', trip.via),
                row(
                    'Leaves',
                    DateFormat('EEE d MMM, hh:mm a')
                        .format(trip.departureTime)),
                row('Seats', seats),
                row('Passenger', ticket.passengerName),
                row('Total paid',
                    'LKR ${NumberFormat('#,###').format(ticket.totalAmount)}'),
              ],
            ),
          ),
        ],
      ),
    );

    Widget pill(String label, IconData icon, VoidCallback onTap,
            {bool outlined = false}) =>
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 22),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: outlined ? Colors.transparent : Colors.white,
              foregroundColor: outlined ? Colors.white : BL.crimson,
              shape: StadiumBorder(
                  side: outlined
                      ? const BorderSide(color: Colors.white, width: 2)
                      : BorderSide.none),
              textStyle:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: BL.crimson,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    color: Colors.white,
                    iconSize: 28,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  FutureBuilder<bool>(
                    key: ValueKey('fav$_favTick'),
                    future:
                        controller.isRouteFavorite(trip.fromCity, trip.toCity),
                    builder: (context, snap) => IconButton(
                      tooltip: (snap.data ?? false)
                          ? 'Remove route from Favourites'
                          : 'Save route in Favourites',
                      color: Colors.white,
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: Icon((snap.data ?? false)
                          ? Icons.favorite
                          : Icons.favorite_border),
                      onPressed: () async {
                        await controller.toggleRouteFavorite(
                            trip.fromCity, trip.toCity);
                        if (mounted) setState(() => _favTick++);
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tell us what you think of the app',
                    color: Colors.white,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => _showFeedbackDialog(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isBulk)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Previous ticket',
                                color: Colors.white,
                                icon: const Icon(Icons.arrow_back_ios_rounded),
                                onPressed: _index > 0
                                    ? () => setState(() => _index--)
                                    : null,
                              ),
                              Text('${_index + 1} / ${tickets.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700)),
                              IconButton(
                                tooltip: 'Next ticket',
                                color: Colors.white,
                                icon:
                                    const Icon(Icons.arrow_forward_ios_rounded),
                                onPressed: _index < tickets.length - 1
                                    ? () => setState(() => _index++)
                                    : null,
                              ),
                            ],
                          ),
                        card,
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                              child: pill(
                                  isBulk ? 'Download all' : 'Download PDF',
                                  Icons.download,
                                  () => _downloadPdf(context, trip, tickets))),
                          if (live) ...[
                            const SizedBox(width: 10),
                            Expanded(
                                child: pill('Track bus', Icons.gps_fixed, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          TrackBusScreen(trip: trip)));
                            }, outlined: true)),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                                        fontSize: 12)),
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
                      cellStyle: const pw.TextStyle(fontSize: 12),
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
                  content: Text("${"Saved to Downloads"}: $fileName"),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error saving PDF")));
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
                    tooltip: 'Rate',
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
