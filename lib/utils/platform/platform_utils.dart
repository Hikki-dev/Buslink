// lib/utils/platform/platform_utils.dart
import 'platform_stub.dart' if (dart.library.html) 'platform_web.dart';

/// Fades out the splash that web/index.html draws while the app downloads.
/// Does nothing on phones and desktop, where Flutter draws its own splash.
void hideWebSplash() => hideSplash();

/// Tells the web splash that start-up is taking longer than usual, so it shows
/// the "still getting ready" message. Does nothing on phones and desktop.
void showWebSplashSlow() => showSplashSlow();

String getPlatformLanguage() => getLanguage();
