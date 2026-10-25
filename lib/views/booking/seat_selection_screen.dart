import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart'; // Added for SMS

import 'payment_screen.dart';
import 'bulk_confirmation_screen.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';
import '../../services/auth_service.dart';
import 'payment_success_screen.dart';
import 'bus_layout_widget.dart';
import '../auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/bl_widgets.dart';
import '../../utils/bl_colors.dart';
import '../home/home_sections.dart' show cityPhoto;
import '../../utils/text_utils.dart';

class SeatSelectionScreen extends StatefulWidget {
  final EnrichedTrip trip;
  final bool showBackButton;
  final bool isConductorMode;

  const SeatSelectionScreen(
      {super.key,
      required this.trip,
      this.showBackButton = true,
      this.isConductorMode = false});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _autoSelectForBulk(); // User requested manual selection only
    });
  }

  static const _maxSeats = 6;

  void _toggle(TripController c, int seat) {
    final has = c.selectedSeats.contains(seat.toString());
    if (!has &&
        !widget.isConductorMode &&
        !c.isBulkBooking &&
        c.selectedSeats.length >= _maxSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can choose up to 6 seats.')));
      return;
    }
    c.toggleSeat(seat.toString());
  }

  void _continue(BuildContext context, TripController controller) {
    if (widget.isConductorMode) {
      _handleConductorBooking(context, controller);
      return;
    }
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Please sign in',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text(
              'To keep your seats and get your ticket, sign in to your BusLink account.',
              style: TextStyle(fontSize: 17)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Not now', style: TextStyle(fontSize: 16))),
            FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                style: FilledButton.styleFrom(backgroundColor: BL.crimson),
                child: const Text('Sign in', style: TextStyle(fontSize: 16))),
          ],
        ),
      );
    } else if (controller.isBulkBooking) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BulkConfirmationScreen(trip: widget.trip)));
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final selected = controller.selectedSeats
        .map((e) => int.tryParse(e) ?? 0)
        .toList()
      ..sort();
    final trip = widget.trip;
    final total = trip.price *
        selected.length *
        (controller.isBulkBooking && controller.bulkDates.isNotEmpty
            ? controller.bulkDates.length
            : 1);
    final totalText = 'LKR ${NumberFormat('#,###').format(total)}';
    final cta =
        widget.isConductorMode ? 'Issue ticket (cash)' : 'Continue to payment';

    final map = StreamBuilder<EnrichedTrip?>(
      stream: controller.getTripRealtimeStream(trip.trip.id),
      initialData: trip,
      builder: (context, snapshot) => BusLayoutWidget(
        trip: snapshot.data?.trip ?? trip.trip,
        totalSeats: trip.totalSeats,
        selectedSeats: selected,
        isDark: false,
        onSeatToggle: (n) => _toggle(controller, n),
      ),
    );

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: BL.surface,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Choose your seats',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        Text('You can pick up to 6',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: BL.hairline))),
              child: const _Legend(yours: 'Yours', spaced: true),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: map),
              ),
            ),
            if (selected.isNotEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, 12 + MediaQuery.paddingOf(context).bottom),
                decoration: BoxDecoration(
                  color: BL.surface,
                  border: Border(top: BorderSide(color: BL.hairline)),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x14660708),
                        blurRadius: 14,
                        offset: Offset(0, -4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                              '${selected.length} seat${selected.length == 1 ? '' : 's'}: ${selected.join(', ')}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500)),
                        ),
                        Text(totalText,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: BL.link)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BlPrimaryButton(
                        label: cta,
                        color: widget.isConductorMode ? BL.success : BL.crimson,
                        onTap: () => _continue(context, controller)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // ---------------------------------------------------------- desktop
    return Scaffold(
      backgroundColor: BL.surface,
      body: FooterScroll(children: [
        const DesktopNavBar(),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BookingSteps(current: 1),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: blCard(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 12,
                                children: const [
                                  Text('Choose your seats',
                                      style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700)),
                                  _Legend(yours: 'Your choice'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('You can choose up to 6 seats.',
                                  style:
                                      TextStyle(fontSize: 17, color: BL.muted)),
                              const SizedBox(height: 28),
                              Center(child: map),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 380,
                        child: _Summary(
                          trip: trip,
                          selected: selected,
                          unitPrice: trip.price,
                          totalText: totalText,
                          cta: cta,
                          ctaColor:
                              widget.isConductorMode ? BL.success : BL.crimson,
                          onContinue: selected.isEmpty
                              ? null
                              : () => _continue(context, controller),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _handleConductorBooking(
      BuildContext context, TripController controller) {
    // We need to resolve auth service here to get the 'Conductor' user
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Conductor not logged in?")));
      return;
    }

    final total = widget.trip.price * controller.selectedSeats.length;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneNumberController = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Issue Cash Ticket",
                  style: TextStyle(
                      fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Review Booking:",
                        style: TextStyle(
                            fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Seats: ${controller.selectedSeats.join(', ')}"),
                    Text("Total Amount: LKR ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: "Passenger Name (Optional)",
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: "Mobile Number (Required)",
                          hintText: "07xxxxxxxx or +947xxxxxxxx",
                          helperText: "For SMS Ticket",
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    const Text("Collect cash before confirming.",
                        style: TextStyle(color: Colors.red, fontSize: 12))
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      // 1. Validation for SL Number
                      String phone = phoneNumberController.text.trim();
                      if (phone.startsWith('94')) phone = '+$phone';

                      bool isValid = false;
                      if (phone.startsWith('07') && phone.length == 10) {
                        isValid = true;
                      }
                      if (phone.startsWith('+947') && phone.length == 12) {
                        isValid = true;
                      }

                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                "Invalid SL Number. Use 07xxxxxxxx or +947xxxxxxxx"),
                            backgroundColor: Colors.red));
                        return;
                      }

                      Navigator.pop(ctx);
                      final String pName = nameController.text.isEmpty
                          ? "Offline Passenger"
                          : nameController.text;

                      try {
                        final ticket = await FirestoreService()
                            .createOfflineBooking(
                                widget.trip.trip,
                                controller.selectedSeats
                                    .map((e) => int.tryParse(e) ?? 0)
                                    .toList(),
                                pName,
                                user,
                                phoneNumber: phone);

                        if (context.mounted) {
                          Provider.of<TripController>(context, listen: false)
                              .selectTrip(widget.trip);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "Ticket Issued! ID: ${firstChars(ticket.ticketId, 5)}... SMS Sending...")));

                          await SmsService.sendTicketCopy(ticket);

                          if (context.mounted) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PaymentSuccessScreen(),
                                    settings: RouteSettings(arguments: {
                                      'booking_id': ticket.ticketId,
                                      'phone_number': phone
                                    })));
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Text("Confirm & Send SMS"))
              ],
            ));
  }
}

