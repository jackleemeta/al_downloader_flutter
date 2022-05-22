import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

/// A tool that file type judgment
class ALDownloaderFileTypeJudge {
  /// Get file type model from url
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [ALDownloaderFileTypeModel] file type model
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

  /// A set of key-value pairs which type and type list
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

/// An enumeration of file type
enum ALDownloaderFileType { common, image, audio, video, other, unknown }

/// A class of file type model
class ALDownloaderFileTypeModel {
  ALDownloaderFileTypeModel(this.type, this.description);
  ALDownloaderFileType type = ALDownloaderFileType.unknown;
  String? description; // e.g. mp4、json、webp、wav
}
