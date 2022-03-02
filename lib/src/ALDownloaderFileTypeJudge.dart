import 'package:flutter/foundation.dart';

/// 文件类型判断工具
class ALDownloaderFileTypeJudge {
  /// 从url中获取文件类型
  ///
  /// **parameters**
  ///
  ///[url] url
  ///
  /// **return**
  ///
  /// 文件类型数据模型 [ALDownloaderFileTypeModel]
  static ALDownloaderFileTypeModel getALDownloaderFileTypeModelFrom(
      String url) {
    for (final anEntry in _allALDownloaderFileTypeFilesEntries) {
      final type = anEntry.key;
      final value = anEntry.value;

      try {
        final String? element =
            value.firstWhere((element) => url.endsWith(element));
        if (element != null) return ALDownloaderFileTypeModel(type, element);
      } catch (error) {
        debugPrint(
            "ALDownloader | getALDownloaderFileTypeModelFrom， type = $type，error = $error");
      }
    }
    return ALDownloaderFileTypeModel(ALDownloaderFileType.unknown, null);
  }

  static final Iterable<MapEntry<ALDownloaderFileType, List<String>>>
      _allALDownloaderFileTypeFilesEntries = {
    ALDownloaderFileType.common: _commons,
    ALDownloaderFileType.image: _images,
    ALDownloaderFileType.audio: _audios,
    ALDownloaderFileType.video: _videos,
  }.entries;

  static final _commons = ["json", "xml", "html"];

  static final _images = [
    "xbm",
    "tif",
    "pjp",
    "svgz",
    "jpg",
    "jpeg",
    "ico",
    "tiff",
    "gif",
    "svg",
    "jfif",
    "webp",
    "png",
    "bmp",
    "pjpeg",
    "avif"
  ];

  static final _audios = [
    "opus",
    "flac",
    "webm",
    "weba",
    "wav",
    "ogg",
    "m4a",
    "mp3",
    "oga",
    "mid",
    "amr",
    "aiff",
    "wma",
    "au",
    "aac"
  ];

  static final _videos = [
    "mp4",
    "avi",
    "wmv",
    "mpg",
    "mpeg",
    "mov",
    "rm",
    "ram",
    "swf",
    "flv"
  ];
}

/// 文件类型枚举
enum ALDownloaderFileType {
  common, // 普通类型
  image, // 图片
  audio, // 音频
  video, //视频
  unknown // 未知类型
}

/// 文件类型的数据模型
class ALDownloaderFileTypeModel {
  ALDownloaderFileTypeModel(this.type, this.description);
  ALDownloaderFileType type = ALDownloaderFileType.unknown;
  String? description; // e.g. mp4、json、webp、wav
}
