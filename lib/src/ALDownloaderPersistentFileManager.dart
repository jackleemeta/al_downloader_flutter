import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ALDownloaderFileTypeJudge.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// persistent file management by url
class ALDownloaderPersistentFileManager {
  /// get the 'physical directory path' and 'virtual/physical file name' of the file for [url]
  ///
  /// when there is no 'physical directory path', create the 'physical directory path' in the disk by [url] lazily
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
    // generate data models of file types based on urls
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

    await _ALDownloaderFilePathManager.tryCreateCustomDirectory(
        dirForRootToFinalLevel,
        recursive: true);

    // level 2 folder - complete
    final dirForRootToFirstLevel = theRootDir + dir;
    return ALDownloaderPathComponentModel(dirForRootToFirstLevel, fileName);
  }

  /// get 'directory path' for [url]
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// directory path
  static Future<String> getAbsolutePathOfDirectoryForUrl(String url) async {
    final alDownloaderPathComponentModel =
        await lazyGetALDownloaderPathModelForUrl(url); // model
    final dirPath = alDownloaderPathComponentModel.dir;

    return dirPath;
  }

  /// get 'virtual file path' for [url]
  ///
  /// the return value must not be null
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
    // generate data model of file types for url
    final model =
        ALDownloaderFileTypeJudge.getALDownloaderFileTypeModelFromUrl(url);

    // level 1 folder - component
    final aDirString = _alDownloaderFileTypeDirKVs[model.type]!;
    final theRootDir = await _theRootDir;
    final dirForRootToFirstLevel = theRootDir + aDirString;
    final fileName = _assembleFileName(url, model); // assemble file name

    try {
      filePath = dirForRootToFirstLevel + fileName;
      debugPrint("getAbsoluteVirtualPathOfFileWithUrl | filePath = $filePath");
    } catch (error) {
      debugPrint("getAbsoluteVirtualPathOfFileWithUrl | error = $error");
    }

    return filePath!;
  }

  /// get 'physical file path' for [url]
  ///
  /// if 'physical file path' does not exist, null will be returned
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
      debugPrint("getAbsolutePhysicalPathOfFileWithUrl | error = $error");
    }

    return filePath;
  }

  /// get all storage directories
  static Future<List<String>?> get dirs async {
    try {
      final String theRootDir = await _theRootDir;

      final List<String> aDirs = _alDownloaderFileTypeDirKVs.values
          .map((e) => theRootDir + e)
          .toList();

      return aDirs;
    } catch (error) {
      debugPrint("ALDownloaderPersistentFileManager | get dirs error = $error");
    }

    return null;
  }

  /// check whether [url] has a physical path
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// Whether exists
  static Future<bool> isExistAbsolutePhysicalPathOfFileForUrl(
          String url) async =>
      await getAbsolutePhysicalPathOfFileForUrl(url) != null;

  /// get 'virtual/physical file name' for [url]
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

  /// check whether [path] is in the root path
  ///
  /// **parameters**
  ///
  /// [path] path
  ///
  /// **return**
  ///
  /// whether [path] is in the root path
  static Future<bool> isInRootPathWithPath(String path) async {
    final theRootDir = await _theRootDir;
    final aBool = path.startsWith(theRootDir);
    return aBool;
  }

  /// -------------------------------- Private API --------------------------------

  /// root path
  static Future<String> get _theRootDir async {
    String? aDir;
    if (Platform.isIOS) {
      aDir = await _ALDownloaderFilePathManager.localDocumentDirectory;
    } else if (Platform.isAndroid) {
      aDir = await _ALDownloaderFilePathManager.localExternalStorageDirectory;
      if (aDir == null)
        aDir = await _ALDownloaderFilePathManager.localDocumentDirectory;
    } else {
      throw "ALDownloaderPersistentFileManager get theRootDir error: ALDownloader can not operate on current platform ${Platform.operatingSystem}";
    }

    return aDir;
  }

  /// assemble file name for [url] and [model]
  static String _assembleFileName(String url, ALDownloaderFileTypeModel model) {
    final StringBuffer sb = StringBuffer();

    final md5String = _getMd5StringForString(url);
    sb.write(md5String);

    final description = model.description;
    if (description != null && description.length > 0) sb.write(description);
    return sb.toString();
  }

  /// type and file path key value pairs
  static final _alDownloaderFileTypeDirKVs = {
    ALDownloaderFileType.common: _kExtensionCommonFilePath,
    ALDownloaderFileType.image: _kExtensionImageFilePath,
    ALDownloaderFileType.audio: _kExtensionAudioFilePath,
    ALDownloaderFileType.video: _kExtensionVideoFilePath,
    ALDownloaderFileType.other: _kExtensionOtherFilePath,
    ALDownloaderFileType.unknown: _kExtensionUnknownFilePath
  };

  static String _getMd5StringForString(String aString) {
    var content = Utf8Encoder().convert(aString);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  /// common file folder path
  static final _kExtensionCommonFilePath = _kSuperiorPath + "al_common" + "/";

  /// image file folder path
  static final _kExtensionImageFilePath = _kSuperiorPath + "al_image" + "/";

  /// audio file folder path
  static final _kExtensionAudioFilePath = _kSuperiorPath + "al_audio" + "/";

  /// video file folder path
  static final _kExtensionVideoFilePath = _kSuperiorPath + "al_video" + "/";

  /// other file folder path
  static final _kExtensionOtherFilePath = _kSuperiorPath + "al_other" + "/";

  /// unknown file folder path
  static final _kExtensionUnknownFilePath = _kSuperiorPath + "al_unknown" + "/";

  /// parent path
  static final _kSuperiorPath = "/" + "al_flutter" + "/";
}

