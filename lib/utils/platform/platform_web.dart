// lib/utils/platform/platform_web.dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void removeSpinner() {
  try {
    final loader = html.document.getElementById('loading-indicator');
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
    return html.window.navigator.language.split('-')[0];
  } catch (e) {
    return 'en';
  }
}
