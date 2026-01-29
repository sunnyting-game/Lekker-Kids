import 'dart:convert';
// ignore: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation for file download.
/// Uses dart:html to trigger browser download.

void downloadFile(String content, String filename) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.AnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  
  html.document.body?.children.add(anchor);
  anchor.click();
  
  // Cleanup
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
