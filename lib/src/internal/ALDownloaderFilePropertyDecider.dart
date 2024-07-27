import 'dart:io';

import 'package:path/path.dart';

import 'ALDownloaderPrint.dart';

/// A file property decider
///
/// Decide type for file.
///
/// Decide component directory path by type for file.
abstract class ALDownloaderFilePropertyDecider {
  /// Privatize constructor
  ALDownloaderFilePropertyDecider._();

  /// Get file type model for url
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [ALDownloaderFileTypeModel] file type model
  static ALDownloaderFileTypeModel getFileTypeModelForUrl(String url) {
    final file = File(url);
    final anExtension = extension(file.path);

    for (final type in ALDownloaderFileType.values) {
      final typeExtensions = type._typeExtensions;

      try {
        if (typeExtensions != null && typeExtensions.contains(anExtension))
          return ALDownloaderFileTypeModel(type, anExtension);
      } catch (error) {
        aldDebugPrint(
            'ALDownloaderFilePropertyDecider | getFileTypeModelForUrl, url = $url, type = $type, error: $error');
      }
    }

    return ALDownloaderFileTypeModel(ALDownloaderFileType.unknown, anExtension);
  }
}

/// An enumeration of file type
enum ALDownloaderFileType {
  unknown,
  common,
  document,
  image,
  audio,
  video,
  archive,
  other
}

/// A class of file type model
class ALDownloaderFileTypeModel {
  ALDownloaderFileType type = ALDownloaderFileType.unknown;

  /// Description
  ///
  /// e.g. mp4 json webp wav
  String? description;

  ALDownloaderFileTypeModel(this.type, this.description);
}

abstract class _ALDownloaderFilePropertyDeciderConstant {
  static final fileTypeComponentDirectoryPathKVs = {
    ALDownloaderFileType.unknown: kComponentUnknownDirectoryPath,
    ALDownloaderFileType.common: kComponentCommonDirectoryPath,
    ALDownloaderFileType.document: kComponentDocumentDirectoryPath,
    ALDownloaderFileType.image: kComponentImageDirectoryPath,
    ALDownloaderFileType.audio: kComponentAudioDirectoryPath,
    ALDownloaderFileType.video: kComponentVideoDirectoryPath,
    ALDownloaderFileType.archive: kComponentArchiveDirectoryPath,
    ALDownloaderFileType.other: kComponentOtherDirectoryPath
  };

  static final fileTypeExtensionsKVs = {
    ALDownloaderFileType.unknown: unknowns,
    ALDownloaderFileType.common: commons,
    ALDownloaderFileType.document: documents,
    ALDownloaderFileType.image: images,
    ALDownloaderFileType.audio: audios,
    ALDownloaderFileType.video: videos,
    ALDownloaderFileType.archive: archives,
    ALDownloaderFileType.other: others
  };

  static const unknowns = <String>[];

  static final commons = ['.json', '.xml', '.yaml', '.html'];

  static final documents = [
    '.txt',
    '.doc',
    '.ppt',
    '.docx',
    '.xlsx',
    '.csv',
    '.tsv',
    '.pptx',
    '.pdf',
    '.pages',
    '.numbers',
    '.key'
  ];

  static final images = [
    '.xbm',
    '.tif',
    '.pjp',
    '.svgz',
    '.jpg',
    '.jpeg',
    '.ico',
    '.tiff',
    '.gif',
    '.svg',
    '.jfif',
    '.webp',
    '.png',
    '.bmp',
    '.pjpeg',
    '.avif'
  ];

  static final archives = [
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.bz2',
    '.xz',
    '.iso',
    '.dmg',
    '.lzma',
    '.cab',
    '.z',
    '.jar',
    '.war',
    '.tar.gz',
    '.tar.bz2',
    '.tar.xz'
  ];

  static final audios = [
    '.opus',
    '.flac',
    '.webm',
    '.weba',
    '.wav',
    '.ogg',
    '.m4a',
    '.mp3',
    '.oga',
    '.mid',
    '.amr',
    '.aiff',
    '.wma',
    '.au',
    '.aac'
  ];

  static final videos = [
    '.mp4',
    '.avi',
    '.wmv',
    '.mpg',
    '.mpeg',
    '.mpe',
    '.mov',
    '.rm',
    '.ram',
    '.swf',
    '.flv',
    '.ts',
    '.m4v',
    '.asf',
    '.asx',
    '.rmvb',
    '.3gp',
    '.dat',
    '.mkv',
    '.vob'
  ];

  static final others = <String>[];

  static final kComponentArchiveDirectoryPath =
      kComponentParentDirectoryPath + 'archive' + '/';

  static final kComponentUnknownDirectoryPath =
      kComponentParentDirectoryPath + 'unknown' + '/';

  static final kComponentCommonDirectoryPath =
      kComponentParentDirectoryPath + 'common' + '/';

  static final kComponentDocumentDirectoryPath =
      kComponentParentDirectoryPath + 'document' + '/';

  static final kComponentImageDirectoryPath =
      kComponentParentDirectoryPath + 'image' + '/';

  static final kComponentAudioDirectoryPath =
      kComponentParentDirectoryPath + 'audio' + '/';

  static final kComponentVideoDirectoryPath =
      kComponentParentDirectoryPath + 'video' + '/';

  static final kComponentOtherDirectoryPath =
      kComponentParentDirectoryPath + 'other' + '/';

  /// Component parent directory path
  static final kComponentParentDirectoryPath = '/resource/';
}

/// An enumeration extension of file type
extension ALDownloaderFileTypeExtension on ALDownloaderFileType {
  /// Component directory path for file type
  String? get componentDirectoryPath => _ALDownloaderFilePropertyDeciderConstant
      .fileTypeComponentDirectoryPathKVs[this];

  /// Component directory path for file type with [kComponentUnknownDirectoryPath] as placeholder
  String get componentDirectoryPathWithUnknownAsPlaceholder =>
      componentDirectoryPath ??
      _ALDownloaderFilePropertyDeciderConstant.kComponentUnknownDirectoryPath;

  /// File extension for file type
  List<String>? get _typeExtensions =>
      _ALDownloaderFilePropertyDeciderConstant.fileTypeExtensionsKVs[this];
}
