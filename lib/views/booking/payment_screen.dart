import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
// For TextInputFormatter
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // For Redirect
import 'package:intl/intl.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../services/payment_service.dart';
import '../../utils/bl_colors.dart';
import '../home/home_sections.dart' show cityPhoto;
import '../layout/app_footer.dart';
import '../widgets/bl_widgets.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String? bookingId;
  final double? amount;
  final EnrichedTrip? trip;
  final bool? isBulk;

  const PaymentScreen({
    super.key,
    this.bookingId,
    this.amount,
    this.trip,
    this.isBulk,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  final PaymentService _paymentService = PaymentService();

  Future<void> _handleCheckoutRedirect() async {
    setState(() => _isProcessing = true);
    final user = Provider.of<User?>(context, listen: false);
    final controller = Provider.of<TripController>(context, listen: false);

    if (user == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to continue")));
      return;
    }

    try {
      // 1. Create Pending Booking in DB (State Persistence)
      String bookingId;
      if (widget.bookingId != null) {
        bookingId = widget.bookingId!;
      } else {
        final id = await controller.createPendingBookingFromState(user);
        bookingId = id;
      }

      final trip = widget.trip ?? controller.selectedTrip!;
      final seats = controller.selectedSeats;

      final double totalAmountVal = widget.amount ??
          (trip.price *
              seats.length *
              (controller.isBulkBooking ? controller.bulkDates.length : 1));
      final String totalAmountStr = totalAmountVal.toStringAsFixed(2);

      if (!mounted) return;
      if (!kIsWeb) {
        final success = await _paymentService.processPaymentMobile(
          context,
          amount: totalAmountStr,
          currency: 'LKR',
        );

        if (success) {
          // Native Payment Success
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const PaymentSuccessScreen(),
                settings: RouteSettings(
                  name: '/payment_success',
                  arguments: {'booking_id': bookingId},
                ),
              ),
            );
          }
        } else {
          setState(() => _isProcessing = false);
        }
        return; // Don't proceed to Web Logic
      }

      // --- WEB PAYMENT (Redirect) ---
      // 2. Construct Dynamic Redirect URLs
      String origin = Uri.base.origin;
      if (origin.endsWith('/')) {
        origin = origin.substring(0, origin.length - 1);
      }

      String successUrl =
          "$origin/#/payment_success?booking_id=$bookingId&session_id={CHECKOUT_SESSION_ID}";
      String cancelUrl = "$origin/#/";

      // 3. Create Stripe Checkout Session
      final redirectUrl = await _paymentService.createCheckoutSession(
        amount: totalAmountStr,
        currency: "LKR",
        successUrl: successUrl,
        cancelUrl: cancelUrl,
        bookingId: bookingId,
      );

      if (redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        } else {
          throw Exception("Could not launch Stripe Checkout.");
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint("Checkout Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        if (e.toString().contains("Seat(s) no longer available")) {
          // Navigate back to seat selection after a brief delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    }
    // Note: If redirect happens, state generally dies here, which is why we saved PendingBooking.
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);

    // Web refresh or lost state: say so, and offer the way home.
    if ((controller.selectedTrip == null || controller.selectedSeats.isEmpty) &&
        widget.trip == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: PaymentStateCard.expired(
                  onHome: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (r) => false),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final trip = widget.trip ?? controller.selectedTrip!;
    final seats = controller.selectedSeats;
    final days = controller.isBulkBooking && controller.bulkDates.isNotEmpty
        ? controller.bulkDates.length
        : 1;
    final totalAmount = widget.amount ?? trip.price * seats.length * days;
    final fmt = NumberFormat('#,###');
    final totalText = 'LKR ${fmt.format(totalAmount)}';
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final summary = _Summary(
      trip: trip,
      seats: seats,
      totalAmount: totalAmount,
      days: controller.isBulkBooking ? controller.bulkDates : const [],
    );
    final method = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Finalize Payment',
            style: TextStyle(
                fontSize: isDesktop ? 32 : 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDEEEE),
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
            border: Border.all(color: BL.crimson, width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: BL.crimson, size: 32),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Credit or debit card',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('You will enter your card on the next, secure page.',
                        style: TextStyle(fontSize: 15, color: BL.muted)),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                    color: BL.crimson, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
    final pay = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlPrimaryButton(
          label:
              _isProcessing ? 'Please wait...' : 'Proceed to Pay · $totalText',
          color: BL.crimson,
          onTap: _isProcessing ? null : _handleCheckoutRedirect,
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 18, color: BL.muted),
            SizedBox(width: 8),
            Text('SSL Encrypted Transaction',
                style: TextStyle(fontSize: 15, color: BL.muted)),
          ],
        ),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: BL.crimson,
                textStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            child: const Text('Back'),
          ),
        ),
      ],
    );

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              color: BL.crimson,
              padding: EdgeInsets.fromLTRB(
                  8, MediaQuery.paddingOf(context).top + 4, 8, 16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Go back',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                  const SizedBox(width: 4),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Secure Checkout',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      Text('Step 3 of 3',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  children: [summary, const SizedBox(height: 16), method],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 14, 16, 8 + MediaQuery.paddingOf(context).bottom),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: BL.hairline))),
              child: pay,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: BL.hairline))),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 1200, minHeight: 72),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BusLink',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: BL.crimson)),
                        Row(children: [
                          Icon(Icons.lock_outline, size: 20, color: BL.muted),
                          SizedBox(width: 8),
                          Text('SSL Encrypted Transaction',
                              style: TextStyle(fontSize: 16, color: BL.muted)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BookingSteps(current: 2),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                method,
                                const SizedBox(height: 20),
                                pay,
                              ],
                            ),
                          ),
                          const SizedBox(width: 28),
                          SizedBox(width: 420, child: summary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

/// "Booking summary" card with the destination photo on top.
class _Summary extends StatelessWidget {
  final EnrichedTrip trip;
  final List<String> seats;
  final double totalAmount;
  final List<DateTime> days;
  const _Summary(
      {required this.trip,
      required this.seats,
      required this.totalAmount,
      required this.days});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final bulk = days.length > 1;
    final autoSeats = seats.contains('-1');
    final bus = [
      if (trip.operatorName.isNotEmpty) trip.operatorName,
      if (trip.busNumber.isNotEmpty) trip.busNumber,
    ].join(' · ');
    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BL.hairline),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14660708), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(cityPhoto(trip.toCity),
                    fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xEB460405), Color(0x80960E12)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 10,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('BOOKING SUMMARY',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.9)),
                      Text('${trip.fromCity} to ${trip.toCity}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (bulk) ...[
                  row('Days', '${days.length} days'),
                  for (final d in days)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(DateFormat('EEE, d MMM yyyy').format(d),
                          style: const TextStyle(fontSize: 16)),
                    ),
                ] else
                  row(
                      'Date',
                      DateFormat('EEE d MMM, hh:mm a')
                          .format(trip.departureTime)),
                if (bulk)
                  row('Leaves',
                      DateFormat('hh:mm a').format(trip.departureTime)),
                if (bus.isNotEmpty) row('Bus', bus),
                row(
                    'Seats',
                    autoSeats
                        ? 'Chosen for you'
                        : (seats.toList()
                              ..sort((a, b) => (int.tryParse(a) ?? 0)
                                  .compareTo(int.tryParse(b) ?? 0)))
                            .join(', ')),
                const Divider(height: 24, color: BL.hairline),
                row('${seats.length} seat${seats.length == 1 ? '' : 's'} × LKR ${fmt.format(trip.price)}${bulk ? ' × ${days.length} days' : ''}',
                    'LKR ${fmt.format(totalAmount)}'),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Expanded(
                        child: Text('Total Amount',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      Text('LKR ${fmt.format(totalAmount)}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: BL.crimson)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The three things that can happen while paying (mockup "PaymentStates").
class PaymentStateCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String message;
  final Color? tint;
  final Color? border;
  final List<Widget> actions;
  const PaymentStateCard._(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actions,
      this.tint,
      this.border});

  factory PaymentStateCard.verifying() => const PaymentStateCard._(
        icon: SizedBox(
            width: 48,
            height: 48,
            child:
                CircularProgressIndicator(color: BL.crimson, strokeWidth: 4)),
        title: 'Verifying Payment...',
        message: 'Please wait. Do not close this page.',
        actions: [],
      );

  factory PaymentStateCard.failed(
          {required VoidCallback onHome, required VoidCallback onSupport}) =>
      PaymentStateCard._(
        icon: _badge(BL.crimson, Colors.white, Icons.close),
        title: 'Verification Failed',
        message:
            'We could not confirm your payment. If money left your account, please contact support. Your seats are not lost.',
        tint: const Color(0xFFFDEEEE),
        border: const Color(0xFFE5383B),
        actions: [
          Expanded(child: _outlined('Go Home', onHome)),
          const SizedBox(width: 10),
          Expanded(
              child: BlPrimaryButton(
                  label: 'Get help', color: BL.crimson, onTap: onSupport)),
        ],
      );

  factory PaymentStateCard.expired({required VoidCallback onHome}) =>
      PaymentStateCard._(
        icon: _badge(
            const Color(0xFFFFF1DB), const Color(0xFF7A4300), Icons.schedule),
        title: 'Session Expired',
        message:
            'Your session has expired or no seats are selected. Please start again.',
        actions: [
          Expanded(
              child: BlPrimaryButton(
                  label: 'Return to Home', color: BL.crimson, onTap: onHome)),
        ],
      );

  static Widget _badge(Color bg, Color fg, IconData i) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(i, size: 28, color: fg),
      );

  static Widget _outlined(String label, VoidCallback onTap) => SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: BL.crimson,
            side: const BorderSide(color: BL.crimson, width: 2),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
          child: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tint ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border ?? BL.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, height: 1.4, color: BL.muted)),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: actions),
          ],
        ],
      ),
    );
  }
}
