import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Web implementation using package:web
Future<void> downloadFileWeb(Uint8List bytes, String fileName) async {
  final blob =
      web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf'));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();

  // Small delay to ensure browser acknowledges the download
  await Future.delayed(const Duration(milliseconds: 100));

  anchor.remove();
  web.URL.revokeObjectURL(url);
}
