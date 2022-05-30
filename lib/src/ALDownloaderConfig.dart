/// ALDownloaderPrint Config
class ALDownloaderPrintConfig {
  /// Get/Set whether enable print
  static bool enable = true;

  /// Get whether enable frequent print
  ///
  /// If [enable] is false, [frequentEnable] is also false.
  static bool get frequentEnable {
    if (!enable) return false;
    return _innerFrequentEnble;
  }

  /// Set whether enable frequent print
  static set frequentEnble(bool value) {
    _innerFrequentEnble = value;
  }

  static bool _innerFrequentEnble = true;
}

// /// ALDownloaderOther Config
// class ALDownloaderOtherConfig {}
