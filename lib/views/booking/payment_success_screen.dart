import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/app_theme.dart'; // Added Import
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

// import '../../views/home/home_screen.dart'; // Unused
import '../customer_main_screen.dart';

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

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  bool _isInit = true;

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
            t.tripData['fromCity'] == null || t.tripData['toCity'] == null);

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
                ticket.tripData['fromCity'] = tMap['fromCity'];
                ticket.tripData['toCity'] = tMap['toCity'];
                ticket.tripData['busNumber'] = tMap['busNumber'];
                ticket.tripData['platformNumber'] = tMap['platformNumber'];
                ticket.tripData['departureTime'] = tMap['departureTime'];
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
        _message = "Payment Confirmed!";
      });

      // Send Notifications (Fire & Forget, now with Push!)
      for (final ticket in tickets) {
        if (ticket.userId.isNotEmpty) {
          NotificationService.sendNotificationToUser(
            userId: ticket.userId,
            title: "Booking Confirmed",
            body:
                "Your trip to ${ticket.tripData['toCity'] ?? 'Destination'} is confirmed!",
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
          _message = "Could not verify all bookings. Please contact support.";
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
              double totalAmount =
                  tickets.fold(0, (sum, item) => sum + item.totalAmount);

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
                            final tripDate = tData['departureTime'] is Timestamp
                                ? (tData['departureTime'] as Timestamp).toDate()
                                : DateTime.tryParse(
                                        tData['departureTime'].toString()) ??
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
                                          "${tData['fromCity']} -> ${tData['toCity']}")),
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
        final tripDate = tData['departureTime'] is Timestamp
            ? (tData['departureTime'] as Timestamp).toDate()
            : DateTime.tryParse(tData['departureTime'].toString()) ??
                DateTime.now();

        final fromCity = tData['fromCity'] ?? tData['originCity'] ?? '';
        final toCity = tData['toCity'] ?? tData['destinationCity'] ?? '';
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
                                        "Ticket Code: ${ticket.shortId ?? ticket.ticketId.substring(0, 8).toUpperCase()}",
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

      if (kIsWeb) {
        await downloadBytesForWeb(bytes, 'buslink_tickets.pdf');
      } else {
        await Printing.sharePdf(bytes: bytes, filename: 'buslink_tickets.pdf');
      }
    } catch (e, stackTrace) {
      debugPrint("Error generating/sharing PDF: $e");
      debugPrint(stackTrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to generate PDF: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const CustomerMainScreen(initialIndex: 0)),
                  (route) => false);
            },
            child: const Text(
              "Done",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading) ...[
                    const CircularProgressIndicator(color: Colors.black),
                    const SizedBox(height: 24),
                    Text(_message,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Colors.grey)),
                  ] else if (_isSuccess && _verifiedTickets.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.green, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Thank You for booking with BusLink,\n${(_verifiedTickets.first.passengerName.isNotEmpty ? _verifiedTickets.first.passengerName.split(' ')[0] : 'Traveler')}!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Here is your booking confirmation.\nYou can also view this in 'My Trips'.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.2),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),

                    // --- TICKET CAROUSEL ---
                    if (_verifiedTickets.isNotEmpty) ...[
                      SizedBox(
                        height: 480,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _verifiedTickets.length,
                          onPageChanged: (index) =>
                              setState(() => _currentIndex = index),
                          itemBuilder: (context, index) {
                            return _buildTicketCard(
                                _verifiedTickets[index], isDark);
                          },
                        ),
                      ),

                      // Indicators / Arrows
                      if (_verifiedTickets.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded),
                              onPressed: _currentIndex > 0
                                  ? () => _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.ease)
                                  : null,
                            ),
                            Text(
                                "${_currentIndex + 1} / ${_verifiedTickets.length}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded),
                              onPressed:
                                  _currentIndex < _verifiedTickets.length - 1
                                      ? () => _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.ease)
                                      : null,
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // Download Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadTickets(_verifiedTickets),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.primaryColor),
                            foregroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: Text(
                              _verifiedTickets.length > 1
                                  ? "Download All Tickets (PDF)"
                                  : "Download Ticket (PDF)",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Add to Favorites Button
                    if (_verifiedTickets.isNotEmpty)
                      _FavoriteRouteButton(
                        userId: _verifiedTickets.first.userId,
                        fromCity:
                            _verifiedTickets.first.tripData['fromCity'] ?? '',
                        toCity: _verifiedTickets.first.tripData['toCity'] ?? '',
                        operatorName:
                            _verifiedTickets.first.tripData['operatorName'],
                      ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CustomerMainScreen(
                                                initialIndex: 1)),
                                    (route) => false);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text("My Trips",
                                  style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CustomerMainScreen(
                                                initialIndex: 0)),
                                    (route) => false);
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text("Home",
                                  style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    const Text(
                      "Verification Failed",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const CustomerMainScreen(
                                      initialIndex: 0)),
                              (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Go Home",
                            style: TextStyle(
                                fontFamily: 'Outfit',
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

  Widget _buildTicketCard(Ticket ticket, bool isDark) {
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
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(dateStr,
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black)),
            Text(
                "${tData['fromCity'] ?? tData['originCity'] ?? '?'} ➔ ${tData['toCity'] ?? tData['destinationCity'] ?? '?'}",
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 12),
            QrImageView(
              data: ticket.shortId ?? ticket.ticketId,
              version: QrVersions.auto,
              size: 150,
            ),
            const SizedBox(height: 8),
            const Text(
              "SHOW 4-DIGIT CODE OR SCAN QR",
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text("TICKET CODE: ${ticket.shortId ?? 'N/A'}",
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 4),
            SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final success = await SmsService.sendTicketCopy(ticket);
                    if (context.mounted) {
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Could not launch SMS app."),
                                backgroundColor: Colors.red));
                      }
                    }
                  },
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text("Share via SMS"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )),
          ],
        ));
  }
}

class _FavoriteRouteButton extends StatefulWidget {
  final String userId;
  final String fromCity;
  final String toCity;
  final String? operatorName;

  const _FavoriteRouteButton({
    required this.userId,
    required this.fromCity,
    required this.toCity,
    this.operatorName,
  });

  @override
  State<_FavoriteRouteButton> createState() => _FavoriteRouteButtonState();
}

class _FavoriteRouteButtonState extends State<_FavoriteRouteButton> {
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final controller = Provider.of<TripController>(context, listen: false);
    final fav =
        await controller.isRouteFavorite(widget.fromCity, widget.toCity);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle() async {
    setState(() => _isLoading = true);
    final controller = Provider.of<TripController>(context, listen: false);
    await controller.toggleRouteFavorite(widget.fromCity, widget.toCity,
        operatorName: widget.operatorName);

    // Toggle state locally
    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isFavorite
              ? "Route added to Favorites"
              : "Route removed from Favorites")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: _toggle,
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.grey,
      ),
      label: Text(
        _isFavorite ? "Favorited Route" : "Add Route to Favorites",
        style: TextStyle(
          color: _isFavorite ? Colors.red : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
