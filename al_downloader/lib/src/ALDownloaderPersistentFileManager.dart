import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ALDownloaderFileTypeJudge.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// 磁盘路径管理(根据url)
///
/// 1. 获取虚拟/物理目录路径
///
/// 2. 获取虚拟/物理文件路径
///
/// 3. 获取文件名
class ALDownloaderPersistentFileManager {
  /// -------------------------------- Public API --------------------------------

  /// 根据[url]获取文件的`物理目录路径`和`文件名`
  ///
  /// 当没有`物理目录路径`时，根据[url]`懒创建`磁盘的`物理目录路径`
  ///
  /// **parameters**
  ///
  /// [url] 远端资源路径
  /// [subDirectoryName] 子文件夹名称
  ///
  /// **return**
  ///
  /// `物理目录路径`和`文件名`
  static Future<ALDownloaderPathComponentModel>
      lazyGetALDownloaderPathModelFromUrl(String url,
          {String subDirectoryName = _kDefault}) async {
    // 根据url生成文件类型的数据模型
    final model =
        ALDownloaderFileTypeJudge.getALDownloaderFileTypeModelFrom(url);

    if (subDirectoryName == null || subDirectoryName.length == 0)
      subDirectoryName = _kDefault;

    // 1级文件夹 - 局部
    final dir = _alDownloaderFileTypeDirKVs[model.type];

    // 2级文件夹 - 局部
    final extensionResourcePath = dir + subDirectoryName + "/";

    // 文件名
    final fileName = _assembleFileName(url, model);

    final theRootDir = await _theRootDir;
    final dirForRootToFinalLevel = theRootDir + extensionResourcePath;

    await _ALDownloaderFilePathManager.tryCreateCustomDirectory(
        dirForRootToFinalLevel,
        recursive: true);

    // 2级文件夹
    final dirForRootToFirstLevel = theRootDir + dir;
    return ALDownloaderPathComponentModel(
        dirForRootToFirstLevel, subDirectoryName, fileName);
  }

  /// 根据[url]获取`目录路径`
  ///
  /// **parameters:**
  ///
  /// [url] 文件远端路径
  ///
  /// **return**
  ///
  /// `目录路径`
  static Future<String> getAbsolutePathOfDirectoryWithUrl(String url,
      {String subDirectoryName}) async {
    if (subDirectoryName == null || subDirectoryName.length == 0)
      subDirectoryName = _kDefault;

    final alDownloaderPathComponentModel =
        await lazyGetALDownloaderPathModelFromUrl(url,
            subDirectoryName: subDirectoryName); // model
    final dirPath = alDownloaderPathComponentModel.subDirectory; // 目录路径

    return dirPath;
  }

  /// 根据[url]获取`虚拟文件路径`
  ///
  /// **parameters:**
  ///
  /// [url] 文件远端路径
  ///
  /// [subDirectoryName] 子文件夹名称；传，直接按照路径取；不传，需要遍历；所以，建议传
  ///
  /// **return**
  ///
  /// `虚拟文件路径`
  static Future<String> getAbsoluteVirtualPathOfFileWithUrl(String url,
      {String subDirectoryName}) async {
    String filePath;
    if (subDirectoryName == null || subDirectoryName.length == 0) {
      // 遍历
      // 根据url生成文件类型的数据模型
      final model =
          ALDownloaderFileTypeJudge.getALDownloaderFileTypeModelFrom(url);
      // 1级文件夹 - 局部
      final aDirString = _alDownloaderFileTypeDirKVs[model.type];
      final theRootDir = await _theRootDir;
      final dirForRootToFirstLevel = theRootDir + aDirString;
      final fileName = _assembleFileName(url, model); // 文件名

      try {
        final aDir = Directory(dirForRootToFirstLevel);
        final aList = aDir.listSync(recursive: true);
        filePath =
            aList.firstWhere((element) => element.path.endsWith(fileName)).path;

        debugPrint("getAbsoluteVirtualPathOfFileWithUrlfilePath = $filePath");
      } catch (error) {
        debugPrint("getAbsoluteVirtualPathOfFileWithUrl | error = $error");
      }
    } else {
      // 指定
      final alDownloaderPathComponentModel =
          await lazyGetALDownloaderPathModelFromUrl(url,
              subDirectoryName: subDirectoryName);
      filePath = alDownloaderPathComponentModel.filePath;
    }

    return filePath;
  }

  /// 根据[url]获取`物理文件路径`
  ///
  /// 如果`物理文件路径`不存在，返回null
  ///
  /// **parameters:**
  ///
  /// [url] 文件远端路径
  ///
  /// [subDirectoryName] 子文件夹名称；传，直接按照路径取；不传，需要遍历；所以，建议传
  ///
  /// **return**
  ///
  /// `物理文件路径`
  static Future<String> getAbsolutePhysicalPathOfFileWithUrl(String url,
      {String subDirectoryName}) async {
    final filePath = await getAbsoluteVirtualPathOfFileWithUrl(url,
        subDirectoryName: subDirectoryName); // 文件路径
    final aFile = File(filePath); // 物理文件
    if (!aFile.existsSync()) return null;
    return filePath;
  }

