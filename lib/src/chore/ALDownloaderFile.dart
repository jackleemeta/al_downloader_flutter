/// ALDownloaderFile
class ALDownloaderFile {
  ALDownloaderFile(this.directoryPath, this.fileName);

  final String directoryPath; // file:/a/b/

  final String fileName;

  /// Get file path
  /// e.g. file:/a/b/c/d.mp4, file:/a/b/d.mp4
  String get filePath {
    StringBuffer sb = StringBuffer();
    sb.write(directoryPath);
    sb.write(fileName);
    return sb.toString();
  }
}
