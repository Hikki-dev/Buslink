// lib/utils/platform/platform_utils.dart
import 'platform_stub.dart' if (dart.library.html) 'platform_web.dart';

void removeWebSpinner() => removeSpinner();

String getPlatformLanguage() => getLanguage();
