class NativeUpdateRunner {
  const NativeUpdateRunner();

  bool get isSupported => false;

  Future<void> configure(String appcastUrl) async {}

  Future<void> checkForUpdates() async {
    throw UnsupportedError(
      'Native updates are not supported on this platform.',
    );
  }
}
