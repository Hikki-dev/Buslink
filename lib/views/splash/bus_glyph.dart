import 'package:flutter/material.dart';

/// The BusLink bus, drawn the same way as the logo in web/index.html:
/// a rounded white body with a window, two lights, a bumper bar and two feet.
class BusGlyph extends StatelessWidget {
  const BusGlyph({
    super.key,
    required this.size,
    required this.body,
    required this.cutout,
  });

  final double size;

  /// The colour of the body and feet.
  final Color body;

  /// The colour of the window and lights (the tile behind the glyph).
  final Color cutout;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _BusGlyphPainter(body, cutout),
      );
}

class _BusGlyphPainter extends CustomPainter {
  _BusGlyphPainter(this.body, this.cutout);

  final Color body;
  final Color cutout;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 100 x 100 grid, then scaled to fit.
    canvas.scale(size.width / 100, size.height / 100);
    final fill = Paint()..color = body;
    final hole = Paint()..color = cutout;
    RRect r(double x, double y, double w, double h, double radius) =>
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h), Radius.circular(radius));

    canvas.drawRRect(r(24, 20, 52, 56, 11), fill);
    canvas.drawRRect(r(31, 28, 38, 24, 5), hole);
    canvas.drawCircle(const Offset(37, 63), 5, hole);
    canvas.drawCircle(const Offset(63, 63), 5, hole);
    canvas.drawRRect(r(40, 56, 20, 4, 2), hole);
    canvas.drawRRect(r(29, 76, 10, 8, 2), fill);
    canvas.drawRRect(r(61, 76, 10, 8, 2), fill);
  }

  @override
  bool shouldRepaint(_BusGlyphPainter old) =>
      old.body != body || old.cutout != cutout;
}
