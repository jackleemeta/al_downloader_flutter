import 'implementation/ALDownloaderFileManagerIMP.dart';
import 'ALDownloaderPathModel.dart';

/// A manager that manages persistent file by url
class ALDownloaderFileManager {
  /// Get 'physical directory path' and 'virtual/physical file name' of the file for [url]
  ///
  /// Create the 'physical directory path' lazily in the disk by [url] when there is no 'physical directory path'.
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// 'physical directory path' and 'virtual/physical file name'
  static Future<ALDownloaderPathModel> lazyGetPathModelForUrl(String url) =>
      ALDownloaderFileManagerIMP.lazyGetPathModelForUrl(url);

  /// Get 'physical directory path' for [url]
  ///
  /// Create the 'physical directory path' lazily in the disk by [url] when there is no 'physical directory path'.
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// directory path
  static Future<String> lazyGetPhysicalDirectoryPathForUrl(String url) =>
      ALDownloaderFileManagerIMP.lazyGetPhysicalDirectoryPathForUrl(url);

  /// Get 'virtual file path' for [url]
  ///
  /// The return value must not be null.
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// 'virtual file path'
  static Future<String> getVirtualFilePathForUrl(String url) =>
      ALDownloaderFileManagerIMP.getVirtualFilePathForUrl(url);

  /// Get 'physical file path' for [url]
  ///
  /// Null will be returned if 'physical file path' does not exist.
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// 'physical file path'
  static Future<String?> getPhysicalFilePathForUrl(String url) =>
      ALDownloaderFileManagerIMP.getPhysicalFilePathForUrl(url);

  /// Check whether [url] exists a 'physical file path'
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// the result whether [url] exists a 'physical file path'
  static Future<bool> isExistPhysicalFilePathForUrl(String url) =>
      ALDownloaderFileManagerIMP.isExistPhysicalFilePathForUrl(url);

  /// Get 'virtual/physical file name' for [url]
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// 'virtual/physical file name'
  static String getFileNameForUrl(String url) =>
      ALDownloaderFileManagerIMP.getFileNameForUrl(url);

  /// Check whether [path] is in [_theRootDir]
  ///
  /// **parameters**
  ///
  /// [path] path
  ///
  /// **return**
  ///
  /// the result whether [path] is in the root path
  static Future<bool> isInRootPathForPath(String path) =>
      ALDownloaderFileManagerIMP.isInRootPathForPath(path);

  /// Get all disk directories
  static Future<List<String>?> get dirs => ALDownloaderFileManagerIMP.dirs;
}
