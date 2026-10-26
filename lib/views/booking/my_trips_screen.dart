// lib/views/booking/my_trips_screen.dart
// "My Trips" (mockups "MyTickets" and "Desktop-MyTickets").
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip_model.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/bl_colors.dart';
import '../../utils/platform_text.dart';
import '../home/home_sections.dart' show cityPhoto;
import '../ticket/ticket_screen.dart';
import '../tracking/track_bus_screen.dart' deferred as tracking;
import '../../app/deferred_screen.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';
import '../analytics/travel_stats_screen.dart';
import 'refund_request_screen.dart';
import 'package:buslink/l10n/app_localizations.dart';
import '../../utils/text_utils.dart';

enum TripFilter { upcoming, completed, cancelled, delayed }

DateTime _depOf(Ticket t) {
  final v = t.tripData['departureDateTime'] ?? t.tripData['departureTime'];
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v) ?? t.bookingTime;
  return t.bookingTime;
}

String _fromOf(Ticket t) =>
    (t.tripData['fromCity'] ?? t.tripData['originCity'] ?? 'Unknown')
        .toString();
String _toOf(Ticket t) =>
    (t.tripData['toCity'] ?? t.tripData['destinationCity'] ?? 'Unknown')
        .toString();

String _statusOf(Ticket t) =>
    (t.tripData['status'] ?? t.status).toString().toLowerCase();

/// Tickets for one tab. Several tickets from one payment are grouped into a
/// bundle (a `List<Ticket>`); everything else is a single `Ticket`.
List<dynamic> filterTickets(List<Ticket> all, TripFilter filter) {
  final now = DateTime.now();
  final tickets = all.where((t) {
    final status = _statusOf(t);
    final date = _depOf(t);
    switch (filter) {
      case TripFilter.cancelled:
        return status == 'cancelled';
      case TripFilter.delayed:
        return status == 'delayed' || (t.tripData['delayMinutes'] ?? 0) > 0;
      case TripFilter.completed:
        if (status == 'cancelled' ||
            status == 'delayed' ||
            status == 'refunded') {
          return false;
        }
        return status == 'completed' ||
            status == 'arrived' ||
            date.isBefore(now);
      case TripFilter.upcoming:
        if (status == 'cancelled' ||
            status == 'delayed' ||
            status == 'refunded' ||
            status == 'completed' ||
            status == 'arrived') {
          return false;
        }
        return date.isAfter(now);
    }
  }).toList();

  final items = <dynamic>[];
  final bundles = <String, List<Ticket>>{};
  for (final t in tickets) {
    final groupId = t.tripData['batchId'] ??
        ((t.paymentIntentId ?? '').isNotEmpty ? t.paymentIntentId : null);
    if (groupId != null) {
      bundles.putIfAbsent(groupId, () => []).add(t);
    } else {
      items.add(t);
    }
  }
  for (final b in bundles.values) {
    items.add(b.length > 1 ? b : b.first);
  }
  DateTime key(dynamic i) => _depOf(i is List<Ticket> ? i.first : i as Ticket);
  items.sort((a, b) => filter == TripFilter.upcoming
      ? key(a).compareTo(key(b))
      : key(b).compareTo(key(a)));
  return items;
}

class MyTripsScreen extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool isAdminView;

  const MyTripsScreen(
      {super.key,
      this.showBackButton = true,
      this.onBack,
      this.isAdminView = false});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final controller = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return StreamBuilder<List<Ticket>>(
      stream: controller.getUserTickets(),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final all = snapshot.data ?? [];
        Widget body;
        if (user == null) {
          body = _message(Icons.lock_clock, 'Please sign in to see your trips');
        } else if (loading) {
          body =
              const Center(child: CircularProgressIndicator(color: BL.crimson));
        } else if (snapshot.hasError) {
          body = _message(Icons.cloud_off,
              'We could not load your trips. Check your connection and try again.');
        } else {
          body = isDesktop
              ? _DesktopTrips(all: all)
              : _PhoneTrips(all: all, onBack: showBackButton ? onBack : null);
        }
        if (!isDesktop) {
          return Scaffold(backgroundColor: BL.surface, body: body);
        }
        return Scaffold(
          backgroundColor: BL.surface,
          body: Column(children: [
            DesktopNavBar(selectedIndex: 1, isAdminView: isAdminView),
            Expanded(child: body),
          ]),
        );
      },
    );
  }

  static Widget _message(IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: BL.border),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: BL.muted)),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------- phone
