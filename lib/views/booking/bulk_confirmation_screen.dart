import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';
import '../../services/auth_service.dart';
import 'payment_screen.dart';

class BulkConfirmationScreen extends StatefulWidget {
  final EnrichedTrip trip;
  const BulkConfirmationScreen({super.key, required this.trip});

  @override
  State<BulkConfirmationScreen> createState() => _BulkConfirmationScreenState();
}

class _BulkConfirmationScreenState extends State<BulkConfirmationScreen> {
  bool _isProcessing = false;

  void _processBulkBooking() async {
    setState(() => _isProcessing = true);
    final tripCtrl = Provider.of<TripController>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to continue")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // 1. Create Pending Bookings for ALL dates
      // Logic inside TripController handling loop
      final bookingIds = await tripCtrl.createPendingBookingFromState(user);

      if (bookingIds.isNotEmpty && mounted) {
        // 2. Navigate to Payment
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              bookingId: bookingIds, // Comma separated IDs
              amount: tripCtrl.calculateBulkTotal(widget.trip.price),
              trip: widget.trip,
              isBulk: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripCtrl = Provider.of<TripController>(context);
    final total = tripCtrl.calculateBulkTotal(widget.trip.price);
    final fmt = NumberFormat('#,###');
    final dates = tripCtrl.bulkDates;
    final shown = dates.take(3).toList();

    Widget card(String title, Widget child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: BL.hairline),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: BL.crimson)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        );
    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Text(l, style: const TextStyle(fontSize: 17, color: BL.muted)),
            const Spacer(),
            Text(v,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const BlHeader(title: 'Bulk Booking Summary'),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    card(
                      'SELECTED ROUTE',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${widget.trip.fromCity} to ${widget.trip.toCity}',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          Text(
                              '${widget.trip.operatorName} · Leaves ${DateFormat('hh:mm a').format(widget.trip.departureTime)}',
                              style: const TextStyle(
                                  fontSize: 16, color: BL.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    card(
                      'TRAVEL DATES',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final d in shown)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                  DateFormat('EEEE, d MMMM yyyy').format(d),
                                  style: const TextStyle(fontSize: 17)),
                            ),
                          if (dates.length > shown.length)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  '+ ${dates.length - shown.length} more days',
                                  style: const TextStyle(
                                      fontSize: 17, color: BL.muted)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    card(
                      'PRICE BREAKDOWN',
                      Column(
                        children: [
                          row('Price per ticket',
                              'LKR ${fmt.format(widget.trip.price)}'),
                          row('Passengers', '${tripCtrl.seatsPerTrip}'),
                          row('Total days', '${dates.length}'),
                          const Divider(height: 22, color: BL.hairline),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text('Total Amount',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text('LKR ${fmt.format(total)}',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: BL.crimson)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: BL.hairline))),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: BlPrimaryButton(
                  label:
                      _isProcessing ? 'Please wait...' : 'Proceed to Payment',
                  color: BL.crimson,
                  onTap: _isProcessing ? null : _processBulkBooking,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
