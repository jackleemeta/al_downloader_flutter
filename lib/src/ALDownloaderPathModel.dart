/// Combination class of 'directory path' and 'file name'
///
/// [dir] directory
///
/// [fileName] name of the file in [dir]
class ALDownloaderPathModel {
  ALDownloaderPathModel(this.dir, this.fileName);
  final String dir; // file:/a/b
  final String fileName;

  /// Get file path
  /// e.g. file:/a/b/c/d.mp4, file:/a/b/d.mp4
  String get filePath {
    StringBuffer sb = StringBuffer();
    sb.write(dir);
    sb.write(fileName);
    return sb.toString();
  }
}
