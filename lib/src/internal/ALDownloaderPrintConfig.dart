/// ALDownloaderPrint Config
abstract class ALDownloaderPrintConfig {
  /// Get/Set whether enable print
  static bool enabled = false;

  /// Get whether enable frequent print
  static bool get frequentEnabled {
    if (!enabled) return false;
    return _innerFrequentEnabled;
  }

  /// Set whether enable frequent print
  static set frequentEnabled(bool value) {
    _innerFrequentEnabled = value;
  }

  static bool _innerFrequentEnabled = false;

  /// Privatize constructor
  ALDownloaderPrintConfig._();
}
