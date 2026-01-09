// lib/utils/platform/platform_web.dart
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

void removeSpinner() {
  try {
    final loader = web.document.getElementById('loading-indicator');
    if (loader != null) {
      // Check if it's attached to the DOM before removing to avoid edge cases
      // "Cannot read properties of null (reading 'removeChild')" happens if parent is null.
      if (loader.parentNode != null) {
        loader.remove();
        debugPrint("Deleted HTML Spinner via Dart");
      } else {
        debugPrint("HTML Spinner already detached (parentNode is null)");
      }
    }
  } catch (e) {
    // Explicitly catch everything to prevent app crash
    debugPrint("HTML Element removal warning: $e");
  }
}

String getLanguage() {
  try {
    return web.window.navigator.language.split('-')[0];
  } catch (e) {
    return 'en';
  }
}
