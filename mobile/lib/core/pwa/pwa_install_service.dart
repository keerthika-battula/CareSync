import 'pwa_install_service_stub.dart'
    if (dart.library.html) 'pwa_install_service_web.dart';

abstract class PwaInstallService {
  static PwaInstallService? _instance;

  static PwaInstallService get instance {
    _instance ??= createPwaInstallService();
    return _instance!;
  }

  bool get isSupported;
  bool get isInstalled;
  bool get canInstall;

  void init({required void Function(bool canInstall, bool isInstalled) onStateChanged});
  Future<({bool supported, bool accepted})> promptInstall();
}
