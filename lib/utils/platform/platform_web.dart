// lib/utils/platform/platform_web.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// The splash drawn by web/index.html (`#splash`). It covers the page from the
/// very first paint, so it is also what people see while the app downloads.
web.Element? get _splash => web.document.getElementById('splash');

/// Fades the splash out, then removes it. Safe to call more than once.
void hideSplash() {
  try {
    final splash = _splash;
    if (splash == null || splash.classList.contains('leaving')) return;
    splash.classList.add('leaving');
    // The fade is 450 ms (see web/index.html); remove it once it has finished.
    Timer(const Duration(milliseconds: 600), () {
      try {
        splash.remove();
      } catch (e) {
        debugPrint('Splash removal warning: $e');
      }
    });
  } catch (e) {
    // Never let a cosmetic step stop the app.
    debugPrint('Splash hide warning: $e');
  }
}

/// Switches the splash to its "still getting ready" message.
void showSplashSlow() {
  try {
    final splash = _splash;
    if (splash != null && splash.getAttribute('data-state') == 'loading') {
      splash.setAttribute('data-state', 'slow');
    }
  } catch (e) {
    debugPrint('Splash slow warning: $e');
  }
}

String getLanguage() {
  try {
    return web.window.navigator.language.split('-')[0];
  } catch (e) {
    return 'en';
  }
}
