import 'dart:typed_data';
import 'file_downloader_stub.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart';

/// Cross-platform wrapper
Future<void> downloadBytesForWeb(Uint8List bytes, String fileName) async {
  await downloadFileWeb(bytes, fileName);
}
