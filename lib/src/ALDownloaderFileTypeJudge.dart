import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

/// file type judgment tool
class ALDownloaderFileTypeJudge {
  /// get file type from url
  ///
  /// **parameters**
  ///
  ///[url] url
  ///
  /// **return**
  ///
  /// file type model [ALDownloaderFileTypeModel]
  static ALDownloaderFileTypeModel getALDownloaderFileTypeModelFromUrl(
      String url) {
    final File file = File(url);
    final anExtension = extension(file.path);

    for (final anEntry in _allALDownloaderFileTypeFilesEntries) {
      final type = anEntry.key;
      final value = anEntry.value;

      try {
        if (value.contains(anExtension))
          return ALDownloaderFileTypeModel(type, anExtension);
      } catch (error) {
        debugPrint(
            "ALDownloader | getALDownloaderFileTypeModelFromUrl, type = $type, error = $error");
      }
    }

    return ALDownloaderFileTypeModel(ALDownloaderFileType.unknown, anExtension);
  }

  /// type and type list key value pairs
  static final Iterable<MapEntry<ALDownloaderFileType, List<String>>>
      _allALDownloaderFileTypeFilesEntries = {
    ALDownloaderFileType.common: _commons,
    ALDownloaderFileType.image: _images,
    ALDownloaderFileType.audio: _audios,
    ALDownloaderFileType.video: _videos,
    ALDownloaderFileType.other: _others,
  }.entries;

  static final _commons = [".json", ".xml", ".html"];

  static final _images = [
    ".xbm",
    ".tif",
    ".pjp",
    ".svgz",
    ".jpg",
    ".jpeg",
    ".ico",
    ".tiff",
    ".gif",
    ".svg",
    ".jfif",
    ".webp",
    ".png",
    ".bmp",
    ".pjpeg",
    ".avif"
  ];

  static final _audios = [
    ".opus",
    ".flac",
    ".webm",
    ".weba",
    ".wav",
    ".ogg",
    ".m4a",
    ".mp3",
    ".oga",
    ".mid",
    ".amr",
    ".aiff",
    ".wma",
    ".au",
    ".aac"
  ];

  static final _videos = [
    ".mp4",
    ".avi",
    ".wmv",
    ".mpg",
    ".mpeg",
    ".mov",
    ".rm",
    ".ram",
    ".swf",
    ".flv"
  ];

  static final _others = [".pdf"];
}

/// file type enumeration
enum ALDownloaderFileType { common, image, audio, video, other, unknown }

/// class of file type model
class ALDownloaderFileTypeModel {
  ALDownloaderFileTypeModel(this.type, this.description);
  ALDownloaderFileType type = ALDownloaderFileType.unknown;
  String? description; // e.g. mp4、json、webp、wav
}
