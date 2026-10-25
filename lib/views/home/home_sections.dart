// "Popular journeys" and "How it works" on the home screen (mockups "Main"
// and "Desktop-Home"). Prices and times come from the real routes and
// schedules; a place with no service yet simply shows no price.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/firestore_service.dart';
import '../../utils/bl_colors.dart';

class _Spot {
  final String city;
  final String photo;
  final String blurb;
  final String alt;
  const _Spot(this.city, this.photo, this.blurb, this.alt);
}

const _spots = [
  _Spot(
      'Kandy',
      'assets/images/home/kandy_temple.jpg',
      'Home of the Temple of the Tooth',
      'Inside the Temple of the Tooth, Kandy'),
  _Spot('Galle', 'assets/images/home/galle_fort.jpg', 'The old fort by the sea',
      'Galle Fort lighthouse at sunset'),
  _Spot('Nuwara Eliya', 'assets/images/home/nuwara_eliya_tea.jpg',
      'Cool hills and tea country', 'Tea hills near Nuwara Eliya'),
  _Spot('Polonnaruwa', 'assets/images/home/sigiriya_rock.jpg',
      'Close to Sigiriya rock', 'Sigiriya rock fortress'),
];

/// Photo for a city banner: the place's own photo, or the Ella train.
String cityPhoto(String? city) {
  for (final s in _spots) {
    if (s.city.toLowerCase() == (city ?? '').toLowerCase()) return s.photo;
  }
  return 'assets/images/home/ella_train.jpg';
}

String formatDuration(int mins) {
  if (mins <= 0) return '';
  final h = mins ~/ 60, m = mins % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

class PopularJourneys extends StatefulWidget {
  final bool isDesktop;
  final String origin;
  final ValueChanged<String> onPick;
  const PopularJourneys({
    super.key,
    required this.isDesktop,
    required this.onPick,
    this.origin = 'Colombo',
  });

  @override
  State<PopularJourneys> createState() => _PopularJourneysState();
}

class _PopularJourneysState extends State<PopularJourneys> {
  Map<String, JourneyHint> _hints = {};

  @override
  void initState() {
    super.initState();
    FirestoreService().getJourneyHints(widget.origin).then((h) {
      if (mounted) setState(() => _hints = h);
    });
  }

  String? _priceLine(String city) {
    final h = _hints[city];
    if (h == null) return null;
    final price = 'From LKR ${NumberFormat('#,###').format(h.fromPrice)}';
    final t = formatDuration(h.durationMins);
    return widget.isDesktop && t.isNotEmpty ? '$price · about $t' : price;
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Popular journeys from ${widget.origin}';
    if (!widget.isDesktop) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BL.ink)),
            ),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _spots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 150,
                  child: _SpotCard(
                    spot: _spots[i],
                    compact: true,
                    priceLine: _priceLine(_spots[i].city),
                    onTap: () => widget.onPick(_spots[i].city),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _DesktopSection(
      title: title,
      subtitle: 'Tap a place to see the buses for it.',
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          for (final s in _spots)
            _SpotCard(
              spot: s,
              compact: false,
              priceLine: _priceLine(s.city),
              onTap: () => widget.onPick(s.city),
            ),
        ].map((c) => SizedBox(width: 273, height: 340, child: c)).toList(),
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final _Spot spot;
  final bool compact;
  final String? priceLine;
  final VoidCallback onTap;
  const _SpotCard(
      {required this.spot,
      required this.compact,
      required this.priceLine,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buses to ${spot.city}${priceLine == null ? '' : ', $priceLine'}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(spot.photo,
                fit: BoxFit.cover,
                semanticLabel: spot.alt,
                cacheWidth: compact ? 450 : 800),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [compact ? 0.35 : 0.4, 1],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: compact ? 0.78 : 0.82)
                  ],
                ),
              ),
            ),
            Positioned(
              left: compact ? 12 : 20,
              right: compact ? 8 : 20,
              bottom: compact ? 10 : 18,
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(spot.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: compact ? 18 : 26,
                            fontWeight: FontWeight.w700)),
                    if (!compact)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(spot.blurb,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    if (priceLine != null)
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 0 : 8),
                        child: Text(priceLine!,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: compact ? 14 : 17,
                                fontWeight: compact
                                    ? FontWeight.w400
                                    : FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap)),
            ),
          ],
        ),
      ),
    );
  }
}

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  static const _steps = [
    (
      'Choose your trip',
      'Say where you are leaving from, where you are going, and which day.'
    ),
    (
      'Pick your seats',
      'See the bus layout and tap the seats you like. Taken seats are crossed out.'
    ),
    (
      'Show your ticket',
      'Open My tickets and show the QR code to the conductor when you board.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _DesktopSection(
      title: 'How it works',
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          for (var i = 0; i < _steps.length; i++)
            Container(
              width: 370,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BL.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BL.hairline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: BL.crimson, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_steps[i].$1,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: BL.ink)),
                        const SizedBox(height: 4),
                        Text(_steps[i].$2,
                            style: TextStyle(
                                fontSize: 17, height: 1.4, color: BL.muted)),
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

class _DesktopSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _DesktopSection(
      {required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: BL.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!,
                    style: TextStyle(fontSize: 18, color: BL.muted)),
              ],
              SizedBox(height: subtitle != null ? 24 : 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
