import 'dart:convert';
import 'dart:io';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../chore/ALDownloaderPathModel.dart';
import '../internal/ALDownloaderFilePropertyDecider.dart';
import '../internal/ALDownloaderPrint.dart';

abstract class ALDownloaderFileManagerIMP {
  static Future<ALDownloaderPathModel> lazyGetPathModelForUrl(
      String url) async {
    // Generate path model by url.
    final model = ALDownloaderFilePropertyDecider.getFileTypeModelForUrl(url);

    // component directory path
    final componentDirectoryPath =
        model.type.componentDirectoryPathWithUnknownAsPlaceholder;

    // file name
    final fileName = _assembleFileName(url, model);

    final theRootDir = await _theRootDir;

    // directory path
    final directoryPath = theRootDir + componentDirectoryPath;

    final directory =
        await _ALDownloaderFilePathManager.tryToCreateCustomDirectory(
            directoryPath,
            recursive: true);

    final pathModel = ALDownloaderPathModel(directoryPath, fileName);

    if (directory == null) {
      pathModel.directoryPersistenceStatus =
          ALDownloaderPersistenceStatus.virtual;
    } else {
      pathModel.directoryPersistenceStatus =
          ALDownloaderPersistenceStatus.physical;
    }

    return pathModel;
  }

  static Future<String> lazyGetPhysicalDirectoryPathForUrl(String url) async {
    final model = await lazyGetPathModelForUrl(url);
    final directoryPath = model.directoryPath;

    return directoryPath;
  }

  static Future<String> getVirtualFilePathForUrl(String url) async {
    // Generate data model of file types for url.
    final model = ALDownloaderFilePropertyDecider.getFileTypeModelForUrl(url);

    // level 1 folder - component
    final aDirString =
        model.type.componentDirectoryPathWithUnknownAsPlaceholder;
    final theRootDir = await _theRootDir;
    final dirForRootToFirstLevel = theRootDir + aDirString;
    final fileName = _assembleFileName(url, model);

    final filePath = dirForRootToFirstLevel + fileName;

    return filePath;
  }

  static Future<String?> getPhysicalFilePathForUrl(String url) async {
    String virtualfilePath =
        await getVirtualFilePathForUrl(url); // virtual file path
    String? filePath;
    try {
      File aFile = File(virtualfilePath); // physical file
      if (aFile.existsSync()) filePath = virtualfilePath;
    } catch (error) {
      aldDebugPrint(
          'ALDownloaderFileManager | getPhysicalFilePathForUrl, error = $error');
    }

    return filePath;
  }

  static Future<bool> isExistPhysicalFilePathForUrl(String url) async =>
      await getPhysicalFilePathForUrl(url) != null;

  static String getFileNameForUrl(String url) {
    final model = ALDownloaderFilePropertyDecider.getFileTypeModelForUrl(url);

    final fileName = _assembleFileName(url, model);
    return fileName;
  }

  static Future<bool> isInRootPathForPath(String path) async {
    final theRootDir = await _theRootDir;
    final aBool = path.startsWith(theRootDir);
    return aBool;
  }

  static Future<List<String>?> get dirs async {
    try {
      final theRootDir = await _theRootDir;
      final aDirs = <String>[];
      for (final element in ALDownloaderFileType.values) {
        final componentDirectoryPath = element.componentDirectoryPath;
        if (componentDirectoryPath != null)
          aDirs.add(theRootDir + componentDirectoryPath);
      }

      return aDirs;
    } catch (error) {
      aldDebugPrint('ALDownloaderFileManager | get dirs, error = $error');
    }

    return null;
  }

  /// Get root path
  static Future<String> get _theRootDir async {
    String? aDir;
    if (Platform.isIOS) {
      aDir = await _ALDownloaderFilePathManager.localDocumentDirectory;
    } else if (Platform.isAndroid) {
      aDir = await _ALDownloaderFilePathManager.localExternalStorageDirectory;
      if (aDir == null)
        aDir = await _ALDownloaderFilePathManager.localDocumentDirectory;
    } else {
      throw 'ALDownloaderFileManager | get _theRootDir, error = ALDownloader can not operate on current platform ${Platform.operatingSystem}';
    }

    return aDir;
  }

  /// Get result that assemble file name for [url] and [model]
  static String _assembleFileName(String url, ALDownloaderFileTypeModel model) {
    final StringBuffer sb = StringBuffer();

    final md5String = _getMd5StringForString(url);
    sb.write(md5String);

    final description = model.description;
    if (description != null && description.length > 0) sb.write(description);
    return sb.toString();
  }

  static String _getMd5StringForString(String aString) {
    final content = Utf8Encoder().convert(aString);
    final digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// Privatize constructor
  ALDownloaderFileManagerIMP._();
}

class _ALDownloaderFilePathManager {
  /// Try to create a directory
  static Future<Directory?> tryToCreateCustomDirectory(String path,
      {bool recursive = false}) async {
    final dir = Directory(path);
    try {
      bool exists = await dir.exists();
      if (!exists) return await dir.create(recursive: recursive);
    } catch (error) {
      aldDebugPrint(
          '_ALDownloaderFilePathManager | tryToCreateCustomDirectory, error = $error');
    }
    return null;
  }

  /// Get `document directory`
  // ignore: unused_element
  static Future<String> get localDocumentDirectory async {
    String? aPath;
    try {
      final aDir = await getApplicationDocumentsDirectory();
      aPath = aDir.path;

      aldDebugPrint(
          '_ALDownloaderFilePathManager | get localDocumentDirectory, directoryPath = $aPath');
    } catch (error) {
      aldDebugPrint(
          '_ALDownloaderFilePathManager | get localDocumentDirectory, error = $error');
    }
    return aPath!;
  }

  /// Get `temporary directory`
  // ignore: unused_element
  static Future<String> get localTemporaryDirectory async {
    String? aPath;
    try {
      final aDir = await getTemporaryDirectory();
      aPath = aDir.path;

      aldDebugPrint(
          '_ALDownloaderFilePathManager | get localTemporaryDirectory, directoryPath = $aPath');
    } catch (error) {
      aldDebugPrint(
          '_ALDownloaderFilePathManager | get localTemporaryDirectory, error = $error');
    }
    return aPath!;
  }

  /// Get `external storage directory`
  ///
  /// **note**
  ///
  /// No iOS
  // ignore: unused_element
  static Future<String?> get localExternalStorageDirectory async {
    String? aPath;
    try {
      final aDir = await getExternalStorageDirectory();
      if (aDir != null) {
        aPath = aDir.path;

        aldDebugPrint(
            '_ALDownloaderFilePathManager | get localExternalStorageDirectory, directoryPath = $aPath');
      } else {
        aldDebugPrint(
            '_ALDownloaderFilePathManager | get localExternalStorageDirectory, directoryPath = none');
      }
    } catch (error) {
      aldDebugPrint(
          '_ALDownloaderFilePathManager | get localExternalStorageDirectory, error = $error');
    }
    return aPath;
  }
}
