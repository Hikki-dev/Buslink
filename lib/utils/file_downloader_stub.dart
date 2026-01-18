import 'dart:typed_data';

/// Stub for non-web platforms (will be overridden by conditional import)
Future<void> downloadFileWeb(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Web download not supported on this platform');
}
