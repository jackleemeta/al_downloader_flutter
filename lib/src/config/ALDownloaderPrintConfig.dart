/// ALDownloaderPrint Config
class ALDownloaderPrintConfig {
  /// Get/Set whether enable print
  static bool enable = true;

  /// Get whether enable frequent print
  ///
  /// If [enable] is false, [frequentEnable] is also false.
  static bool get frequentEnable {
    if (!enable) return false;
    return _innerFrequentEnable;
  }

  /// Set whether enable frequent print
  static set frequentEnable(bool value) {
    _innerFrequentEnable = value;
  }

  static bool _innerFrequentEnable = true;
}
