import 'chore/ALDownloaderFile.dart';
import 'implementation/ALDownloaderFileManagerIMP.dart';

/// A manager that manages file by url
abstract class ALDownloaderFileManager {
  /// Get directory path and file name of the file for [url]
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [ALDownloaderFile]
  static Future<ALDownloaderFile?> getPhysicalFileForUrl(String url) =>
      ALDownloaderFileManagerIMP.getPhysicalFileForUrl(url);

  /// Get physical directory path for [url]
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// physical file path
  static Future<String?> getPhysicalFilePathForUrl(String url) =>
      ALDownloaderFileManagerIMP.getPhysicalFilePathForUrl(url);

  /// Check whether [url] exists a physical file path
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// the result whether [url] exists a physical file path
  static Future<bool> isExistPhysicalFilePathForUrl(String url) =>
      ALDownloaderFileManagerIMP.isExistPhysicalFilePathForUrl(url);

  /// Privatize constructor
  ALDownloaderFileManager._();
}
