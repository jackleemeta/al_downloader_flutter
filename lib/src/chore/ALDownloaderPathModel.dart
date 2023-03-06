/// ALDownloaderPathModel
class ALDownloaderPathModel {
  ALDownloaderPathModel(this.directoryPath, this.fileName);

  String directoryPath; // file:/a/b/

  String fileName;

  /// Get file path
  /// e.g. file:/a/b/c/d.mp4, file:/a/b/d.mp4
  String get filePath {
    StringBuffer sb = StringBuffer();
    sb.write(directoryPath);
    sb.write(fileName);
    return sb.toString();
  }
}
