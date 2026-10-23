import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'splash_screen.dart' show SplashColors;

/// Draws the small road on the start-up screen: a dotted road from Colombo to
/// Kandy to Ella, a red line that fills in behind the bus, three stops that
/// light up as the bus reaches them, and the bus itself.
///
/// It is a straight copy of the SVG in web/index.html, so the page splash and
/// the app splash look the same. Everything is a pure function of [cycle].
class RoutePainter extends CustomPainter {
  RoutePainter({required this.colors, required this.cycle, this.still = false});

  final SplashColors colors;

  /// 0..1 through the current journey, or null before the first one starts.
  final double? cycle;

  /// Hold the picture still: the bus parked at Kandy, two stops lit.
  final bool still;

  // The drawing is on a 260 x 120 grid.
  static const _w = 260.0;
  static const _h = 120.0;
  static final Path _road = Path()
    ..moveTo(16, 90)
    ..cubicTo(62, 90, 70, 36, 124, 44)
    ..cubicTo(178, 52, 196, 94, 244, 28);
  static final ui.PathMetric _metric = _road.computeMetrics().first;
  static final double _kandy = (Path()
            ..moveTo(16, 90)
            ..cubicTo(62, 90, 70, 36, 124, 44))
          .computeMetrics()
          .first
          .length /
      _metric.length;

  /// How far along the road Kandy is (0..1). About 0.47.
  static double get kandyFraction => _kandy;

  /// The bus travels for the first 85% of a journey and rests for the rest.
  static const _drive = 0.85;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _w, size.height / _h);
    final len = _metric.length;
    final c = cycle;

    // 1. The dotted road: a dot every 12 units.
    final dots = Paint()..color = colors.road;
    for (double d = 0; d <= len; d += 12) {
      canvas.drawCircle(_metric.getTangentForOffset(d)!.position, 2.5, dots);
    }

    // How far the bus has got (0..1 of the road) and how visible the trail is.
    double reached;
    double trailOpacity = 1;
    if (still) {
      reached = _kandy;
    } else if (c == null) {
      reached = 0;
      trailOpacity = 0;
    } else {
      reached = (c / _drive).clamp(0.0, 1.0);
      trailOpacity = c < 0.94 ? 1 : (1 - (c - 0.94) / 0.06).clamp(0.0, 1.0);
    }

    // 2. The red trail behind the bus.
    if (reached > 0 && trailOpacity > 0) {
      canvas.drawPath(
        _metric.extractPath(0, len * reached),
        Paint()
          ..color = colors.accent.withValues(alpha: trailOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }

    // 3. The three stops.
    void stop(Offset at, double lit) {
      canvas.drawCircle(at, 8, Paint()..color = colors.stop);
      canvas.drawCircle(
        at,
        8,
        Paint()
          ..color = colors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      if (lit > 0) {
        canvas.drawCircle(at, 4.5 * lit, Paint()..color = colors.accent);
      }
    }

    stop(const Offset(16, 90), still ? 1 : _lit(c, null, null));
    stop(const Offset(124, 44), still ? 1 : _lit(c, 0.39, 0.48));
    stop(const Offset(244, 28), still ? 0 : _lit(c, 0.83, 0.91));

    // 4. The names of the stops.
    _label(canvas, 'Colombo', const Offset(16, 116));
    _label(canvas, 'Kandy', const Offset(124, 72));
    _label(canvas, 'Ella', const Offset(244, 54));

    // 5. The bus.
    final busOpacity = still
        ? 1.0
        : c == null
            ? 0.0
            : c < 0.03
                ? c / 0.03
                : c < 0.92
                    ? 1.0
                    : (1 - (c - 0.92) / 0.08).clamp(0.0, 1.0);
    if (busOpacity > 0) {
      final t = _metric.getTangentForOffset(len * reached)!;
      canvas.save();
      canvas.translate(t.position.dx, t.position.dy);
      canvas.rotate(still ? 0.14 : -t.angle);
      _bus(canvas, busOpacity);
      canvas.restore();
    }
    canvas.restore();
  }

  /// The size (0..1.3) of a stop's red centre at this point in the journey.
  /// A stop pops up when the bus arrives, settles, and clears when the journey
  /// ends. [from] is where it starts to pop and [settle] where it has settled;
  /// both null means "lit from the very start" (Colombo).
  static double _lit(double? c, double? from, double? settle) {
    if (c == null) return 0;
    double fade(double v) => c < 0.94 ? v : v * (1 - (c - 0.94) / 0.06);
    if (from == null || settle == null) return fade(1);
    if (c < from) return 0;
    final peak = from + (settle - from) * 0.55;
    if (c < peak) return 1.3 * (c - from) / (peak - from);
    if (c < settle) return 1.3 - 0.3 * (c - peak) / (settle - peak);
    return fade(1);
  }

  void _label(Canvas canvas, String text, Offset baseline) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.muted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // SVG text sits on its baseline, so lift the box by the baseline height.
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(baseline.dx - tp.width / 2, baseline.dy - ascent));
  }

  void _bus(Canvas canvas, double opacity) {
    final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -10, 26, 15), const Radius.circular(4.5));
    canvas.drawRRect(body,
        Paint()..color = const Color(0xFFBA181B).withValues(alpha: opacity));
    canvas.drawRRect(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -7, 14, 6), const Radius.circular(1.8)),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    final wheel = Paint()
      ..color = const Color(0xFF660708).withValues(alpha: opacity);
    canvas.drawCircle(const Offset(-6, 6), 2.8, wheel);
    canvas.drawCircle(const Offset(6, 6), 2.8, wheel);
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      old.cycle != cycle || old.still != still || old.colors != colors;
}
