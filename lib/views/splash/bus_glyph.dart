import 'package:flutter/material.dart';

/// The BusLink bus, drawn the same way as the logo in web/index.html:
/// a rounded white body with a window, two lights and two feet.
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
    // Drawn on a 64 x 64 grid, then scaled to fit.
    canvas.scale(size.width / 64, size.height / 64);
    final fill = Paint()..color = body;
    final hole = Paint()..color = cutout;
    RRect r(double x, double y, double w, double h, double radius) =>
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h), Radius.circular(radius));

    canvas.drawRRect(r(12, 8, 40, 42, 11), fill);
    canvas.drawRRect(r(17, 14, 30, 14, 4), hole);
    canvas.drawCircle(const Offset(22, 38), 3.6, hole);
    canvas.drawCircle(const Offset(42, 38), 3.6, hole);
    canvas.drawRRect(r(17, 49, 8, 9, 3), fill);
    canvas.drawRRect(r(39, 49, 8, 9, 3), fill);
  }

  @override
  bool shouldRepaint(_BusGlyphPainter old) =>
      old.body != body || old.cutout != cutout;
}