/// Free / Yours / Taken key. Each has a shape as well as a colour.
class _Legend extends StatelessWidget {
  final String yours;
  final bool spaced;
  const _Legend({required this.yours, this.spaced = false});

  Widget _chip(Color fill, Color? border, IconData? icon, Color iconColor,
          String label) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
              border:
                  border == null ? null : Border.all(color: border, width: 1.5),
            ),
            child: icon == null ? null : Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final items = [
      _chip(Colors.white, BL.faint, null, BL.ink, 'Free'),
      _chip(BL.crimson, null, Icons.check, Colors.white, yours),
      _chip(const Color(0xFFD5DAE0), null, Icons.close, BL.muted, 'Taken'),
    ];
    return spaced
        ? Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: items)
        : Wrap(spacing: 20, runSpacing: 8, children: items);
  }
}

class _Summary extends StatelessWidget {
  final EnrichedTrip trip;
  final List<int> selected;
  final double unitPrice;
  final String totalText;
  final String cta;
  final Color ctaColor;
  final VoidCallback? onContinue;
  const _Summary({
    required this.trip,
    required this.selected,
    required this.unitPrice,
    required this.totalText,
    required this.cta,
    required this.ctaColor,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final bus = [
      if (trip.busType.isNotEmpty) trip.busType,
      if (trip.busNumber.isNotEmpty) trip.busNumber,
    ].join(' · ');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: blCard(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(cityPhoto(trip.toCity),
                    fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x0D000000), Color(0xD9320304)],
                      stops: [0.2, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${trip.fromCity} to ${trip.toCity}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '${DateFormat('EEE d MMM').format(trip.departureTime)} · ${DateFormat('hh:mm a').format(trip.departureTime)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.operatorName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                if (bus.isNotEmpty)
                  Text(bus, style: TextStyle(fontSize: 16, color: BL.muted)),
                Divider(height: 36, color: BL.hairline),
                Text('Your seats',
                    style: TextStyle(fontSize: 16, color: BL.muted)),
                const SizedBox(height: 8),
                if (selected.isEmpty)
                  const Text('Tap a seat on the map to choose it.',
                      style: TextStyle(fontSize: 17))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in selected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: BL.blush,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('Seat $n',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: BL.deep)),
                        ),
                    ],
                  ),
                Divider(height: 36, color: BL.hairline),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${selected.length} seat${selected.length == 1 ? '' : 's'} × LKR ${fmt.format(unitPrice)}',
                        style: const TextStyle(fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(totalText,
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: BL.link)),
                  ],
                ),
                const SizedBox(height: 20),
                BlPrimaryButton(label: cta, color: ctaColor, onTap: onContinue),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: TextButton.styleFrom(
                        foregroundColor: BL.link,
                        textStyle: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    child: const Text('Back to buses'),
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
