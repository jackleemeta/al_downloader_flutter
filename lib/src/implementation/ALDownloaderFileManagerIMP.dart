import 'dart:async';
import 'dart:io';
import '../chore/ALDownloaderFile.dart';
import '../internal/ALDownloaderConstant.dart';
import '../internal/ALDownloaderDirectoryManager.dart';
import '../internal/ALDownloaderHeader.dart';
import '../internal/ALDownloaderMessage.dart';
import '../internal/ALDownloaderPrint.dart';
import '../internal/ALDownloaderInnerTask.dart';

/// ALDownloaderFileManagerIMP
abstract class ALDownloaderFileManagerIMP {
  static Future<ALDownloaderFile?> getPhysicalFileForUrl(String url) async {
    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<ALDownloaderFile?>();
    _idDynamicKVs[id] = (ALDownloaderFile? file) => aCompleter.complete(file);

    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderFileManagerIMP;
    message.action = ALDownloaderConstant.kGetPhysicalFileForUrl;
    message.content = {
      ALDownloaderConstant.kHandlerId: id,
      ALDownloaderConstant.kUrl: url
    };

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static Future<String?> getPhysicalFilePathForUrl(String url) async {
    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<String?>();
    _idDynamicKVs[id] =
        (String? directoryPath) => aCompleter.complete(directoryPath);

    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderFileManagerIMP;
    message.action = ALDownloaderConstant.kGetPhysicalFilePathForUrl;
    message.content = {
      ALDownloaderConstant.kHandlerId: id,
      ALDownloaderConstant.kUrl: url
    };

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static Future<bool> isExistPhysicalFilePathForUrl(String url) async {
    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<bool>();
    _idDynamicKVs[id] = (bool isExist) => aCompleter.complete(isExist);

    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderFileManagerIMP;
    message.action = ALDownloaderConstant.kIsExistPhysicalFilePathForUrl;
    message.content = {
      ALDownloaderConstant.kHandlerId: id,
      ALDownloaderConstant.kUrl: url
    };

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static Future<ALDownloaderFile> cLazyGetFile(
      String directoryPath, String fileName) async {
    if (Platform.isIOS) {
      final localDocumentDirectory =
          await ALDownloaderDirectoryManager.localDocumentDirectory;
      if (!directoryPath.startsWith(localDocumentDirectory)) {
        final errorMsg =
            'ALDownloaderFileManager | cLazyGetFile | error: At present, on iOS, only `Documents` directory is available, because `FlutterDownloader` does not support any other directory.';
        aldDebugPrint(errorMsg);
        throw errorMsg;
      }
    }

    await ALDownloaderDirectoryManager.tryToCreateCustomDirectory(directoryPath,
        recursive: true);

    final file = ALDownloaderFile(directoryPath, fileName);

    aldDebugPrint(
        'ALDownloaderFileManager | cLazyGetFile | file path = ${file.filePath}');

    return file;
  }

  static Future<bool> cIsInRootPathForPath(String path, String rootPath) async {
    final theRootDir = rootPath;
    final aBool = path.startsWith(theRootDir);
    return aBool;
  }

  static bool cIsExistPhysicalFilePath(String? filePath) {
    bool aBool = false;

    if (filePath != null) {
      try {
        final aFile = File(filePath);
        if (aFile.existsSync()) aBool = true;
      } catch (error) {
        aldDebugPrint(
            'ALDownloaderFileManager | getPhysicalFilePathForUrl, error: $error');
      }
    }

    return aBool;
  }

  /// Do work on root isolate
  static void doWorkOnRootIsolate(ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;
    if (action == ALDownloaderConstant.kCallFileManagerHandler) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final data = content[ALDownloaderConstant.kData];

      final handler = _idDynamicKVs[id];

      if (handler != null) handler(data);

      _idDynamicKVs.remove(id);
    }
  }

  /// Do work on ALDownloader isolate
  static void doWorkOnALIsolate(ALDownloaderMessage message) {
    if (ALDownloaderHeader.initializedCompleter.isCompleted) {
      _doWorkWhichMustBeAfterInitializedOnALIsolate(message);
    } else {
      ALDownloaderHeader.initializedCompleter.future
          .then((_) => _doWorkWhichMustBeAfterInitializedOnALIsolate(message));
    }
  }

  static void _doWorkWhichMustBeAfterInitializedOnALIsolate(
      ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;

    if (action == ALDownloaderConstant.kGetPhysicalFileForUrl) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final url = content[ALDownloaderConstant.kUrl];

      _getPhysicalFileForUrl(id, url);
    } else if (action == ALDownloaderConstant.kGetPhysicalFilePathForUrl) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final url = content[ALDownloaderConstant.kUrl];

      _getPhysicalFilePathForUrl(id, url);
    } else if (action == ALDownloaderConstant.kIsExistPhysicalFilePathForUrl) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final url = content[ALDownloaderConstant.kUrl];

      _isExistPhysicalFilePathForUrl(id, url);
    }
  }

  static Future<void> _getPhysicalFileForUrl(String id, String url) async {
    final task = _getTaskFromUrl(url);

    ALDownloaderFile? file;
    if (task != null) {
      final directoryPath = task.savedDir;
      final fileName = task.fileName;
      if (directoryPath != null && fileName != null) {
        try {
          final filePath = directoryPath + fileName;
          final aFile = File(filePath);
          if (aFile.existsSync()) {
            file = ALDownloaderFile(directoryPath, fileName);
          } else {
            final aDirectory = Directory(directoryPath);
            if (aDirectory.existsSync())
              file = ALDownloaderFile(directoryPath, '');
          }
        } catch (error) {
          aldDebugPrint(
              'ALDownloaderFileManager | getPhysicalFilePathForUrl, error: $error');
        }
      }
    }

    ALDownloaderHeader.processFileManagerHandlerOnComingRootIsolate(id, file);
  }

  static void _getPhysicalFilePathForUrl(String id, String url) {
    final task = _getTaskFromUrl(url);

    String? aFilePath;

    if (task != null) {
      final filePath = task.filePath;

      if (filePath != null) {
        try {
          final aFile = File(filePath);
          if (aFile.existsSync()) aFilePath = filePath;
        } catch (error) {
          aldDebugPrint(
              'ALDownloaderFileManager | getPhysicalFilePathForUrl, error: $error');
        }
      }
    }

    ALDownloaderHeader.processFileManagerHandlerOnComingRootIsolate(
        id, aFilePath);
  }

  static void _isExistPhysicalFilePathForUrl(String id, String url) {
    final task = _getTaskFromUrl(url);

    bool aBool = false;

    if (task != null && task.savedDir != null && task.fileName != null) {
      final filePath = task.filePath;

      if (filePath != null) {
        try {
          final aFile = File(filePath);
          if (aFile.existsSync()) aBool = true;
        } catch (error) {
          aldDebugPrint(
              'ALDownloaderFileManager | getPhysicalFilePathForUrl, error: $error');
        }
      }
    }

    ALDownloaderHeader.processFileManagerHandlerOnComingRootIsolate(id, aBool);
  }

  static ALDownloaderInnerTask? _getTaskFromUrl(String url) {
    ALDownloaderInnerTask? task;
    try {
      task =
          ALDownloaderHeader.tasks.firstWhere((element) => url == element.url);
    } catch (error) {
      aldDebugPrint('ALDownloaderFileManager | _getTaskFromUrl, error: $error');
    }

    return task;
  }

  static final _idDynamicKVs = <String, dynamic>{};
}
