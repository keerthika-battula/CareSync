import 'dart:async';
import 'package:caresync/core/version/app_version_info.dart';
import 'package:caresync/core/version/version_service.dart';
import 'package:caresync/core/version/version_service_stub.dart'
    if (dart.library.html) 'package:caresync/core/version/version_service_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VersionState {
  final bool hasUpdate;
  final bool isDismissed;
  final bool isUpdating;
  final String currentBuild;
  final String? latestBuild;

  const VersionState({
    this.hasUpdate = false,
    this.isDismissed = false,
    this.isUpdating = false,
    this.currentBuild = AppVersionInfo.currentBuildNumber,
    this.latestBuild,
  });

  bool get shouldShowBanner => hasUpdate && !isDismissed;

  VersionState copyWith({
    bool? hasUpdate,
    bool? isDismissed,
    bool? isUpdating,
    String? currentBuild,
    String? latestBuild,
  }) {
    return VersionState(
      hasUpdate: hasUpdate ?? this.hasUpdate,
      isDismissed: isDismissed ?? this.isDismissed,
      isUpdating: isUpdating ?? this.isUpdating,
      currentBuild: currentBuild ?? this.currentBuild,
      latestBuild: latestBuild ?? this.latestBuild,
    );
  }
}

class VersionNotifier extends StateNotifier<VersionState> {
  final VersionService _service;
  Timer? _periodicTimer;

  VersionNotifier(this._service) : super(const VersionState()) {
    if (kIsWeb) {
      // Check shortly after boot
      Future.delayed(const Duration(seconds: 2), checkForUpdates);
      // Check periodically every 3 minutes
      _periodicTimer = Timer.periodic(const Duration(minutes: 3), (_) {
        checkForUpdates();
      });
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> checkForUpdates() async {
    if (!kIsWeb) return;
    try {
      final latest = await _service.fetchLatestBuildNumber();
      if (latest != null && latest.isNotEmpty && latest != AppVersionInfo.currentBuildNumber) {
        state = state.copyWith(hasUpdate: true, latestBuild: latest);
      }
    } catch (_) {}
  }

  void dismissBanner() {
    state = state.copyWith(isDismissed: true);
  }

  void applyUpdate() {
    state = state.copyWith(isUpdating: true);
    _service.hardRefresh();
  }
}

final versionProvider = StateNotifierProvider<VersionNotifier, VersionState>((ref) {
  return VersionNotifier(createVersionService());
});
