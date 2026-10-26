import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../models/trip_view_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/bl_colors.dart';
import '../widgets/motion.dart';
import '../booking/bulk_confirmation_screen.dart';
import '../booking/bulk_quantity_dialog.dart';
import '../booking/seat_selection_screen.dart';
import 'bus_details_screen.dart';
import '../home/home_sections.dart' show cityPhoto;
import '../layout/app_footer.dart';
import '../layout/desktop_navbar.dart';
import '../widgets/animated_favorite_button.dart';

/// "Choose a bus" (mockups "Results" and "Desktop-Results").
class BusListScreen extends StatefulWidget {
  const BusListScreen({super.key});

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  String _sortBy = 'price_asc';
  final Set<String> _times = {'morning', 'afternoon', 'evening'};
  final Set<String> _types = {};
  bool _hideFull = false;

  static bool _isFull(EnrichedTrip t) =>
      t.totalSeats - t.bookedSeats.length <= 0 ||
      t.status.toLowerCase() == 'cancelled';

  List<EnrichedTrip> _visible(TripController c) {
    final all = List<EnrichedTrip>.from(c.searchResults);
    final types = _types.isEmpty ? all.map((t) => t.busType).toSet() : _types;
    final out = all.where((t) {
      final h = t.departureTime.hour;
      final slot = h < 12 ? 'morning' : (h < 18 ? 'afternoon' : 'evening');
      if (!_times.contains(slot)) return false;
      if (!types.contains(t.busType)) return false;
      if (_hideFull && _isFull(t)) return false;
      return true;
    }).toList();
    // Buses you can book come first, full ones sink to the bottom.
    out.sort((a, b) {
      if (_isFull(a) != _isFull(b)) return _isFull(a) ? 1 : -1;
      return _sortBy == 'time_asc'
          ? a.departureTime.compareTo(b.departureTime)
          : a.price.compareTo(b.price);
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final trips = _visible(c);
    return Scaffold(
      backgroundColor: BL.surface,
      body: isDesktop ? _desktop(c, trips) : _phone(c, trips),
    );
  }

  String _title(TripController c) => '${c.fromCity ?? ''} to ${c.toCity ?? ''}';

  // --------------------------------------------------------------- phone
  Widget _phone(TripController c, List<EnrichedTrip> trips) {
    final date = c.travelDate;
    return Column(
      children: [
        _Banner(
          height: 124 + MediaQuery.paddingOf(context).top - 24,
          photo: cityPhoto(c.toCity),
          horizontal: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                8, MediaQuery.paddingOf(context).top + 2, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Go back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  iconSize: 24,
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title(c),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      if (date != null)
                        Text(DateFormat('EEEE, d MMM').format(date),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_countText(trips.length),
                        style: TextStyle(fontSize: 16, color: BL.muted)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showFilterSheet,
                    icon: const Icon(Icons.tune),
                    label: const Text('Narrow it down'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: BL.link,
                      side: BorderSide(color: BL.border, width: 1.5),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._cards(c, trips),
            ],
          ),
        ),
      ],
    );
  }

  String _countText(int n) => n == 1 ? '1 bus found' : '$n buses found';

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BL.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: _filters(onChanged: () {
              setState(() {});
              setSheet(() {});
            }),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- desktop
  Widget _desktop(TripController c, List<EnrichedTrip> trips) {
    final date = c.travelDate;
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: DesktopNavBar()),
        SliverToBoxAdapter(
          child: _Banner(
            photo: cityPhoto(c.toCity),
            horizontal: true,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (date != null)
                              Text(DateFormat('EEEE, d MMMM yyyy').format(date),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(_title(c),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                                c.isLoading
                                    ? 'Looking for buses...'
                                    : _countText(trips.length),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Change search'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 56),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 280,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: BL.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: BL.hairline),
                        ),
                        child: _filters(onChanged: () => setState(() {})),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _sortMenu(),
                          ),
                          const SizedBox(height: 8),
                          ..._cards(c, trips),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Align(alignment: Alignment.bottomCenter, child: AppFooter()),
        ),
      ],
    );
  }

