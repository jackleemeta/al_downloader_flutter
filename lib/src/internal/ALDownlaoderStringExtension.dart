extension ALDownloaderStringExtension on String {
  bool isEqualTo(String? b) =>
      ALDownloaderStringExtension.isEqualTwoString(this, b);

  static bool isEqualTwoString(String? a, String? b) {
    if (a == null || a.length == 0) {
      return b == null || b.length == 0;
    } else {
      if (b == null || b.length == 0) {
        return false;
      } else {
        return a == b;
      }
    }
  }
}
