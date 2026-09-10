import 'package:caresync/core/pwa/pwa_install_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PwaInstallState {
  final bool isInstalled;
  final bool canInstall;
  final bool isPrompting;

  const PwaInstallState({
    this.isInstalled = false,
    this.canInstall = false,
    this.isPrompting = false,
  });

  PwaInstallState copyWith({
    bool? isInstalled,
    bool? canInstall,
    bool? isPrompting,
  }) {
    return PwaInstallState(
      isInstalled: isInstalled ?? this.isInstalled,
      canInstall: canInstall ?? this.canInstall,
      isPrompting: isPrompting ?? this.isPrompting,
    );
  }
}

class PwaInstallNotifier extends StateNotifier<PwaInstallState> {
  final PwaInstallService _service;

  PwaInstallNotifier(this._service)
      : super(PwaInstallState(
          isInstalled: _service.isInstalled,
          canInstall: _service.canInstall,
        )) {
    if (kIsWeb) {
      _service.init(onStateChanged: (canInstall, isInstalled) {
        state = state.copyWith(
          canInstall: canInstall,
          isInstalled: isInstalled,
        );
      });
    }
  }

  Future<({bool supported, bool accepted})> promptInstall() async {
    if (state.isInstalled) return (supported: true, accepted: true);
    state = state.copyWith(isPrompting: true);
    try {
      final result = await _service.promptInstall();
      if (result.accepted) {
        state = state.copyWith(
          isInstalled: true,
          canInstall: false,
          isPrompting: false,
        );
      } else {
        state = state.copyWith(isPrompting: false);
      }
      return result;
    } catch (_) {
      state = state.copyWith(isPrompting: false);
      return (supported: false, accepted: false);
    }
  }
}

final pwaInstallProvider = StateNotifierProvider<PwaInstallNotifier, PwaInstallState>((ref) {
  return PwaInstallNotifier(PwaInstallService.instance);
});
