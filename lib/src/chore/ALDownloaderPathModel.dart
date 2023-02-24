/// Combination class of 'directory path' and 'file name'
///
/// [directoryPath] directory
///
/// [fileName] name of the file in [directoryPath]
class ALDownloaderPathModel {
  ALDownloaderPathModel(this.directoryPath, this.fileName);

  final String directoryPath; // file:/a/b/

  final String fileName;

  /// Directory persistence status
  ALDownloaderPersistenceStatus directoryPersistenceStatus =
      ALDownloaderPersistenceStatus.unknown;

  /// Get file path
  /// e.g. file:/a/b/c/d.mp4, file:/a/b/d.mp4
  String get filePath {
    StringBuffer sb = StringBuffer();
    sb.write(directoryPath);
    sb.write(fileName);
    return sb.toString();
  }
}

/// ALDownloader persistence status
enum ALDownloaderPersistenceStatus { unknown, virtual, physical }