  Widget _sortMenu() => DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          style: TextStyle(fontSize: 17, color: BL.ink),
          icon: const Icon(Icons.expand_more),
          items: const [
            DropdownMenuItem(value: 'price_asc', child: Text('Cheapest first')),
            DropdownMenuItem(value: 'time_asc', child: Text('Earliest first')),
          ],
          onChanged: (v) => setState(() => _sortBy = v!),
        ),
      );

  List<Widget> _cards(TripController c, List<EnrichedTrip> trips) {
    if (c.isLoading) {
      return const [
        BusCardSkeleton(),
        SizedBox(height: 16),
        BusCardSkeleton(),
        SizedBox(height: 16),
        BusCardSkeleton(),
      ];
    }
    if (trips.isEmpty) {
      final hidden = c.searchResults.length;
      return [
        _NoBuses(
          // A new search starts a new look-up.
          key: ValueKey('${c.fromCity}|${c.toCity}|${c.travelDate}'),
          controller: c,
          hiddenByFilters: hidden,
          onShowAll: () => setState(() {
            _times
              ..clear()
              ..addAll({'morning', 'afternoon', 'evening'});
            _types.clear();
            _hideFull = false;
          }),
        ),
      ];
    }
    return [
      for (var i = 0; i < trips.length; i++) ...[
        // Each card arrives a moment after the one above it, and gets its own
        // layer so a live seat count changing does not redraw the others.
        RepaintBoundary(
          child: FadeInUp(
            key: ValueKey(trips[i].trip.id),
            delay: Duration(milliseconds: 50 * (i < 8 ? i : 8)),
            child: BusTicketCard(trip: trips[i]),
          ),
        ),
        const SizedBox(height: 16),
      ]
    ];
  }

  // ------------------------------------------------------------- filters
  Widget _filters({required VoidCallback onChanged}) {
    final types = <String>{
      for (final t in context.read<TripController>().searchResults)
        if (t.busType.isNotEmpty) t.busType
    };
    Widget box(String label, bool value, ValueChanged<bool> set) => InkWell(
          onTap: () {
            set(!value);
            onChanged();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 26, color: value ? BL.link : BL.muted),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label, style: const TextStyle(fontSize: 17))),
              ],
            ),
          ),
        );
    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(t,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        );
    void toggle(Set<String> s, String v, bool on) =>
        on ? s.add(v) : s.remove(v);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Narrow it down',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        heading('When do you want to leave?'),
        box('Morning (before 12 noon)', _times.contains('morning'),
            (v) => toggle(_times, 'morning', v)),
        box('Afternoon', _times.contains('afternoon'),
            (v) => toggle(_times, 'afternoon', v)),
        box('Evening and night', _times.contains('evening'),
            (v) => toggle(_times, 'evening', v)),
        if (types.length > 1) ...[
          const SizedBox(height: 18),
          heading('Type of bus'),
          for (final t in types)
            box(t, _types.isEmpty || _types.contains(t), (v) {
              if (_types.isEmpty) _types.addAll(types);
              toggle(_types, t, v);
              if (_types.length == types.length) _types.clear();
            }),
        ],
        const SizedBox(height: 18),
        box('Hide full buses', _hideFull, (v) => _hideFull = v),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String photo;
  final Widget child;
  final bool horizontal;
  final double? height;
  const _Banner(
      {required this.photo,
      required this.child,
      required this.horizontal,
      this.height});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(photo,
              fit: BoxFit.cover, alignment: const Alignment(0, -0.3)),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xEB460405), Color(0x99960E12)],
              ),
            ),
          ),
        ),
        SizedBox(height: height, width: double.infinity, child: child),
      ],
    );
  }
}

