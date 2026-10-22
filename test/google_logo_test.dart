import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled Google "G" is a real, square, non-empty image', () async {
    final bytes = (await rootBundle.load('assets/images/google_g.png'))
        .buffer
        .asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    expect(image.width, image.height);
    expect(image.width, greaterThanOrEqualTo(96));
  });
}
