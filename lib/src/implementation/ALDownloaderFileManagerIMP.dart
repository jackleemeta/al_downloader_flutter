import 'dart:convert';
import 'dart:io';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../chore/ALDownloaderPathModel.dart';
import '../internal/ALDownloaderFileTypeJudge.dart';
import '../internal/ALDownloaderPrint.dart';

class ALDownloaderFileManagerIMP {
  static Future<ALDownloaderPathModel> lazyGetPathModelForUrl(
      String url) async {
    // Generate path model by url.
    final model = ALDownloaderFileTypeJudge.getFileTypeModelForUrl(url);

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
    return ALDownloaderPathModel(dirForRootToFirstLevel, fileName);
  }

  static Future<String> lazyGetPhysicalDirectoryPathForUrl(String url) async {
    final model = await lazyGetPathModelForUrl(url);
    final dirPath = model.dir;

    return dirPath;
  }

  static Future<String> getVirtualFilePathForUrl(String url) async {
    String? filePath;
    // Generate data model of file types for url.
    final model = ALDownloaderFileTypeJudge.getFileTypeModelForUrl(url);

    // level 1 folder - component
    final aDirString = _alDownloaderFileTypeDirKVs[model.type]!;
    final theRootDir = await _theRootDir;
    final dirForRootToFirstLevel = theRootDir + aDirString;
    final fileName = _assembleFileName(url, model);

    try {
      filePath = dirForRootToFirstLevel + fileName;
      aldDebugPrint(
          "ALDownloaderFileManager | getVirtualFilePathForUrl, filePath = $filePath");
    } catch (error) {
      aldDebugPrint(
          "ALDownloaderFileManager | getVirtualFilePathForUrl, error = $error");
    }

    return filePath!;
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
          "ALDownloaderFileManager | getPhysicalFilePathForUrl, error = $error");
    }

    return filePath;
  }

  static Future<bool> isExistPhysicalFilePathForUrl(String url) async =>
      await getPhysicalFilePathForUrl(url) != null;

  static String getFileNameForUrl(String url) {
    final model = ALDownloaderFileTypeJudge.getFileTypeModelForUrl(url);

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
      final String theRootDir = await _theRootDir;

      final List<String> aDirs = _alDownloaderFileTypeDirKVs.values
          .map((e) => theRootDir + e)
          .toList();

      return aDirs;
    } catch (error) {
      aldDebugPrint("ALDownloaderFileManager | get dirs, error = $error");
    }

    return null;
  }

  /// Get root path
  static Future<String> get _theRootDir async {
    String? aDir;
    if (Platform.isIOS) {
      aDir = await _ALDownloaderFilePathManager._localDocumentDirectory;
    } else if (Platform.isAndroid) {
      aDir = await _ALDownloaderFilePathManager._localExternalStorageDirectory;
      if (aDir == null)
        aDir = await _ALDownloaderFilePathManager._localDocumentDirectory;
    } else {
      throw "ALDownloaderFileManager | get _theRootDir, error = ALDownloader can not operate on current platform ${Platform.operatingSystem}";
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

  /// A set of key-value pairs for type and file path
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
          "_ALDownloaderFilePathManager | tryToCreateCustomDirectory, error = $error");
    }
    return null;
  }

  /// Get `document directory`
  // ignore: unused_element
  static Future<String> get _localDocumentDirectory async {
    String? aPath;
    try {
      final aDir = await getApplicationDocumentsDirectory();
      aPath = aDir.path;

      aldDebugPrint(
          "_ALDownloaderFilePathManager | get _localDocumentDirectory, directoryPath = $aPath");
    } catch (error) {
      aldDebugPrint(
          "_ALDownloaderFilePathManager | get _localDocumentDirectory, error = $error");
    }
    return aPath!;
  }

  /// Get `temporary directory`
  // ignore: unused_element
  static Future<String> get _localTemporaryDirectory async {
    String? aPath;
    try {
      final aDir = await getTemporaryDirectory();
      aPath = aDir.path;

      aldDebugPrint(
          "_ALDownloaderFilePathManager | get _localTemporaryDirectory, directoryPath = $aPath");
    } catch (error) {
      aldDebugPrint(
          "_ALDownloaderFilePathManager | get _localTemporaryDirectory, error = $error");
    }
    return aPath!;
  }

  /// Get `external storage directory`
  ///
  /// **note**
  ///
  /// No iOS
  // ignore: unused_element
  static Future<String?> get _localExternalStorageDirectory async {
    String? aPath;
    try {
      final aDir = await getExternalStorageDirectory();
      if (aDir != null) {
        aPath = aDir.path;

        aldDebugPrint(
            "_ALDownloaderFilePathManager | get _localExternalStorageDirectory, directoryPath = $aPath");
      } else {
        aldDebugPrint(
            "_ALDownloaderFilePathManager | get _localExternalStorageDirectory, directoryPath = none");
      }
    } catch (error) {
      aldDebugPrint(
          "_ALDownloaderFilePathManager | get _localExternalStorageDirectory, error = $error");
    }
    return aPath;
  }
}
