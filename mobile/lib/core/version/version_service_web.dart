// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'version_service.dart';

VersionService createVersionService() => VersionServiceWeb();

class VersionServiceWeb implements VersionService {
  @override
  Future<String?> fetchLatestBuildNumber() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = 'version.json?_t=$timestamp';
      final response = await html.HttpRequest.request(
        url,
        method: 'GET',
        requestHeaders: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );
      if (response.status == 200 && response.responseText != null) {
        final data = jsonDecode(response.responseText!) as Map<String, dynamic>;
        return data['buildNumber']?.toString();
      }
    } catch (_) {}
    return null;
  }

  @override
  void hardRefresh() {
    try {
      if (js.context.hasProperty('caresyncHardRefresh')) {
        js.context.callMethod('caresyncHardRefresh');
        return;
      }
      html.window.location.reload();
    } catch (_) {
      try {
        html.window.location.reload();
      } catch (_) {}
    }
  }
}
