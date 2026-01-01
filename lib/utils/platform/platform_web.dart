// lib/utils/platform/platform_web.dart
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

void removeSpinner() {
  try {
    final loader = web.document.getElementById('loading-indicator');
    if (loader != null) {
      loader.remove();
      debugPrint("Deleted HTML Spinner via Dart");
    }
  } catch (e) {
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