  /// 获取所有存储目录
  static Future<List<String>> get dirs async {
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

  /// 是否存在[url]对应`物理路径`
  ///
  ///
  /// **parameters:**
  ///
  /// [url] 文件远端路径
  ///
  /// **return**
  ///
  /// bool `是否存在`
  static Future<bool> isExistAbsolutePhysicalPathOfFileForUrl(String url,
          {String subDirectoryName = _kDefault}) async =>
      getAbsolutePhysicalPathOfFileWithUrl(url,
          subDirectoryName: subDirectoryName) !=
      null;

  /// 根据[url]获取`文件名`
  ///
  /// **parameters**
  ///
  /// [url] 文件远端路径
  ///
  /// **return**
  ///
  /// `文件名`
  static String getFileNameFromUrl(String url) {
    // 文件类型的数据模型
    final model =
        ALDownloaderFileTypeJudge.getALDownloaderFileTypeModelFrom(url);

    // 文件名
    final fileName = _assembleFileName(url, model);
    return fileName;
  }

  /// -------------------------------- Private API --------------------------------

  /// 根路径
  static Future<String> get _theRootDir async =>
      await _ALDownloaderFilePathManager.localExternalStorageDirectory;

  /// 根据[url]和[model]组装文件名
  static String _assembleFileName(String url, ALDownloaderFileTypeModel model) {
    final StringBuffer sb = StringBuffer();

    final md5String = _getMd5StringFor(url);
    sb.write(md5String);

    if (model.type != ALDownloaderFileType.unknown) {
      sb.write(".");
      sb.write(model.description);
    }
    return sb.toString();
  }

  // 类型和类型列表键值
  static final _alDownloaderFileTypeDirKVs = {
    ALDownloaderFileType.common: _kExtensionCommonFilePath,
    ALDownloaderFileType.image: _kExtensionImageFilePath,
    ALDownloaderFileType.audio: _kExtensionAudioFilePath,
    ALDownloaderFileType.video: _kExtensionVideoFilePath,
    ALDownloaderFileType.unknown: _kExtensionUnknownFilePath,
  };

  static String _getMd5StringFor(String aString) {
    var content = new Utf8Encoder().convert(aString);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  // 默认文件夹名称
  static const String _kDefault = "default";

  // 普通文件路径
  static final _kExtensionCommonFilePath = _kSuperiorPath + "al_common" + "/";

  // 图片文件路径
  static final _kExtensionImageFilePath = _kSuperiorPath + "al_image" + "/";

  // 音频文件路径
  static final _kExtensionAudioFilePath = _kSuperiorPath + "al_audio" + "/";

  // 视频文件路径
  static final _kExtensionVideoFilePath = _kSuperiorPath + "al_video" + "/";

  // 未知类型文件路径
  static final _kExtensionUnknownFilePath = _kSuperiorPath + "al_unknown" + "/";

  // 父路径
  static final _kSuperiorPath = "/" + "flutter" + "/";
}

/// `目录路径`和`文件名` 组合类
///
/// [dir] 目录
///
/// [fileName] [dir]下的文件名
class ALDownloaderPathComponentModel {
  ALDownloaderPathComponentModel(
      this.dir, this.subDirectoryName, this.fileName);
  final String dir; // file:/a/b
  final String subDirectoryName;
  final String fileName;

  /// file:/a/b/c
  String get subDirectory {
    StringBuffer sb = StringBuffer();
    sb.write(dir);
    if (subDirectoryName != null && subDirectoryName.length > 0) {
      sb.write(subDirectoryName);
      sb.write("/");
      return sb.toString();
    }
    return null;
  }

  /// file:/a/b/c/d.mp4 or // file:/a/b/d.mp4
  String get filePath {
    StringBuffer sb = StringBuffer();
    sb.write(dir);
    if (subDirectoryName != null) {
      sb.write(subDirectoryName);
      sb.write("/");
    }
    sb.write(fileName);
    return sb.toString();
  }
}

class _ALDownloaderFilePathManager {
  /// 创建目录
  static Future<Directory> tryCreateCustomDirectory(String path,
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

  /// 获取[文档目录]
  // ignore: unused_element
  static Future<String> get localDocumentPath async {
    String aPath;
    try {
      final aDir = await getApplicationDocumentsDirectory();
      aPath = aDir.path;

      debugPrint('文档目录: ' + aPath);
    } catch (error) {
      debugPrint("localDocumentPath error = $error");
    }
    return aPath;
  }

  /// 获取[临时目录]
  // ignore: unused_element
  static Future<String> get localTemporaryPath async {
    String aPath;
    try {
      final aDir = await getTemporaryDirectory();
      aPath = aDir.path;

      debugPrint('临时目录: ' + aPath);
    } catch (error) {
      debugPrint("localTemporaryPath error = $error");
    }
    return aPath;
  }

  /// 获取[外部存储目录]
  ///
  /// No iOS
  static Future<String> get localExternalStorageDirectory async {
    String aPath;
    try {
      final aDir = await getExternalStorageDirectory();
      aPath = aDir.path;

      debugPrint('外部存储目录: ' + aPath);
    } catch (error) {
      debugPrint("localExternalStorageDirectory error = $error");
    }
    return aPath;
  }
}
