import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'internal/ALDownloaderFileTypeJudge.dart';
import 'internal/ALDownloaderPrint.dart';

/// A manager that manages persistent file by url
class ALDownloaderPersistentFileManager {
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
  static Future<ALDownloaderPathComponentModel>
      lazyGetALDownloaderPathModelForUrl(String url) async {
    // Generate path model by url.
    final model =
        ALDownloaderFileTypeJudge.getALDownloaderFileTypeModelFromUrl(url);

    // level 1 folder - component
    final dir = _alDownloaderFileTypeDirKVs[model.type]!;

    // level 2 folder - component
    final extensionResourcePath = dir + "/";

    // file name
    final fileName = _assembleFileName(url, model);

    final theRootDir = await _theRootDir;
    final dirForRootToFinalLevel = theRootDir + extensionResourcePath;

    await _ALDownloaderFilePathManager.tryToCreateCustomDirectory(
        dirForRootToFinalLevel,
        recursive: true);

    // level 2 folder - complete
    final dirForRootToFirstLevel = theRootDir + dir;
    return ALDownloaderPathComponentModel(dirForRootToFirstLevel, fileName);
  }

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
  static Future<String> lazyGetAbsolutePathOfDirectoryForUrl(String url) async {
    final alDownloaderPathComponentModel =
        await lazyGetALDownloaderPathModelForUrl(url); // model
    final dirPath = alDownloaderPathComponentModel.dir;

    return dirPath;
  }

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
  static Future<String> getAbsoluteVirtualPathOfFileForUrl(String url) async {
    String? filePath;
    // Generate data model of file types for url.
    final model =
        ALDownloaderFileTypeJudge.getALDownloaderFileTypeModelFromUrl(url);

    // level 1 folder - component
    final aDirString = _alDownloaderFileTypeDirKVs[model.type]!;
    final theRootDir = await _theRootDir;
    final dirForRootToFirstLevel = theRootDir + aDirString;
    final fileName = _assembleFileName(url, model);

    try {
      filePath = dirForRootToFirstLevel + fileName;
      aldDebugPrint(
          "ALDownloaderPersistentFileManager | getAbsoluteVirtualPathOfFileForUrl, filePath = $filePath");
    } catch (error) {
      aldDebugPrint(
          "ALDownloaderPersistentFileManager | getAbsoluteVirtualPathOfFileForUrl, error = $error");
    }

    return filePath!;
  }

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
  static Future<String?> getAbsolutePhysicalPathOfFileForUrl(String url) async {
    String virtualfilePath =
        await getAbsoluteVirtualPathOfFileForUrl(url); // virtual file path
    String? filePath;
    try {
      File aFile = File(virtualfilePath); // physical file
      if (aFile.existsSync()) filePath = virtualfilePath;
    } catch (error) {
      aldDebugPrint(
          "ALDownloaderPersistentFileManager | getAbsolutePhysicalPathOfFileForUrl, error = $error");
    }

    return filePath;
  }

  /// Check whether [url] exists a 'physical file path'
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// the result whether [url] exists a 'physical file path'
  static Future<bool> isExistAbsolutePhysicalPathOfFileForUrl(
          String url) async =>
      await getAbsolutePhysicalPathOfFileForUrl(url) != null;

  /// Get 'virtual/physical file name' for [url]
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// 'virtual/physical file name'
  static String getFileNameForUrl(String url) {
    final model =
        ALDownloaderFileTypeJudge.getALDownloaderFileTypeModelFromUrl(url);

    final fileName = _assembleFileName(url, model);
    return fileName;
  }

  /// Check whether [path] is in [_theRootDir]
  ///
  /// **parameters**
  ///
  /// [path] path
  ///
  /// **return**
  ///
  /// the result whether [path] is in the root path
  static Future<bool> isInRootPathForPath(String path) async {
    final theRootDir = await _theRootDir;
    final aBool = path.startsWith(theRootDir);
    return aBool;
  }

  /// Get all disk directories
  static Future<List<String>?> get dirs async {
    try {
      final String theRootDir = await _theRootDir;

      final List<String> aDirs = _alDownloaderFileTypeDirKVs.values
          .map((e) => theRootDir + e)
          .toList();

      return aDirs;
    } catch (error) {
      aldDebugPrint(
          "ALDownloaderPersistentFileManager | get dirs, error = $error");
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
      throw "ALDownloaderPersistentFileManager | get _theRootDir, error = ALDownloader can not operate on current platform ${Platform.operatingSystem}";
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

  /// A set of key-value pairs which type and file path
  static final _alDownloaderFileTypeDirKVs = {
    ALDownloaderFileType.common: _kExtensionCommonFilePath,
    ALDownloaderFileType.image: _kExtensionImageFilePath,
    ALDownloaderFileType.audio: _kExtensionAudioFilePath,
    ALDownloaderFileType.video: _kExtensionVideoFilePath,
    ALDownloaderFileType.other: _kExtensionOtherFilePath,
    ALDownloaderFileType.unknown: _kExtensionUnknownFilePath
  };

  static String _getMd5StringForString(String aString) {
    final content = Utf8Encoder().convert(aString);
    final digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// Common file folder path
  static final _kExtensionCommonFilePath = _kSuperiorPath + "al_common" + "/";

  /// Image file folder path
  static final _kExtensionImageFilePath = _kSuperiorPath + "al_image" + "/";

  /// Audio file folder path
  static final _kExtensionAudioFilePath = _kSuperiorPath + "al_audio" + "/";

  /// Video file folder path
  static final _kExtensionVideoFilePath = _kSuperiorPath + "al_video" + "/";

  /// Other file folder path
  static final _kExtensionOtherFilePath = _kSuperiorPath + "al_other" + "/";

  /// Unknown file folder path
  static final _kExtensionUnknownFilePath = _kSuperiorPath + "al_unknown" + "/";

  /// Parent path
  static final _kSuperiorPath = "/" + "al_flutter" + "/";
}

/// Combination class of 'directory path' and 'file name'
///
/// [dir] directory
///
/// [fileName] name of the file in [dir]
class ALDownloaderPathComponentModel {
  ALDownloaderPathComponentModel(this.dir, this.fileName);
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

class _ALDownloaderFilePathManager {
  /// Try to create a directory.
  static Future<Directory?> tryToCreateCustomDirectory(String path,
      {bool recursive = false}) async {
    final dir = Directory(path);
    try {
      bool exists = await dir.exists();
      if (!exists) return await dir.create(recursive: recursive);
    } catch (error) {
      aldDebugPrint(
          "_ALDownloaderFilePathManager | tryToCreateCustomDirectory, error = $error");
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
          "_ALDownloaderFilePathManager | get localDocumentDirectory, directoryPath = $aPath");
    } catch (error) {
      aldDebugPrint(
          "_ALDownloaderFilePathManager | get localDocumentDirectory, error = $error");
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
          "_ALDownloaderFilePathManager | get localTemporaryDirectory, directoryPath = $aPath");
    } catch (error) {
      aldDebugPrint(
          "_ALDownloaderFilePathManager | get localTemporaryDirectory, error = $error");
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
            "_ALDownloaderFilePathManager | get localExternalStorageDirectory, directoryPath = $aPath");
      } else {
        aldDebugPrint(
            "_ALDownloaderFilePathManager | get localExternalStorageDirectory, directoryPath = none");
      }
    } catch (error) {
      aldDebugPrint(
          "_ALDownloaderFilePathManager | get localExternalStorageDirectory, error = $error");
    }
    return aPath;
  }
}
