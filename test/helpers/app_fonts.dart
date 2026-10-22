import 'dart:io';
import 'package:flutter/services.dart';

/// Loads the app's bundled fonts so widget tests lay text out with realistic
/// widths (Flutter's default test font makes every letter a full-width box).
Future<void> loadAppFonts() async {
  const fonts = {
    'Outfit': 'assets/fonts/Outfit-Variable.ttf',
    'Inter': 'assets/fonts/Inter-Variable.ttf',
    'Montserrat': 'assets/fonts/Montserrat/Montserrat-VariableFont_wght.ttf',
  };
  for (final entry in fonts.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) continue;
    final loader = FontLoader(entry.key)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }
}
