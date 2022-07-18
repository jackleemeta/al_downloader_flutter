/// ALDownloaderPrint Config
class ALDownloaderPrintConfig {
  /// Get/Set whether enable print
  static bool enabled = true;

  /// Get whether enable frequent print
  ///
  /// If [enabled] is false, [frequentEnabled] is also false.
  static bool get frequentEnabled {
    if (!enabled) return false;
    return _innerFrequentEnabled;
  }

  /// Set whether enable frequent print
  static set frequentEnabled(bool value) {
    _innerFrequentEnabled = value;
  }

  static bool _innerFrequentEnabled = true;
}
