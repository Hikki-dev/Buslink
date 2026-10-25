// Making and saving a ticket as a PDF. This file is loaded only when someone
// presses Download PDF (`deferred as`), because the PDF library is large and
// most visits never use it.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

import '../../models/trip_model.dart';
import '../../services/notification_service.dart';
import '../../utils/file_downloader.dart';
import '../../utils/platform_text.dart';
import '../../utils/text_utils.dart';

Future<void> downloadTicketPdf(
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
                              firstChars(t.ticketId, 8).toUpperCase(),
                              t.passengerName,
                              t.passengerPhone,
                              t.seatNumbers.join(','),
                              t.shortId ?? '-'
                            ])
                        .toList(),
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.white),
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
                  body: "Your ticket ($fileName) has been saved to Downloads.");
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
              content: Text("Permission Denied"), backgroundColor: Colors.red));
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

Future<void> downloadBookingPdf(
    BuildContext context, List<Ticket> tickets) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text(
            "Generating ${tickets.length > 1 ? 'Booking PDF' : 'Ticket PDF'}...")),
  );

  try {
    final doc = pw.Document();

    // 1. Add Summary Page if multiple tickets
    if (tickets.length > 1) {
      doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            double totalAmount = tickets.fold(
                0, (currentSum, item) => currentSum + item.totalAmount);

            return pw.Center(
                child: pw.Column(children: [
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
                        pw.Text("BOOKING SUMMARY",
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
                              pw.Text("Total Tickets: ${tickets.length}",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 18)),
                              pw.Text(
                                  "Total Paid: LKR ${totalAmount.toStringAsFixed(0)}",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 18,
                                      color: PdfColors.green900)),
                            ]),
                        pw.Divider(),
                        pw.SizedBox(height: 10),
                        // List of Tickets
                        ...tickets.map((t) {
                          final tData = t.tripData;
                          final tripDateVal = tData['departureDateTime'] ??
                              tData['departureTime'];
                          final tripDate = tripDateVal is Timestamp
                              ? tripDateVal.toDate()
                              : DateTime.tryParse(tripDateVal.toString()) ??
                                  DateTime.now();
                          return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Row(children: [
                                pw.Expanded(
                                    flex: 2,
                                    child: pw.Text(DateFormat('yyyy-MM-dd')
                                        .format(tripDate))),
                                pw.Expanded(
                                    flex: 3,
                                    child: pw.Text(
                                        "${tData['originCity'] ?? tData['fromCity']} -> ${tData['destinationCity'] ?? tData['toCity']}")),
                                pw.Expanded(
                                    flex: 2,
                                    child: pw.Text(
                                        "Seat: ${t.seatNumbers.join(',')}")),
                                pw.Text(
                                    "LKR ${t.totalAmount.toStringAsFixed(0)}")
                              ]));
                        }),
                      ])),
              pw.SizedBox(height: 20),
              pw.Text("Individual tickets are attached in the following pages.",
                  style: const pw.TextStyle(color: PdfColors.grey)),
            ]));
          }));
    }

    // 2. Add Individual Ticket Pages
    for (final ticket in tickets) {
      // Construct Trip from Ticket Data (Snapshot)
      final tData = ticket.tripData;
      final tripDateVal = tData['departureDateTime'] ?? tData['departureTime'];
      final tripDate = tripDateVal is Timestamp
          ? tripDateVal.toDate()
          : DateTime.tryParse(tripDateVal.toString()) ?? DateTime.now();

      final fromCity = tData['fromCity'] ?? tData['originCity'] ?? '';
      final toCity = tData['toCity'] ?? tData['destinationCity'] ?? '';
      final busNum = tData['busNumber'] ?? '';
      final platform = platformOf(tData);

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
                                      "Ticket Code: ${ticket.shortId ?? firstChars(ticket.ticketId, 8).toUpperCase()}",
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 18)),
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
                            if (platform.isNotEmpty)
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
                    data: ticket.shortId ?? ticket.ticketId,
                    width: 150,
                    height: 150,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                      "SHOW the 4 DIGIT CODE TO CONDUCTOR or TELL CONDUCTOR TO SCAN QR",
                      style: const pw.TextStyle(color: PdfColors.grey)),
                  if (tickets.length > 1) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                        "Ticket ${tickets.indexOf(ticket) + 1} of ${tickets.length}",
                        style: const pw.TextStyle(color: PdfColors.grey500)),
                  ]
                ],
              ),
            );
          },
        ),
      );
    }

    final bytes = await doc.save();
    final fileName = 'buslink_tickets.pdf';

    if (kIsWeb) {
      await downloadBytesForWeb(bytes, fileName);
    } else if (Platform.isAndroid) {
      // Android-specific download logic
      if (await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        try {
          final directory = Directory('/storage/emulated/0/Download');
          Directory? targetDir = directory;
          if (!await directory.exists()) {
            targetDir = await getExternalStorageDirectory();
          }

          if (targetDir != null) {
            final file = File('${targetDir.path}/$fileName');
            await file.writeAsBytes(bytes);

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

              NotificationService.showLocalNotification(
                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: "Tickets Downloaded",
                  body: "Your tickets have been saved to Downloads.");
            }
          } else {
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          }
        } catch (e) {
          debugPrint("Download Error: $e. Fallback to Share.");
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Permission Denied"), backgroundColor: Colors.red));
        }
      }
    } else {
      // iOS and others
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  } catch (e, stackTrace) {
    debugPrint("Error generating/sharing PDF: $e");
    debugPrint(stackTrace.toString());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${"Error saving PDF"}: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
