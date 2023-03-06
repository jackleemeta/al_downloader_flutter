extension ALDownloaderMapExtension on Map {
  bool isEqualTo(Map? b) => ALDownloaderMapExtension.isEqualTwoMap(this, b);

  static bool isEqualTwoMap(Map? a, Map? b) {
    if (a == null || a.isEmpty) {
      return b == null || b.isEmpty;
    } else {
      if (b == null || b.isEmpty) {
        return false;
      } else {
        for (final element in a.entries) {
          final k = element.key;
          final v = element.value;

          final vb = b[k];
          if (vb != v) return false;
        }

        for (final element in b.entries) {
          final k = element.key;
          final v = element.value;

          final va = a[k];
          if (va != v) return false;
        }

        return true;
      }
    }
  }
}
