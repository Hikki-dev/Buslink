import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../utils/bl_colors.dart';
import '../../utils/platform_text.dart';
import '../home/home_sections.dart' show cityPhoto;
import '../tracking/track_bus_screen.dart' deferred as tracking;
import 'ticket_pdf.dart' deferred as ticket_pdf;
import '../../app/deferred_screen.dart';
import '../profile/feedback_dialog.dart';
import '../../utils/text_utils.dart';

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
        backgroundColor: BL.surface,
        appBar: AppBar(
            backgroundColor: BL.surface,
            iconTheme: IconThemeData(color: BL.ink)),
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
    final code = ticket.shortId ?? firstChars(ticket.ticketId, 4);

    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l, style: TextStyle(fontSize: 16, color: BL.muted)),
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
          color: BL.surface, borderRadius: BorderRadius.circular(20)),
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
                Text('Show the code or let the conductor scan the QR',
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
                      backgroundColor: Colors.white,
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
                      color: BL.tint, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('CODE',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: BL.deep)),
                      const SizedBox(width: 12),
                      Semantics(
                        label: 'Verified code $code',
                        excludeSemantics: true,
                        child: Text(code,
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 5,
                                color: BL.link)),
                      ),
                    ],
                  ),
                ),
                Divider(height: 28, color: BL.hairline),
                row('Trip', '${trip.fromCity} to ${trip.toCity}'),
                if (trip.via.isNotEmpty && trip.via != 'Direct')
                  row('Via', trip.via),
                row(
                    'Leaves',
                    DateFormat('EEE d MMM, hh:mm a')
                        .format(trip.departureTime)),
                if (platformOf(ticket.tripData).isNotEmpty)
                  row('Platform', platformOf(ticket.tripData)),
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
              textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  fontWeight: FontWeight.w800),
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
                                  Icons.download, () async {
                            await ticket_pdf.loadLibrary();
                            if (context.mounted) {
                              ticket_pdf.downloadTicketPdf(
                                  context, trip, tickets);
                            }
                          })),
                          if (live) ...[
                            const SizedBox(width: 10),
                            Expanded(
                                child: pill('Track bus', Icons.gps_fixed, () {
                              pushDeferred(context,
                                  load: tracking.loadLibrary,
                                  build: () =>
                                      tracking.TrackBusScreen(trip: trip));
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
      builder: (ctx) => const FeedbackDialog(),
    );
  }
}
