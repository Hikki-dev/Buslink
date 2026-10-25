import 'dart:io';
import 'package:flutter/services.dart';

/// Loads the app's bundled fonts so widget tests lay text out with realistic
/// widths and weights (Flutter's default test font makes every letter a
/// full-width box). Each file knows its own weight, so a family can load them all.
Future<void> loadAppFonts() async {
  const fonts = {
    'Outfit': [
      'assets/fonts/Outfit/Outfit-Light.ttf',
      'assets/fonts/Outfit/Outfit-Regular.ttf',
      'assets/fonts/Outfit/Outfit-Medium.ttf',
      'assets/fonts/Outfit/Outfit-SemiBold.ttf',
      'assets/fonts/Outfit/Outfit-Bold.ttf',
      'assets/fonts/Outfit/Outfit-ExtraBold.ttf',
    ],
    'Montserrat': [
      'assets/fonts/Montserrat/Montserrat-Regular.ttf',
      'assets/fonts/Montserrat/Montserrat-Bold.ttf',
    ],
    'Cormorant': ['assets/fonts/Cormorant/Cormorant-Bold.ttf'],
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) continue;
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }
}
