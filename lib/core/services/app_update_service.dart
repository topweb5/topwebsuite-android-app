import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => AppUpdateService(),
);

/// Checks the Play Store for a newer app version and prompts the user to
/// update (Android only). Best-effort: silently no-ops when the Play Store is
/// unavailable (debug/sideloaded builds, offline, non-Android platforms).
class AppUpdateService {
  bool _checked = false;

  Future<void> maybePromptUpdate() async {
    if (!Platform.isAndroid || _checked) return;
    _checked = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      // Prefer a flexible (non-blocking) update; fall back to immediate.
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      } else if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // Update flow is optional; ignore failures.
    }
  }
}
