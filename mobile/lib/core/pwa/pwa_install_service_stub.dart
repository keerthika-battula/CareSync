import 'pwa_install_service.dart';

PwaInstallService createPwaInstallService() => PwaInstallServiceStub();

class PwaInstallServiceStub implements PwaInstallService {
  @override
  bool get isSupported => false;

  @override
  bool get isInstalled => false;

  @override
  bool get canInstall => false;

  @override
  void init({required void Function(bool canInstall, bool isInstalled) onStateChanged}) {
    // No-op for non-web platforms
  }

  @override
  Future<({bool supported, bool accepted})> promptInstall() async {
    return (supported: false, accepted: false);
  }
}