/// "3h 15m". Never "0h 5m" noise for short hops, never negative.
String busDuration(Duration d) {
  final mins = d.inMinutes < 0 ? 0 : d.inMinutes;
  final h = mins ~/ 60;
  final m = mins % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// How the "seats left" line should look.
enum SeatsLevel { plenty, few, none }

SeatsLevel seatsLevel(int left) => left <= 0
    ? SeatsLevel.none
    : (left <= 5 ? SeatsLevel.few : SeatsLevel.plenty);

class BusTicketCard extends StatefulWidget {
  final EnrichedTrip trip;
  const BusTicketCard({super.key, required this.trip});

  @override
  State<BusTicketCard> createState() => _BusTicketCardState();
}

class _BusTicketCardState extends State<BusTicketCard> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    // Live seat counts: merge the newest trip from the database.
    return StreamBuilder<Trip>(
      stream: Provider.of<FirestoreService>(context, listen: false)
          .getTripStream(widget.trip.id),
      builder: (context, snapshot) {
        var trip = widget.trip;
        if (snapshot.hasData) {
          trip = EnrichedTrip(
              trip: snapshot.data!,
              schedule: widget.trip.schedule,
              route: widget.trip.route);
        }
        final left = trip.totalSeats - trip.bookedSeats.length;
        final cancelled = trip.status.toLowerCase() == 'cancelled';
        if (cancelled || left <= 0) return _unavailable(trip, cancelled);
        return LayoutBuilder(
          builder: (context, box) =>
              _available(trip, controller, left, wide: box.maxWidth >= 640),
        );
      },
    );
  }

  Widget _unavailable(EnrichedTrip trip, bool cancelled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: BL.fill, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_operator(trip),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BL.muted)),
              ),
              Text(DateFormat('h:mm a').format(trip.departureTime),
                  style: TextStyle(fontSize: 16, color: BL.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(cancelled ? Icons.cancel_outlined : Icons.block,
                  size: 22, color: BL.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    cancelled
                        ? 'This trip is cancelled. Please choose another bus.'
                        : 'This bus is full. Please choose another one.',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: BL.ink)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _operator(EnrichedTrip t) =>
      t.operatorName.isEmpty ? 'BusLink Operator' : t.operatorName;

  Widget _available(EnrichedTrip trip, TripController c, int left,
      {required bool wide}) {
    final level = seatsLevel(left);
    final duration = trip.arrivalTime.difference(trip.departureTime);
    final bus = [
      if (trip.busType.isNotEmpty) trip.busType,
      if (trip.busNumber.isNotEmpty) trip.busNumber,
    ].join(' · ');
    final late = trip.delayMinutes > 0
        ? 'Running ${trip.delayMinutes} minutes late'
        : (trip.status.toLowerCase() == 'delayed' ? 'Delayed' : null);
    final total =
        c.isBulkBooking ? trip.price * c.bulkDates.length : trip.price;
    final price = 'LKR ${NumberFormat('#,###').format(total)}';

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_operator(trip),
            style: TextStyle(
                fontSize: wide ? 22 : 18, fontWeight: FontWeight.w700)),
        if (bus.isNotEmpty)
          Text(bus,
              style: TextStyle(fontSize: wide ? 17 : 16, color: BL.muted)),
        if (trip.via.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('via ${trip.via}',
                style: TextStyle(fontSize: 15, color: BL.muted)),
          ),
        if (late != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: BL.warnTint, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 22, color: BL.warnInk),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(late,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: BL.warnInk)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    Widget stop(String label, DateTime t, CrossAxisAlignment a) => Column(
          crossAxisAlignment: a,
          children: [
            Text(label,
                style: TextStyle(fontSize: wide ? 15 : 14, color: BL.muted)),
            Text(DateFormat('hh:mm a').format(t),
                style: TextStyle(
                    fontSize: wide ? 26 : 20, fontWeight: FontWeight.w700)),
          ],
        );
    final detailsLink = TextButton(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => BusDetailsScreen(trip: trip))),
      style: TextButton.styleFrom(
          foregroundColor: BL.link,
          minimumSize: const Size(0, 48),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
              fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700)),
      child: const Text('Stops and what is on the bus'),
    );
    final times = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        stop('Leaves', trip.departureTime, CrossAxisAlignment.start),
        Column(
          children: [
            Text(busDuration(duration),
                style: TextStyle(fontSize: wide ? 15 : 14, color: BL.muted)),
            const SizedBox(height: 4),
            Container(width: wide ? 64 : 56, height: 2, color: BL.border),
          ],
        ),
        stop('Arrives', trip.arrivalTime, CrossAxisAlignment.end),
      ],
    );

    final fewColor = BL.dangerInk;
    final seats = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(level == SeatsLevel.few ? Icons.error_outline : Icons.check,
            size: 20, color: level == SeatsLevel.few ? fewColor : BL.success),
        const SizedBox(width: 6),
        Text(
            level == SeatsLevel.few
                ? 'Only $left seats left'
                : '$left seats left',
            style: TextStyle(
                fontSize: 16,
                fontWeight:
                    level == SeatsLevel.few ? FontWeight.w700 : FontWeight.w500,
                color: level == SeatsLevel.few ? fewColor : BL.success)),
      ],
    );

    final book = SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: () => _book(trip, c),
        style: FilledButton.styleFrom(
          backgroundColor: BL.crimson,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
              fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: const Text('Book Now'),
      ),
    );

    final fav = FutureBuilder<bool>(
      future: c.isRouteFavorite(trip.originCity, trip.destinationCity),
      builder: (context, snap) => AnimatedFavoriteButton(
        isFavorite: snap.data ?? false,
        onToggle: () async {
          await c.toggleFavorite(trip);
          if (mounted) setState(() {});
        },
      ),
    );

    final priceText = Text(price,
        style: TextStyle(
            fontSize: wide ? 26 : 20,
            fontWeight: FontWeight.w700,
            color: BL.link));

    return Container(
      padding: EdgeInsets.all(wide ? 22 : 16),
      decoration: BoxDecoration(
        color: BL.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A660708), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    flex: 4,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [head, detailsLink])),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: times),
                const SizedBox(width: 20),
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [fav, const SizedBox(width: 4), priceText],
                      ),
                      const SizedBox(height: 8),
                      seats,
                      const SizedBox(height: 8),
                      book,
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: head),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [priceText, fav],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                times,
                const SizedBox(height: 4),
                detailsLink,
                seats,
                const SizedBox(height: 12),
                book,
              ],
            ),
    );
  }

  void _book(EnrichedTrip trip, TripController controller) {
    void say(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 4)));
    if (trip.departureTime.difference(DateTime.now()).inMinutes <= 10) {
      say('Booking closes 10 minutes before departure');
    } else if (controller.isBulkBooking) {
      showDialog(
        context: context,
        builder: (context) => BulkQuantityDialog(
          trip: trip.trip,
          days: controller.bulkDates.length,
          onConfirm: (qty) {
            Navigator.pop(context);
            controller.selectedSeats = List.generate(qty, (index) => '-1');
            controller.selectedTrip = trip;
            controller.setBulkPassengers(qty);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BulkConfirmationScreen(trip: trip)));
          },
        ),
      );
    } else {
      controller.selectTrip(trip);
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => SeatSelectionScreen(trip: trip)));
    }
  }
}