class _PhoneTrips extends StatelessWidget {
  final List<Ticket> all;
  final VoidCallback? onBack;
  const _PhoneTrips({required this.all, this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final upcoming = filterTickets(all, TripFilter.upcoming).length;
    final done = filterTickets(all, TripFilter.completed).length;
    final counts = <String, int>{};
    for (final t in all) {
      if (_depOf(t).isBefore(now) || upcoming > 0) {
        counts[_toOf(t)] = (counts[_toOf(t)] ?? 0) + 1;
      }
    }
    final top = counts.isEmpty
        ? '-'
        : (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    Widget stat(String v, String l) => Expanded(
          child: Semantics(
            label: '$l: $v',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  Text(l,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        );

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: BL.crimson,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.paddingOf(context).top + 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        tooltip: 'Go back',
                        onPressed: onBack,
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    Expanded(
                      child: Text(l10n.myTrips,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      tooltip: 'Your travel numbers',
                      color: Colors.white,
                      icon: const Icon(Icons.bar_chart),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TravelStatsScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  stat('$done', 'Trips taken'),
                  const SizedBox(width: 10),
                  stat('$upcoming', 'Coming up'),
                  const SizedBox(width: 10),
                  stat(top, 'Top place'),
                ]),
                const SizedBox(height: 8),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                  indicatorColor: Colors.white,
                  indicatorWeight: 4,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: l10n.tabUpcoming.toUpperCase()),
                    Tab(text: l10n.tabCompleted.toUpperCase()),
                    Tab(text: l10n.tabCancelled.toUpperCase()),
                    Tab(text: l10n.tabDelayed.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final f in TripFilter.values)
                  _PhoneList(all: all, filter: f),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneList extends StatelessWidget {
  final List<Ticket> all;
  final TripFilter filter;
  const _PhoneList({required this.all, required this.filter});

  @override
  Widget build(BuildContext context) {
    final items = filterTickets(all, filter);
    if (items.isEmpty) {
      return _EmptyTrips(filter: filter);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final item = items[i];
            if (item is List<Ticket>) {
              return _BulkBoardingPassCard(tickets: item);
            }
            return BoardingPassCard(
              ticket: item as Ticket,
              shouldListen:
                  filter == TripFilter.upcoming || filter == TripFilter.delayed,
            );
          },
        ),
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  final TripFilter filter;
  const _EmptyTrips({required this.filter});

  @override
  Widget build(BuildContext context) {
    final text = switch (filter) {
      TripFilter.upcoming =>
        'No trips coming up. Find a bus on the Home page and your ticket will be here.',
      TripFilter.completed => 'No finished trips yet.',
      TripFilter.cancelled => 'No cancelled trips. Good news.',
      TripFilter.delayed => 'None of your buses are running late.',
    };
    return MyTripsScreen._message(Icons.directions_bus_outlined, text);
  }
}

// -------------------------------------------------------------- desktop
class _DesktopTrips extends StatefulWidget {
  final List<Ticket> all;
  const _DesktopTrips({required this.all});

  @override
  State<_DesktopTrips> createState() => _DesktopTripsState();
}

class _DesktopTripsState extends State<_DesktopTrips> {
  TripFilter _filter = TripFilter.upcoming;
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = filterTickets(widget.all, _filter);
    final sel =
        items.isEmpty ? null : items[_selected.clamp(0, items.length - 1)];
    final labels = {
      TripFilter.upcoming: l10n.tabUpcoming,
      TripFilter.completed: l10n.tabCompleted,
      TripFilter.cancelled: l10n.tabCancelled,
      TripFilter.delayed: l10n.tabDelayed,
    };

    return FooterScroll(children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('My tickets',
                          style: TextStyle(
                              fontSize: 34, fontWeight: FontWeight.w700)),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TravelStatsScreen())),
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Your travel numbers'),
                      style: TextButton.styleFrom(
                          foregroundColor: BL.link,
                          minimumSize: const Size(0, 48),
                          textStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final f in TripFilter.values)
                      ChoiceChip(
                        label: Text(labels[f]!,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _filter == f ? Colors.white : BL.ink)),
                        selected: _filter == f,
                        showCheckmark: false,
                        selectedColor: BL.crimson,
                        backgroundColor: BL.surface,
                        side: BorderSide(color: BL.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        onSelected: (_) => setState(() {
                          _filter = f;
                          _selected = 0;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  SizedBox(height: 320, child: _EmptyTrips(filter: _filter))
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 400,
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              _ListTile(
                                item: items[i],
                                selected:
                                    i == _selected.clamp(0, items.length - 1),
                                onTap: () => setState(() => _selected = i),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: sel is List<Ticket>
                            ? _BulkBoardingPassCard(tickets: sel)
                            : _Detail(ticket: sel as Ticket),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ListTile extends StatelessWidget {
  final dynamic item;
  final bool selected;
  final VoidCallback onTap;
  const _ListTile(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t =
        item is List<Ticket> ? (item as List<Ticket>).first : item as Ticket;
    final bundle = item is List<Ticket>;
    final st = _chip(t, _depOf(t));
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BL.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? BL.crimson : Colors.transparent, width: 3),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14660708),
                  blurRadius: 10,
                  offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: ColorFiltered(
                    colorFilter: st.done
                        ? const ColorFilter.matrix([
                            0.33,
                            0.33,
                            0.33,
                            0,
                            0,
                            0.33,
                            0.33,
                            0.33,
                            0,
                            0,
                            0.33,
                            0.33,
                            0.33,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst),
                    child: Image.asset(cityPhoto(_toOf(t)), fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_fromOf(t)} to ${_toOf(t)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                        bundle
                            ? '${(item as List).length} trips'
                            : DateFormat('EEE, d MMM · hh:mm a')
                                .format(_depOf(t)),
                        style: TextStyle(fontSize: 16, color: BL.muted)),
                    const SizedBox(height: 8),
                    _StatusChip(st),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final Ticket ticket;
  const _Detail({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final dep = _depOf(t);
    final arr = t.tripData['arrivalDateTime'] ?? t.tripData['arrivalTime'];
    final arrival = arr is Timestamp ? arr.toDate() : null;
    final bus = (t.tripData['busNumber'] ?? '').toString();
    final operator = (t.tripData['operatorName'] ?? '').toString();
    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Text(l, style: TextStyle(fontSize: 18, color: BL.muted)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(v,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: BL.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14660708), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(cityPhoto(_toOf(t)),
                    fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x0D000000), Color(0xD9320304)],
                      stops: [0.25, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${_fromOf(t)} to ${_toOf(t)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '${operator.isEmpty ? '' : '$operator · '}${DateFormat('EEE d MMM yyyy').format(dep)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Wrap(
              spacing: 32,
              runSpacing: 24,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 360,
                  child: Column(
                    children: [
                      row('Leaves', DateFormat('hh:mm a').format(dep)),
                      if (arrival != null)
                        row('Arrives', DateFormat('hh:mm a').format(arrival)),
                      if (bus.isNotEmpty) row('Bus number', bus),
                      if (platformOf(t.tripData).isNotEmpty)
                        row('Platform', platformOf(t.tripData)),
                      row('Seats', (t.seatNumbers.toList()..sort()).join(', ')),
                      row('Passenger', t.passengerName),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: BL.tint,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(
                            'Show the QR code to the conductor when you get on the bus.',
                            style: TextStyle(
                                fontSize: 17, height: 1.4, color: BL.deep)),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'QR code for this ticket',
                      image: true,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: BL.hairline),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: QrImageView(
                            backgroundColor: Colors.white,
                            data: t.ticketId,
                            version: QrVersions.auto,
                            size: 200),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Ticket ID: ${t.shortId ?? firstChars(t.ticketId, 8)}',
                        style: TextStyle(fontSize: 15, color: BL.muted)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: _TicketActions(ticket: t, tripData: t.tripData),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ shared bits
class _Chip {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  final bool done;
  const _Chip(this.label, this.bg, this.fg, this.icon, {this.done = false});
}

/// Status in words, with an icon and a colour (never colour alone).
_Chip _chip(Ticket t, DateTime dep, {Map<String, dynamic>? live}) {
  final data = live ?? t.tripData;
  final raw = (data['status'] ?? t.status).toString().toLowerCase();
  final delay = (data['delayMinutes'] ?? 0) as num;
  if (raw == 'cancelled') {
    return _Chip('Cancelled', BL.tint, BL.dangerInk, Icons.cancel_outlined);
  }
  if (raw == 'delayed' || delay > 0) {
    return _Chip(delay > 0 ? 'Late +${delay}m' : 'Delayed', BL.warnTint,
        BL.warnInk, Icons.schedule);
  }
  if (raw == 'completed' || raw == 'arrived') {
    return _Chip('Completed', BL.fill, BL.inkSoft, Icons.check, done: true);
  }
  if (raw == 'started' || raw == 'departed') {
    return _Chip('Active', BL.successTint, BL.successInk, Icons.directions_bus);
  }
  if (dep.isBefore(DateTime.now())) {
    return _Chip('Completed', BL.fill, BL.inkSoft, Icons.check, done: true);
  }
  return _Chip('Upcoming', BL.blush, BL.deep, Icons.event_available);
}

class _StatusChip extends StatelessWidget {
  final _Chip c;
  const _StatusChip(this.c);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(c.icon, size: 14, color: c.fg),
            const SizedBox(width: 4),
            Text(c.label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: c.fg)),
          ],
        ),
      );
}

/// View ticket, Track now and the quiet Refund link.
class _TicketActions extends StatelessWidget {
  final Ticket ticket;
  final Map<String, dynamic> tripData;
  const _TicketActions({required this.ticket, required this.tripData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dep = _depOf(ticket);
    final chip = _chip(ticket, dep, live: tripData);
    final raw = (tripData['status'] ?? ticket.status).toString().toLowerCase();
    final track = raw == 'started' ||
        raw == 'departed' ||
        chip.label.startsWith('Late') ||
        chip.label == 'Delayed' ||
        (dep.isAfter(DateTime.now()) &&
            dep.difference(DateTime.now()).inHours < 3 &&
            raw != 'cancelled');
    final refundable = raw != 'cancelled' &&
        raw != 'completed' &&
        raw != 'arrived' &&
        raw != 'refunded' &&
        dep.isAfter(DateTime.now());
    Trip trip() => Trip.fromMap(tripData, ticket.tripId);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TicketScreen(
                              ticketArg: ticket, tripArg: trip()))),
                  style: FilledButton.styleFrom(
                    backgroundColor: BL.crimson,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                  child: Text(l10n.viewTicket.toUpperCase()),
                ),
              ),
            ),
            if (track) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => pushDeferred(context,
                        load: tracking.loadLibrary,
                        build: () => tracking.TrackBusScreen(trip: trip())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BL.link,
                      side: const BorderSide(color: BL.crimson, width: 2),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    child: const Text('TRACK NOW'),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (refundable)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RefundRequestScreen(ticket: ticket, trip: trip()))),
              style: TextButton.styleFrom(
                  foregroundColor: BL.muted,
                  textStyle: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline)),
              child: Text(l10n.refund),
            ),
          ),
      ],
    );
  }
}

class BoardingPassCard extends StatelessWidget {
  final Ticket ticket;
  final bool shouldListen;
  const BoardingPassCard(
      {super.key, required this.ticket, this.shouldListen = true});

  @override
  Widget build(BuildContext context) {
    if (!shouldListen) return _card(context, ticket.tripData);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .doc(ticket.tripId)
          .snapshots(),
      builder: (context, snap) {
        final live = snap.data != null && snap.data!.exists
            ? snap.data!.data() as Map<String, dynamic>
            : ticket.tripData;
        return _card(context, live);
      },
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> data) {
    final dep = _depOf(ticket);
    final depLive = data['departureDateTime'] is Timestamp
        ? (data['departureDateTime'] as Timestamp).toDate()
        : dep;
    final st = _chip(ticket, depLive, live: data);
    final from =
        (data['fromCity'] ?? data['originCity'] ?? _fromOf(ticket)).toString();
    final to =
        (data['toCity'] ?? data['destinationCity'] ?? _toOf(ticket)).toString();
    final bus = (data['busNumber'] ?? '').toString();
    final seats = (ticket.seatNumbers.toList()..sort()).join(', ');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: BL.surface,
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
            height: 88,
            width: double.infinity,
            child: Image.asset(cityPhoto(to),
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.4),
                semanticLabel: to),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('$from to $to',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(st),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    '${DateFormat('EEE d MMM · hh:mm a').format(depLive)}${bus.isEmpty ? '' : ' · Bus $bus'} · Seats $seats',
                    style: TextStyle(fontSize: 16, color: BL.muted)),
                const SizedBox(height: 14),
                _TicketActions(ticket: ticket, tripData: data),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkBoardingPassCard extends StatelessWidget {
  final List<Ticket> tickets;
  const _BulkBoardingPassCard({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const SizedBox.shrink();
    final sorted = [...tickets]..sort((a, b) => _depOf(a).compareTo(_depOf(b)));
    final first = sorted.first;
    final last = sorted.last;
    final total = sorted.fold(0.0, (p, t) => p + t.totalAmount);
    final fmt = DateFormat('d MMM');
    final range = fmt.format(_depOf(first)) == fmt.format(_depOf(last))
        ? fmt.format(_depOf(first))
        : '${fmt.format(_depOf(first))} to ${fmt.format(_depOf(last))}';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: BL.surface,
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
            height: 88,
            width: double.infinity,
            child: Image.asset(cityPhoto(_toOf(first)),
                fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_fromOf(first)} to ${_toOf(first)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    '${sorted.length} trips · $range · LKR ${NumberFormat('#,###').format(total)}',
                    style: TextStyle(fontSize: 16, color: BL.muted)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketScreen(
                          ticketsArg: sorted,
                          tripArg: Trip.fromMap(first.tripData, first.tripId),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('View All Tickets & Download PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BL.link,
                      side: const BorderSide(color: BL.crimson, width: 2),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17,
                          fontWeight: FontWeight.w800),
                    ),
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
