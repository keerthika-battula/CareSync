// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadBytesInBrowser(List<int> bytes, String fileName, {String? mimeType}) {
  final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void openBytesInBrowser(List<int> bytes, {String? mimeType}) {
  final blob = html.Blob([bytes], mimeType ?? 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
