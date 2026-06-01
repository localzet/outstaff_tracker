import 'dart:io';

import 'package:auto_updater/auto_updater.dart';

class NativeUpdateRunner {
  const NativeUpdateRunner();

  bool get isSupported => Platform.isWindows || Platform.isMacOS;

  Future<void> configure(String appcastUrl) async {
    if (!isSupported) {
      return;
    }
    await autoUpdater.setFeedURL(appcastUrl);
    await autoUpdater.setScheduledCheckInterval(0);
  }

  Future<void> checkForUpdates() async {
    if (!isSupported) {
      throw UnsupportedError(
        'Native updates are not supported on this platform.',
      );
    }
    await autoUpdater.checkForUpdates();
  }
}
