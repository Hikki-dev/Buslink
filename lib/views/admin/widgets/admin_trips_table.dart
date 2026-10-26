import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../controllers/trip_controller.dart';
import '../../../models/trip_model.dart';
import '../../../models/trip_view_model.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/bl_colors.dart';
import '../../home/home_sections.dart' show cityPhoto;

/// "Upcoming trips" table (mockup "Desktop-Admin"): every trip passengers can
/// still book in the next 30 days, with Edit, Seats and Delete.
class AdminTripsTable extends StatefulWidget {
  final void Function(EnrichedTrip trip) onEdit;
  final void Function(Trip trip) onSeats;
  const AdminTripsTable(
      {super.key, required this.onEdit, required this.onSeats});

  @override
  State<AdminTripsTable> createState() => AdminTripsTableState();
}

class AdminTripsTableState extends State<AdminTripsTable> {
  late Future<List<EnrichedTrip>> _future = _load();

  Future<List<EnrichedTrip>> _load() async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final ctl = Provider.of<TripController>(context, listen: false);
    final now = DateTime.now();
    final trips = await fs.getTripsByDate(
        now.subtract(const Duration(hours: 6)),
        now.add(const Duration(days: 30)));
    final enriched = await ctl.enrichTrips(trips);
    enriched.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return enriched;
  }

  void reload() => setState(() => _future = _load());

  Future<void> _delete(EnrichedTrip t) async {
    final booked = t.bookedSeats.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this trip?'),
        content: Text(booked > 0
            ? '$booked seat${booked == 1 ? ' is' : 's are'} already booked on ${t.fromCity} to ${t.toCity}. Deleting it cannot be undone.'
            : 'Delete ${t.fromCity} to ${t.toCity}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: BL.dangerInk),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await Provider.of<TripController>(context, listen: false)
          .deleteTrip(t.id);
      reload();
    }
  }

  ({String label, IconData icon, Color bg, Color fg}) _status(EnrichedTrip t) {
    if (t.status.toLowerCase() == 'cancelled') {
      return (
        label: 'Cancelled',
        icon: Icons.close,
        bg: BL.tint,
        fg: BL.dangerInk
      );
    }
    if (t.delayMinutes > 0) {
      return (
        label: 'Late ${t.delayMinutes} min',
        icon: Icons.schedule,
        bg: BL.warnTint,
        fg: BL.warnInk
      );
    }
    if (t.bookedSeats.length >= t.totalSeats) {
      return (label: 'Full', icon: Icons.block, bg: BL.fill, fg: BL.inkSoft);
    }
    return (
      label: 'On time',
      icon: Icons.check,
      bg: BL.successTint,
      fg: BL.successInk
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EnrichedTrip>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: BL.crimson)),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              const Expanded(
                child: Text(
                    'We could not load the trips. Check the connection.',
                    style: TextStyle(fontSize: 17)),
              ),
              OutlinedButton(onPressed: reload, child: const Text('Try again')),
            ]),
          );
        }
        final trips = snap.data ?? [];
        if (trips.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(32),
            child: Text(
                'No upcoming trips yet. Tap "Add new trip" to create one.',
                style: TextStyle(fontSize: 18, color: BL.muted)),
          );
        }
        final head = TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: BL.muted);
        Widget cell(Widget c, int flex) => Expanded(flex: flex, child: c);
        Widget headCell(String t, int flex) => cell(Text(t, style: head), flex);
        return Container(
          decoration: BoxDecoration(
            color: BL.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14660708),
                  blurRadius: 10,
                  offset: Offset(0, 2))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: BL.fill,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  headCell('Route', 4),
                  headCell('Leaves', 3),
                  headCell('Bus', 3),
                  headCell('Seats taken', 2),
                  headCell('Status', 3),
                  headCell('Actions', 4),
                ]),
              ),
              for (final t in trips)
                Builder(builder: (context) {
                  final st = _status(t);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: BL.fill))),
                    child: Row(children: [
                      cell(
                        Row(children: [
                          ClipOval(
                            child: Image.asset(cityPhoto(t.toCity),
                                width: 44, height: 44, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('${t.fromCity} to ${t.toCity}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        4,
                      ),
                      cell(
                          Text(
                              DateFormat('EEE d MMM, hh:mm a')
                                  .format(t.departureTime),
                              style: const TextStyle(fontSize: 16)),
                          3),
                      cell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.operatorName,
                                style: const TextStyle(fontSize: 16)),
                            Text(t.busNumber,
                                style:
                                    TextStyle(fontSize: 15, color: BL.muted)),
                          ],
                        ),
                        3,
                      ),
                      cell(
                          Text('${t.bookedSeats.length} of ${t.totalSeats}',
                              style: const TextStyle(fontSize: 16)),
                          2),
                      cell(
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: st.bg,
                                borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(st.icon, size: 16, color: st.fg),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(st.label,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: st.fg)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        3,
                      ),
                      cell(
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _btn('Edit', BL.ink, () => widget.onEdit(t)),
                          _btn('Seats', BL.ink, () => widget.onSeats(t.trip)),
                          _btn('Delete', BL.dangerInk, () => _delete(t)),
                        ]),
                        4,
                      ),
                    ]),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _btn(String label, Color c, VoidCallback onTap) => SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: c,
            side: BorderSide(color: c, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          child: Text(label),
        ),
      );
}