/// Says why a search found nothing, and what to do next.
class _NoBuses extends StatefulWidget {
  final TripController controller;
  final int hiddenByFilters;
  final VoidCallback onShowAll;
  const _NoBuses(
      {super.key,
      required this.controller,
      required this.hiddenByFilters,
      required this.onShowAll});

  @override
  State<_NoBuses> createState() => _NoBusesState();
}

class _NoBusesState extends State<_NoBuses> {
  late final Future<Map<DateTime, int>> _days = widget.hiddenByFilters > 0
      ? Future.value(const {})
      : widget.controller.upcomingDaysForRoute();

  bool _knownCity(String? name) {
    final cities = widget.controller.availableCities;
    if (cities.isEmpty || name == null) return true; // cannot tell: assume yes
    return cities.any((c) => c.toLowerCase() == name.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final from = c.fromCity ?? '', to = c.toCity ?? '';
    final date = c.travelDate;
    final today = DateTime.now();
    final isToday = date != null &&
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final cities = c.availableCities;

    final String title;
    final String reason;
    if (widget.hiddenByFilters > 0) {
      title = widget.hiddenByFilters == 1
          ? 'Your choices hide 1 bus'
          : 'Your choices hide ${widget.hiddenByFilters} buses';
      reason =
          'There are buses on this day, but not at the times or types you picked.';
    } else if (!_knownCity(from) || !_knownCity(to)) {
      final unknown = !_knownCity(from) ? from : to;
      title = 'We do not run buses to or from "$unknown" yet';
      reason = cities.isEmpty
          ? 'Check the spelling, or pick a city from the list on the home page.'
          : 'Pick one of these cities: ${cities.join(', ')}.';
    } else {
      title = date == null
          ? 'No buses from $from to $to'
          : 'No buses from $from to $to on ${DateFormat('EEE d MMM').format(date)}';
      reason = isToday
          ? 'Buses that have already left today are not shown. Try another day:'
          : 'Nothing is planned for that day. Try another day:';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.directions_bus_outlined, size: 64, color: BL.border),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: BL.ink)),
        const SizedBox(height: 6),
        Text(reason,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: BL.muted)),
        const SizedBox(height: 18),
        if (widget.hiddenByFilters > 0)
          FilledButton(
            onPressed: widget.onShowAll,
            style: FilledButton.styleFrom(
                backgroundColor: BL.crimson,
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            child: const Text('Show all buses'),
          )
        else if (_knownCity(from) && _knownCity(to))
          FutureBuilder<Map<DateTime, int>>(
            future: _days,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: BL.crimson));
              }
              final days = snap.data ?? const <DateTime, int>{};
              if (days.isEmpty) {
                return Text(
                    'There are no buses on this route in the next two weeks. Try a different route.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, color: BL.muted));
              }
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in days.entries.take(8))
                    ActionChip(
                      onPressed: () => widget.controller.searchAgainOn(e.key),
                      avatar: Icon(Icons.event, size: 20, color: BL.link),
                      label: Text(
                          '${DateFormat('EEE d MMM').format(e.key)} · ${e.value} ${e.value == 1 ? 'bus' : 'buses'}'),
                      labelStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      backgroundColor: BL.blush,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                    ),
                ],
              );
            },
          ),
      ]),
    );
  }
}
