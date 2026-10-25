import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/bl_colors.dart';
import '../../utils/platform_text.dart';
import '../home/home_sections.dart' show cityPhoto;
import '../support/support_screen.dart';
import 'payment_screen.dart' show PaymentStateCard;
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart'; // Corrected import for Ticket
import '../../services/sms_service.dart'; // Added Import
import '../../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/rendering.dart'; // For capturing widget?
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import '../../utils/file_downloader.dart';
import 'dart:io'; // Added
import 'package:open_filex/open_filex.dart'; // Added
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// Added

// import '../../views/home/home_screen.dart'; // Unused
import '../customer_main_screen.dart';
import '../../utils/text_utils.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  List<Ticket> _verifiedTickets = [];

  int _currentIndex = 0;

  bool _isInit = true;
  int _favTick = 0;

  @override
  void initState() {
    super.initState();
    // _verifyBooking() moved to didChangeDependencies to safely access ModalRoute
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Schedule verification for after the build phase to avoid "setState during build" errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyBooking();
      });
      _isInit = false;
    }
  }

  Future<void> _verifyBooking() async {
    String? bookingIdParam;
    String? paymentIntentId; // Added

    // Strategy A: Check standard URL query parameters
    if (kIsWeb) {
      bookingIdParam = Uri.base.queryParameters['booking_id'];
      paymentIntentId = Uri.base.queryParameters['payment_intent']; // Added
    }

    // Strategy B: Check Flutter Route Name
    if (bookingIdParam == null) {
      final routeName = ModalRoute.of(context)?.settings.name;
      if (routeName != null) {
        // Use a placeholder domain to parse the path/query safely
        final uri = Uri.parse("https://buslink.app$routeName");
        bookingIdParam = uri.queryParameters['booking_id'];
        paymentIntentId = uri.queryParameters['payment_intent']; // Added
      }
    }

    // Strategy C: Fragment Parsing
    if (bookingIdParam == null && kIsWeb && Uri.base.hasFragment) {
      final fragment = Uri.base.fragment;
      final safeFragment = fragment.startsWith('/') ? fragment : '/$fragment';
      final uri = Uri.parse("https://buslink.app$safeFragment");
      bookingIdParam = uri.queryParameters['booking_id'];
      paymentIntentId = uri.queryParameters['payment_intent']; // Added
    }

    // Strategy D: Fallback Args
    if (bookingIdParam == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        bookingIdParam = args['booking_id'];
        // Maybe passed in args if manual nav, but query param is standard for Stripe
        paymentIntentId = args['payment_intent'];
      }
    }

    if (bookingIdParam == null) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
      });
      return;
    }

    // Handle comma-separated IDs for Bulk Booking
    final List<String> bookingIds = bookingIdParam.split(',');

    final controller = Provider.of<TripController>(context, listen: false);
    bool allSuccess = true;
    List<Ticket> tickets = [];

    try {
      // 1. Confirm and Verify all bookings
      for (final id in bookingIds) {
        if (id.trim().isEmpty) continue;
        final success = await controller.confirmBooking(id.trim(),
            paymentIntentId: paymentIntentId);
        if (!success) {
          allSuccess = false;
          break;
        }
        final ticket = await controller.verifyTicket(id.trim());
        if (ticket != null) {
          tickets.add(ticket);
        }
      }

      // 2. Parallel Repair of Ticket Data (if needed)
      if (allSuccess && tickets.isNotEmpty) {
        // Identify tickets needing repair
        final ticketsToRepair = tickets.where((t) =>
            (t.tripData['originCity'] ?? t.tripData['fromCity']) == null ||
            (t.tripData['destinationCity'] ?? t.tripData['toCity']) == null);

        if (ticketsToRepair.isNotEmpty) {
          debugPrint(
              "Repairing ${ticketsToRepair.length} tickets in parallel...");
          await Future.wait(ticketsToRepair.map((ticket) async {
            try {
              final tripDoc = await FirebaseFirestore.instance
                  .collection('trips')
                  .doc(ticket.tripId)
                  .get();

              if (tripDoc.exists) {
                final tMap = tripDoc.data()!;
                ticket.tripData['originCity'] =
                    tMap['originCity'] ?? tMap['fromCity'];
                ticket.tripData['destinationCity'] =
                    tMap['destinationCity'] ?? tMap['toCity'];
                ticket.tripData['busNumber'] = tMap['busNumber'];
                ticket.tripData['platformNumber'] = tMap['platformNumber'];
                ticket.tripData['departureTime'] =
                    tMap['departureTime'] ?? tMap['departureDateTime'];
                ticket.tripData['departureDateTime'] =
                    tMap['departureDateTime'];
                ticket.tripData['operatorName'] = tMap['operatorName'];
              }
            } catch (e) {
              debugPrint("Failed to repair ticket ${ticket.ticketId}: $e");
            }
          }));
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
      });

      // Send Notifications (Fire & Forget, now with Push!)
      for (final ticket in tickets) {
        if (ticket.userId.isNotEmpty) {
          NotificationService.sendNotificationToUser(
            userId: ticket.userId,
            title: "Booking Confirmed",
            body:
                "Your trip to ${ticket.tripData['destinationCity'] ?? ticket.tripData['toCity'] ?? 'Destination'} is confirmed!",
            type: "booking",
            relatedId: ticket.ticketId,
          );
        }
      }
    } else {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
        });
      }
    }
  }

  Future<void> _downloadTickets(List<Ticket> tickets) async {
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
                pw.Text(
                    "Individual tickets are attached in the following pages.",
                    style: const pw.TextStyle(color: PdfColors.grey)),
              ]));
            }));
      }

      // 2. Add Individual Ticket Pages
      for (final ticket in tickets) {
        // Construct Trip from Ticket Data (Snapshot)
        final tData = ticket.tripData;
        final tripDateVal =
            tData['departureDateTime'] ?? tData['departureTime'];
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
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
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
                              pw.Text(
                                  "Seats: ${ticket.seatNumbers.join(', ')}"),
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

              if (mounted) {
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Permission Denied"),
                backgroundColor: Colors.red));
          }
        }
      } else {
        // iOS and others
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e, stackTrace) {
      debugPrint("Error generating/sharing PDF: $e");
      debugPrint(stackTrace.toString());
      if (mounted) {
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

  void _goTo(int index) => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => CustomerMainScreen(initialIndex: index)),
      (route) => false);

  static DateTime _tripDate(Ticket t) {
    final v = t.tripData['departureDateTime'] ?? t.tripData['departureTime'];
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  static String _from(Ticket t) =>
      (t.tripData['fromCity'] ?? t.tripData['originCity'] ?? '?').toString();
  static String _to(Ticket t) =>
      (t.tripData['toCity'] ?? t.tripData['destinationCity'] ?? '?').toString();

  Future<void> _sms(Ticket t) async {
    final ok = await SmsService.sendTicketCopy(t);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the messages app.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (_isLoading) {
      return _stateScaffold(PaymentStateCard.verifying());
    }
    if (!_isSuccess || _verifiedTickets.isEmpty) {
      return _stateScaffold(PaymentStateCard.failed(
        onHome: () => _goTo(0),
        onSupport: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SupportScreen())),
      ));
    }

    final tickets = _verifiedTickets;
    final t = tickets[_currentIndex.clamp(0, tickets.length - 1)];
    return Scaffold(
      backgroundColor: BL.crimson,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 18, vertical: isDesktop ? 40 : 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tickets.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Previous ticket',
                            color: Colors.white,
                            icon: const Icon(Icons.arrow_back_ios_rounded),
                            onPressed: _currentIndex > 0
                                ? () => setState(() => _currentIndex--)
                                : null,
                          ),
                          Text(
                              'Ticket ${_currentIndex + 1} of ${tickets.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                          IconButton(
                            tooltip: 'Next ticket',
                            color: Colors.white,
                            icon: const Icon(Icons.arrow_forward_ios_rounded),
                            onPressed: _currentIndex < tickets.length - 1
                                ? () => setState(() => _currentIndex++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  isDesktop ? _desktopCard(t, tickets) : _phoneCard(t),
                  const SizedBox(height: 14),
                  _favRow(t),
                  if (!isDesktop) ...[
                    Row(children: [
                      Expanded(
                          child: _whiteButton('Download PDF', Icons.download,
                              () => _downloadTickets(tickets))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _whiteButton('Share via SMS',
                              Icons.sms_outlined, () => _sms(t),
                              outlined: true)),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: () => _goTo(1),
                        style: FilledButton.styleFrom(
                          backgroundColor: BL.crimsonDark,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                        child: const Text('Go to My Trips'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "Save this route" under the ticket, so it is one tap next time.
  Widget _favRow(Ticket t) {
    final from =
        (t.tripData['originCity'] ?? t.tripData['fromCity'] ?? '').toString();
    final to = (t.tripData['destinationCity'] ?? t.tripData['toCity'] ?? '')
        .toString();
    final c = Provider.of<TripController>(context, listen: false);
    return FutureBuilder<bool>(
      key: ValueKey('fav$_favTick'),
      future: c.isRouteFavorite(from, to),
      builder: (context, snap) {
        final fav = snap.data ?? false;
        return Center(
          child: TextButton.icon(
            onPressed: () async {
              await c.toggleRouteFavorite(from, to,
                  operatorName: t.tripData['operatorName']);
              if (mounted) setState(() => _favTick++);
            },
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                color: Colors.white),
            label: Text(
                fav ? 'Saved in Favourites' : 'Save this route in Favourites'),
            style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                textStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  Widget _stateScaffold(Widget card) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: card,
              ),
            ),
          ),
        ),
      );

  Widget _whiteButton(String label, IconData icon, VoidCallback onTap,
      {bool outlined = false}) {
    return SizedBox(
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
          textStyle: const TextStyle(
              fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _qr(Ticket t, double size) => Semantics(
        label: 'QR code for your ticket',
        image: true,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BL.hairline),
          ),
          child: QrImageView(
              data: t.shortId ?? t.ticketId,
              version: QrVersions.auto,
              size: size),
        ),
      );

  Widget _row(String l, String v, {bool last = false, bool line = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: line && !last
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3EDEE))))
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l, style: const TextStyle(fontSize: 17, color: BL.muted)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(v,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  String _seats(Ticket t) => (t.seatNumbers.toList()..sort())
      .map((e) => e == -1 ? 'chosen for you' : '$e')
      .join(', ');

  Widget _phoneCard(Ticket t) {
    final d = _tripDate(t);
    final bus = (t.tripData['busNumber'] ?? '').toString();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          SizedBox(
            height: 72 + 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: Image.asset(cityPhoto(_to(t)),
                      fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 72 - 26,
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
                const Text('Booking Confirmed',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const Text('Show the code or let the conductor scan the QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: BL.muted)),
                const SizedBox(height: 10),
                _qr(t, 112),
                const SizedBox(height: 4),
                Text('E-TICKET · ${t.shortId ?? firstChars(t.ticketId, 8)}',
                    style: const TextStyle(fontSize: 14, color: BL.muted)),
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
                      const Text('CODE',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: BL.crimsonDark)),
                      const SizedBox(width: 12),
                      Semantics(
                        label: 'Verified code ${t.shortId ?? ''}',
                        excludeSemantics: true,
                        child: Text(t.shortId ?? '----',
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
                if (bus.isNotEmpty) _row('Bus number', bus),
                if (platformOf(t.tripData).isNotEmpty)
                  _row('Platform', platformOf(t.tripData)),
                _row('Trip', '${_from(t)} to ${_to(t)}'),
                _row('Leaves', DateFormat('EEE d MMM, hh:mm a').format(d)),
                _row('Seats', _seats(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopCard(Ticket t, List<Ticket> all) {
    final d = _tripDate(t);
    final bus = (t.tripData['busNumber'] ?? '').toString();
    Widget action(String label, IconData? icon, VoidCallback onTap,
        {required bool filled, Color? border}) {
      final style = filled
          ? FilledButton.styleFrom(
              backgroundColor: BL.crimson,
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 26),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  fontWeight: FontWeight.w800))
          : OutlinedButton.styleFrom(
              foregroundColor: border == BL.crimson ? BL.crimson : BL.ink,
              side: BorderSide(color: border ?? BL.border, width: 2),
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 26),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  fontWeight: FontWeight.w800));
      final child = icon == null
          ? Text(label)
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label)
            ]);
      return filled
          ? FilledButton(onPressed: onTap, style: style, child: child)
          : OutlinedButton(onPressed: onTap, style: style, child: child);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                          color: BL.success, shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 14),
                    const Text('Booking Confirmed',
                        style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text(
                        'Payment Confirmed! Your ticket is saved in My Trips.',
                        style: TextStyle(fontSize: 18, color: BL.muted)),
                    const SizedBox(height: 18),
                    _row('Trip', '${_from(t)} to ${_to(t)}', line: true),
                    _row('Leaves',
                        DateFormat('EEE d MMM yyyy, hh:mm a').format(d),
                        line: true),
                    if (bus.isNotEmpty) _row('Bus', bus, line: true),
                    if (platformOf(t.tripData).isNotEmpty)
                      _row('Platform', platformOf(t.tripData), line: true),
                    _row('Seats', _seats(t), line: true),
                    _row('Passenger', t.passengerName, last: true, line: true),
                    const SizedBox(height: 22),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      action('Download PDF', Icons.download,
                          () => _downloadTickets(all),
                          filled: true),
                      action('Share via SMS', null, () => _sms(t),
                          filled: false, border: BL.crimson),
                      action('My Trips', null, () => _goTo(1), filled: false),
                    ]),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                color: const Color(0xFFFDEEEE),
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('E-TICKET',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: BL.crimsonDark)),
                    const SizedBox(height: 12),
                    _qr(t, 200),
                    const SizedBox(height: 12),
                    const Text('Show the code or let the conductor scan the QR',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: BL.muted)),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Verified code ${t.shortId ?? ''}',
                      excludeSemantics: true,
                      child: Text(t.shortId ?? '----',
                          style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 9,
                              color: BL.crimson)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
