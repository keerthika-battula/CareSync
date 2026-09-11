// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'pwa_install_service.dart';

PwaInstallService createPwaInstallService() => PwaInstallServiceWeb();

class PwaInstallServiceWeb implements PwaInstallService {
  bool _isInstalled = false;
  bool _canInstall = false;
  void Function(bool canInstall, bool isInstalled)? _onStateChanged;

  @override
  bool get isSupported => true;

  @override
  bool get isInstalled => _isInstalled;

  @override
  bool get canInstall => _canInstall;

  @override
  void init({required void Function(bool canInstall, bool isInstalled) onStateChanged}) {
    _onStateChanged = onStateChanged;
    _refreshState();

    html.window.addEventListener('caresync_pwa_installable', (event) {
      _canInstall = true;
      _onStateChanged?.call(_canInstall, _isInstalled);
    });

    html.window.addEventListener('caresync_pwa_installed', (event) {
      _isInstalled = true;
      _canInstall = false;
      _onStateChanged?.call(_canInstall, _isInstalled);
    });
  }

  void _refreshState() {
    try {
      final isStandaloneDisplay = html.window.matchMedia('(display-mode: standalone)').matches;
      final dynamic nav = js.context['navigator'];
      final bool isIosStandalone = nav != null && nav['standalone'] == true;
      if (isStandaloneDisplay || isIosStandalone) {
        _isInstalled = true;
        _canInstall = false;
      }
    } catch (_) {}
    _onStateChanged?.call(_canInstall, _isInstalled);
  }

  @override
  Future<({bool supported, bool accepted})> promptInstall() async {
    if (_isInstalled) {
      return (supported: true, accepted: true);
    }

    final completer = Completer<({bool supported, bool accepted})>();

    late html.EventListener listener;
    listener = (html.Event event) {
      html.window.removeEventListener('caresync_pwa_install_response', listener);
      bool supported = false;
      bool accepted = false;

      if (event is html.CustomEvent && event.detail != null) {
        try {
          final detailStr = event.detail.toString();
          final Map<String, dynamic> data = jsonDecode(detailStr);
          supported = data['supported'] == true;
          accepted = data['accepted'] == true;
        } catch (_) {}
      }

      if (accepted) {
        _isInstalled = true;
        _canInstall = false;
        _onStateChanged?.call(_canInstall, _isInstalled);
      }

      if (!completer.isCompleted) {
        completer.complete((supported: supported, accepted: accepted));
      }
    };

    html.window.addEventListener('caresync_pwa_install_response', listener);

    try {
      // Directly and synchronously trigger the install method in JS
      js.context.callMethod('caresyncPromptInstall');
    } catch (_) {
      html.window.removeEventListener('caresync_pwa_install_response', listener);
      if (!completer.isCompleted) {
        completer.complete((supported: false, accepted: false));
      }
    }

    Timer(const Duration(seconds: 30), () {
      html.window.removeEventListener('caresync_pwa_install_response', listener);
      if (!completer.isCompleted) {
        completer.complete((supported: false, accepted: false));
      }
    });

    return await completer.future;
  }
}