/// combination class of 'directory path' and 'file name'
///
/// [dir] directory
///
/// [fileName] name of the file in [dir]
class ALDownloaderPathComponentModel {
  ALDownloaderPathComponentModel(this.dir, this.fileName);
  final String dir; // file:/a/b
  final String fileName;

  /// file:/a/b/c/d.mp4 or // file:/a/b/d.mp4
  String get filePath {
    StringBuffer sb = StringBuffer();
    sb.write(dir);
    sb.write(fileName);
    return sb.toString();
  }
}

class _ALDownloaderFilePathManager {
  /// try to create a directory
  static Future<Directory?> tryCreateCustomDirectory(String path,
      {bool recursive = false}) async {
    var dir = Directory(path);
    try {
      bool exists = await dir.exists();
      if (!exists) return await dir.create(recursive: recursive);
    } catch (error) {
      debugPrint("tryCreateCustomDirectory error = $error");
    }
    return null;
  }

  /// get `document directory`
  // ignore: unused_element
  static Future<String> get localDocumentDirectory async {
    String? aPath;
    try {
      final aDir = await getApplicationDocumentsDirectory();
      aPath = aDir.path;

      debugPrint('document directory: ' + aPath);
    } catch (error) {
      debugPrint("get document directory error = $error");
    }
    return aPath!;
  }

  /// get `temporary directory`
  // ignore: unused_element
  static Future<String> get localTemporaryDirectory async {
    String? aPath;
    try {
      final aDir = await getTemporaryDirectory();
      aPath = aDir.path;

      debugPrint('temporary directory: ' + aPath);
    } catch (error) {
      debugPrint("get temporary directory error = $error");
    }
    return aPath!;
  }

  /// get `external storage directory`
  ///
  /// No iOS
  // ignore: unused_element
  static Future<String?> get localExternalStorageDirectory async {
    String? aPath;
    try {
      final aDir = await getExternalStorageDirectory();
      if (aDir != null) {
        aPath = aDir.path;

        debugPrint('external storage directory: ' + aPath);
      } else {
        debugPrint('external storage directory: none');
      }
    } catch (error) {
      debugPrint("get external storage directory error = $error");
    }
    return aPath;
  }
}
