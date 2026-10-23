import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart';
import '../../utils/bl_colors.dart';
import '../booking/seat_selection_screen.dart';
import '../home/home_sections.dart' show cityPhoto;
import '../widgets/bl_widgets.dart';
import 'bus_list_screen.dart' show busDuration;

/// "Bus details" (mockup "BusDetails"): times, what is on the bus, the stops.
class BusDetailsScreen extends StatelessWidget {
  final EnrichedTrip trip;
  const BusDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final time = DateFormat('hh:mm a');
    final bus = [
      if (trip.busType.isNotEmpty) trip.busType,
      if (trip.busNumber.isNotEmpty) trip.busNumber,
    ].join(' · ');
    final between = trip.stops
        .where((s) =>
            s.toLowerCase() != trip.fromCity.toLowerCase() &&
            s.toLowerCase() != trip.toCity.toLowerCase())
        .toList();

    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        );
    Widget stopRow(Widget dot, String label) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(children: [
            dot,
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
          ]),
        );
    Widget stat(String label, String value, String sub, CrossAxisAlignment a) =>
        Column(crossAxisAlignment: a, children: [
          Text(label, style: const TextStyle(fontSize: 14, color: BL.muted)),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(sub, style: const TextStyle(fontSize: 15, color: BL.muted)),
        ]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 170 + top - 24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(cityPhoto(trip.toCity),
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -0.4)),
                        ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x8C460405), Color(0xEB660708)],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(8, top + 2, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                tooltip: 'Go back',
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white),
                                constraints: const BoxConstraints(
                                    minWidth: 48, minHeight: 48),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(trip.operatorName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w800)),
                                          if (bus.isNotEmpty)
                                            Text(bus,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 17)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        'LKR ${NumberFormat('#,###').format(trip.price)}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: blCard(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  stat(
                                      'Depart',
                                      time.format(trip.departureTime),
                                      trip.fromCity,
                                      CrossAxisAlignment.start),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(children: [
                                      Text(
                                          busDuration(trip.arrivalTime
                                              .difference(trip.departureTime)),
                                          style: const TextStyle(
                                              fontSize: 14, color: BL.muted)),
                                      const SizedBox(height: 4),
                                      Container(
                                          width: 44,
                                          height: 2,
                                          color: BL.border),
                                    ]),
                                  ),
                                  Flexible(
                                    child: stat(
                                        'Arrive',
                                        time.format(trip.arrivalTime),
                                        trip.toCity,
                                        CrossAxisAlignment.end),
                                  ),
                                ],
                              ),
                            ),
                            if (trip.amenities.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              heading('On this bus'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final a in trip.amenities)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFFDEEEE),
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                      child: Text(a,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: BL.crimsonDark)),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 18),
                            heading('Stops on the way'),
                            stopRow(
                                Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                        color: BL.crimsonDark,
                                        shape: BoxShape.circle)),
                                trip.fromCity),
                            if (between.isNotEmpty)
                              stopRow(
                                  Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: BL.crimson, width: 3))),
                                  between.join(' · ')),
                            stopRow(
                                Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                        color: BL.ink, shape: BoxShape.circle)),
                                trip.toCity),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: BL.hairline))),
            child: BlPrimaryButton(
              label: 'Choose seats',
              color: BL.crimson,
              onTap: () {
                context.read<TripController>().selectTrip(trip);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SeatSelectionScreen(trip: trip)));
              },
            ),
          ),
        ],
      ),
    );
  }
}
