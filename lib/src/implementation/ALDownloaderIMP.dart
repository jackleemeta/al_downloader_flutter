import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:queue/queue.dart';
import 'ALDownloaderFileManagerIMP.dart';
import '../ALDownloaderHandlerInterface.dart';
import '../ALDownloaderStatus.dart';
import '../ALDownloaderTypeDefine.dart';
import '../internal/ALDownloaderConstant.dart';
import '../internal/ALDownloaderHeader.dart';
import '../internal/ALDownloaderIsolateLauncher.dart';
import '../internal/ALDownloaderMessage.dart';
import '../internal/ALDownloaderPrint.dart';
import '../internal/ALDownloaderPrintConfig.dart';

abstract class ALDownloaderIMP {
  static void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;
      _launchALIsolate();
    }
  }

  static void configurePrint(
      {bool enabled = false, bool frequentEnabled = false}) {
    ALDownloaderPrintConfig.enabled = enabled;
    ALDownloaderPrintConfig.frequentEnabled = frequentEnabled;

    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kConfigurePrint;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kEnabled: enabled,
      ALDownloaderConstant.kFrequentEnabled: frequentEnabled
    };

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static ALDownloaderHandlerInterfaceId? download(String url,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface,
      Map<String, String> headers = const {}}) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kDownload;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kUrl: url,
      ALDownloaderConstant.kHeaders: headers
    };

    ALDownloaderHandlerInterfaceId? id;
    if (downloaderHandlerInterface != null) {
      id = ALDownloaderHeader.uuid.v1();
      _idInterfaceKVs[id] = downloaderHandlerInterface;
      message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;
    }

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static ALDownloaderHandlerInterfaceId addDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kAddDownloaderHandlerInterface;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();
    _idInterfaceKVs[id] = downloaderHandlerInterface;
    message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static ALDownloaderHandlerInterfaceId addForeverDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kAddForeverDownloaderHandlerInterface;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();
    _idInterfaceKVs[id] = downloaderHandlerInterface;
    message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static void removeDownloaderHandlerInterfaceForUrl(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action =
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForUrl;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeDownloaderHandlerInterfaceForId(
      ALDownloaderHandlerInterfaceId id) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action =
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForId;
    message.content = {ALDownloaderConstant.kDownloaderHandlerInterfaceId: id};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeDownloaderHandlerInterfaceForAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action =
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForAll;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static ALDownloaderStatus getStatusForUrl(String url) {
    ALDownloaderStatus status;

    try {
      final task = _getTaskFromUrl(url);

      if (task == null) {
        status = ALDownloaderStatus.unstarted;
      } else {
        final innerStatus = task.innerStatus;
        if (task.waitingPhase == _ALDownloaderTaskWaitingPhase.transiting ||
            task.waitingPhase == _ALDownloaderTaskWaitingPhase.waiting) {
          // _ALDownloaderTaskWaitingPhase.transiting and ALDownloaderTaskWaitingPhase.waiting as downloading
          status = ALDownloaderStatus.downloading;
        } else if (innerStatus == _ALDownloaderInnerStatus.prepared ||
            innerStatus == _ALDownloaderInnerStatus.undefined ||
            innerStatus == _ALDownloaderInnerStatus.deprecated) {
          status = ALDownloaderStatus.unstarted;
        } else if (innerStatus == _ALDownloaderInnerStatus.enqueued ||
            innerStatus == _ALDownloaderInnerStatus.running) {
          status = ALDownloaderStatus.downloading;
        } else if (innerStatus == _ALDownloaderInnerStatus.canceled ||
            innerStatus == _ALDownloaderInnerStatus.failed) {
          status = ALDownloaderStatus.failed;
        } else if (innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
            innerStatus == _ALDownloaderInnerStatus.paused) {
          status = ALDownloaderStatus.paused;
        } else {
          status = ALDownloaderStatus.succeeded;
        }
      }
    } catch (error) {
      status = ALDownloaderStatus.unstarted;
      aldDebugPrint('ALDownloader | getStatusForUrl = $url, error = $error');
    }

    return status;
  }

  static double getProgressForUrl(String url) {
    // ignore: non_constant_identifier_names
    double double_progress;

    try {
      final task = _getTaskFromUrl(url);

      int progress = task == null ? 0 : task.progress;

      double_progress =
          double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;
    } catch (error) {
      double_progress = 0;
      aldDebugPrint(
          'ALDownloader | get download progress for url = $url, error = $error');
    }

    return double_progress;
  }

  static void pause(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kPause;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void pauseAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kPauseAll;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void cancel(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kCancel;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void cancelAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kCancelAll;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void remove(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kRemove;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kRemoveAll;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void cDownload(String url,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface,
      Map<String, String> headers = const {}}) {
    String? id;
    if (downloaderHandlerInterface != null) {
      id = ALDownloaderHeader.uuid.v1();
      _idInterfaceKVs[id] = downloaderHandlerInterface;
    }

    _qDownload(url, downloaderHandlerInterfaceId: id, headers: headers);
  }

  static ALDownloaderHandlerInterfaceId cAddDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final id = ALDownloaderHeader.uuid.v1();
    _idInterfaceKVs[id] = downloaderHandlerInterface;

    _qAddDownloaderHandlerInterface(id, url, isInner: false);

    return id;
  }

  static void cAddForeverDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final id = ALDownloaderHeader.uuid.v1();
    _idInterfaceKVs[id] = downloaderHandlerInterface;
    _qAddForeverDownloaderHandlerInterface(id, url);
  }

  static void cRemoveDownloaderHandlerInterfaceForUrl(String url) =>
      _qRemoveDownloaderHandlerInterfaceForUrl(url);

  static void cRemoveDownloaderHandlerInterfaceForId(
          ALDownloaderHandlerInterfaceId id) =>
      _qRemoveDownloaderHandlerInterfaceForId(id);

  static void cPause(String url) => _qPause(url);

  static void cPauseAll() => _qPauseAll();

  static void cPauseUrls(List<String> urls) => _qPauseUrls(urls);

  static void cCancel(String url) => _qCancel(url);

  static void cCancelUrls(List<String> urls) => _qCancelUrls(urls);

  static void cCancelAll() => _qCancelAll();

  static void cRemove(String url) => _qRemove(url);

  static void cRemoveUrls(List<String> urls) => _qRemoveUrls(urls);

  static void cRemoveAll() => _qRemoveAll();

  static void _launchALIsolate() =>
      ALDownloaderIsolateLauncher.launchALIsolate();

  static void _qInitialize() {
    _queue.add(() async {
      await _initialize();
      ALDownloaderHeader.initializedCompleter.complete();
    }).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qInitialize, error = $error');
    });
  }

  static void _qDownload(String url,
      {String? downloaderHandlerInterfaceId,
      Map<String, String> headers = const {}}) {
    _queue
        .add(() => _download(url,
            downloaderHandlerInterfaceId: downloaderHandlerInterfaceId,
            headers: headers))
        .catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qDownload, error = $error');
    });
  }

  static void _qAddDownloaderHandlerInterface(
      String downloaderHandlerInterfaceId, String url,
      {bool isInner = true}) {
    _queue.add(() async {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterfaceId, false);
      aBinder.isInner = isInner;

      _addBinder(url, aBinder);
    });
  }

  static void _addBinder(String url, _ALDownloaderBinder binder) {
    List<_ALDownloaderBinder>? binders = _urlBinderKVs[url];
    if (binders == null) {
      binders = <_ALDownloaderBinder>[];
      _urlBinderKVs[url] = binders;
    }
    binders.add(binder);
  }

  static void _qAddForeverDownloaderHandlerInterface(
      String downloaderHandlerInterfaceId, String url) {
    _queue.add(() async {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterfaceId, true);

      _addBinder(url, aBinder);
    });
  }

  static void _qRemoveDownloaderHandlerInterfaceForUrl(String url) {
    _queue.add(() async {
      final binders = _urlBinderKVs[url];
      if (binders == null) return;

      final aList = <_ALDownloaderBinder>[];
      aList.addAll(binders);
      for (final element in aList) {
        if (element.isInner && element.url == url) {
          _callInterface(element.downloaderHandlerInterfaceId, false, false,
              false, false, 0,
              isNeedRemoveInterface: true);
          binders.remove(element);
        }
      }

      if (binders.length == 0) _urlBinderKVs.remove(url);
    }).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qRemoveDownloaderHandlerInterfaceForUrl, error = $error');
    });
  }

  static void _qRemoveDownloaderHandlerInterfaceForId(
      ALDownloaderHandlerInterfaceId id) {
    _queue.add(() async {
      final aMap = <String, List<_ALDownloaderBinder>>{};
      aMap.addAll(_urlBinderKVs);
      for (final entry in aMap.entries) {
        final key = entry.key;
        final element = entry.value;

        final aList = <_ALDownloaderBinder>[];
        aList.addAll(element);

        for (final element1 in aList) {
          if (element1.downloaderHandlerInterfaceId == id) {
            _callInterface(element1.downloaderHandlerInterfaceId, false, false,
                false, false, 0,
                isNeedRemoveInterface: true);
            element.remove(element1);
            if (element.length == 0) _urlBinderKVs.remove(key);
            return;
          }
        }
      }
    }).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qRemoveDownloaderHandlerInterfaceForId, error = $error');
    });
  }

  static void _qRemoveDownloaderHandlerInterfaceForAll() {
    _queue.add(() async {
      final aMap = <String, List<_ALDownloaderBinder>>{};
      aMap.addAll(_urlBinderKVs);
      for (final entry in aMap.entries) {
        final key = entry.key;
        final element = entry.value;

        final aList = <_ALDownloaderBinder>[];
        aList.addAll(element);

        for (final element1 in aList) {
          if (element1.isInner) {
            _callInterface(element1.downloaderHandlerInterfaceId, false, false,
                false, false, 0,
                isNeedRemoveInterface: true);
            element.remove(element1);
            if (element.length == 0) _urlBinderKVs.remove(key);
          }
        }
      }
    }).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qRemoveDownloaderHandlerInterfaceForAll, error = $error');
    });
  }

  static void _qPause(String url) {
    _queue.add(() => _pause(url)).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qPause, error = $error');
    });
  }

  static void _qPauseUrls(List<String> urls) {
    _queue.add(() => _pauseUrls(urls)).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qPauseUrls, error = $error');
    });
  }

  static void _qPauseAll() {
    _queue.add(() => _pauseAll()).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qPauseAll, error = $error');
    });
  }

  static void _qCancel(String url) {
    _queue.add(() => _cancel(url)).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qCancel, error = $error');
    });
  }

  static void _qCancelUrls(List<String> urls) {
    _queue.add(() => _cancelUrls(urls)).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qCancelUrls, error = $error');
    });
  }

  static void _qCancelAll() {
    _queue.add(() => _cancelAll()).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qCancelAll, error = $error');
    });
  }

  static void _qRemove(String url) {
    _queue.add(() => _remove(url)).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qRemove, error = $error');
    });
  }

  static void _qRemoveUrls(List<String> urls) {
    _queue.add(() => _removeUrls(urls)).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qRemoveUrls, error = $error');
    });
  }

  static void _qRemoveAll() {
    _queue.add(() => _removeAll()).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qRemoveAll, error = $error');
    });
  }

  static Future<void> _initialize() async {
    // Initialize FlutterDownloader.
    await FlutterDownloader.initialize(
      debug: false,
      ignoreSsl: true,
    );

    _registerServiceForCommunicationBetweenFAndAL();

    // Register FlutterDownloader callback.
    await FlutterDownloader.registerCallback(_downloadCallback, step: 1);

    await _loadTasks();
  }

  static Future<void> _download(String url,
      {String? downloaderHandlerInterfaceId,
      Map<String, String> headers = const {}}) async {
    _ALDownloadTask? task = _getTaskFromUrl(url);

    if (downloaderHandlerInterfaceId != null) {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterfaceId, false);
      _addBinder(url, aBinder);
    }

    if (task == null)
      task = _addOrUpdateTaskForUrl(url, '', _ALDownloaderInnerStatus.prepared,
          0, '', '', _ALDownloaderTaskWaitingPhase.nonWaiting);

    task.headers = headers;

    if (_isLimitedForGoingTasks) {
      if (task.innerStatus == _ALDownloaderInnerStatus.prepared ||
          task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
          task.innerStatus == _ALDownloaderInnerStatus.deprecated ||
          task.innerStatus == _ALDownloaderInnerStatus.canceled ||
          task.innerStatus == _ALDownloaderInnerStatus.failed ||
          task.innerStatus == _ALDownloaderInnerStatus.paused) {
        final aBool = _isWaitingTask(task);
        if (!aBool) {
          _waitTask(task);
          _processProgressEventForTask(task);
        }

        aldDebugPrint(
            'ALDownloader | try to download url, going tasks are limited, those will download later, url = $url, taskId = ${task.taskId}, status= ${task.innerStatus}');
        return;
      }
    }

    if (await _isShouldRemoveData(
        url, task.innerStatus, task.savedDir, task.filePath))
      await _removeTask(task);

    if (task.innerStatus == _ALDownloaderInnerStatus.prepared ||
        task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
      aldDebugPrint(
          'ALDownloader | try to download url, url is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}');

      // Get 'physical directory path' and 'file name' of the file by url.
      final model =
          await ALDownloaderFileManagerIMP.lazyGetPathModelForUrl(url);

      final directoryPath = model.directoryPath;
      final fileName = model.fileName;

      // Enqueue a task.
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: directoryPath,
          fileName: model.fileName,
          headers: task.headers,
          showNotification: false,
          openFileFromNotification: false);

      if (taskId != null) {
        aldDebugPrint(
            'ALDownloader | try to download url, a download task of url generates succeeded, url = $url, taskId = $taskId, innerStatus = enqueued');

        _addOrUpdateTaskForUrl(url, taskId, _ALDownloaderInnerStatus.enqueued,
            0, directoryPath, fileName, task.waitingPhase);

        _callProgressHandler(url, 0);
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, but a download task of url generates failed, url = $url, taskId = null');
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.complete) {
      aldDebugPrint(
          'ALDownloader | try to download url, but url is succeeded, url = $url, taskId = ${task.taskId}');

      _callSucceededHandler(task.url, task.double_progress);
    } else if (task.innerStatus == _ALDownloaderInnerStatus.canceled ||
        task.innerStatus == _ALDownloaderInnerStatus.failed) {
      final previousTaskId = task.taskId;
      final previousStatusDescription = task.innerStatus.alDescription;

      final taskIdForRetry = await FlutterDownloader.retry(taskId: task.taskId);

      if (taskIdForRetry != null) {
        final progress = task.progress;

        _addOrUpdateTaskForUrl(
            url,
            taskIdForRetry,
            _ALDownloaderInnerStatus.enqueued,
            progress,
            task.savedDir,
            task.fileName,
            task.waitingPhase);

        _processProgressEventForTask(task);

        aldDebugPrint(
            'ALDownloader | try to download url, url is $previousStatusDescription previously and retries succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForRetry, innerStatus = enqueued');
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, url is $previousStatusDescription previously but retries failed, url = $url, previous taskId = $previousTaskId, taskId = null');
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.paused) {
      final previousTaskId = task.taskId;

      final taskIdForResumption =
          await FlutterDownloader.resume(taskId: task.taskId);
      if (taskIdForResumption != null) {
        aldDebugPrint(
            'ALDownloader | try to download url, url is paused previously and resumes succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForResumption');

        _addOrUpdateTaskForUrl(
            url,
            taskIdForResumption,
            Platform.isIOS
                ? _ALDownloaderInnerStatus.running
                : _ALDownloaderInnerStatus.paused,
            task.progress,
            task.savedDir,
            task.fileName,
            task.waitingPhase);
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, url is paused previously but resumes failed, url = $url, previous taskId = $previousTaskId, taskId = null');
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.running) {
      aldDebugPrint(
          'ALDownloader | try to download url, but url is running, url may re-download after being paused, url = $url, taskId = ${task.taskId}');

      task.isMayRedownloadAboutPause = true;
    } else {
      aldDebugPrint(
          'ALDownloader | try to download url, but url is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}');
    }
  }

  static Future<void> _pause(String url) async {
    try {
      _ALDownloadTask? task = _getTaskFromUrl(url);

      aldDebugPrint(
          'ALDownloader | _pause, url = $url, url is ${task?.innerStatus.alDescription}');

      if (task == null) {
        task = _addOrUpdateTaskForUrl(
            url,
            '',
            _ALDownloaderInnerStatus.prepared,
            0,
            '',
            '',
            _ALDownloaderTaskWaitingPhase.nonWaiting);
      } else {
        final taskId = task.taskId;

        if (task.innerStatus == _ALDownloaderInnerStatus.enqueued) {
          await _pauseTaskPretendedlyWithCallHandler(task);
        } else if (task.innerStatus == _ALDownloaderInnerStatus.running) {
          if (Platform.isAndroid) {
            if (await ALDownloaderFileManagerIMP.isExistPhysicalFilePathForUrl(
                url)) {
              await FlutterDownloader.pause(taskId: taskId);
              task.isMayRedownloadAboutPause = false;
            } else {
              await _pauseTaskPretendedlyWithCallHandler(task);
            }
          } else {
            await FlutterDownloader.pause(taskId: taskId);
            task.isMayRedownloadAboutPause = false;
          }
        } else if (task.waitingPhase ==
                _ALDownloaderTaskWaitingPhase.transiting ||
            task.waitingPhase == _ALDownloaderTaskWaitingPhase.waiting) {
          if (task.innerStatus == _ALDownloaderInnerStatus.paused ||
              task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused) {
            _processPausedEventForTask(task);
          } else {
            await _pauseTaskPretendedlyWithCallHandler(task);
          }
        } else if (task.innerStatus == _ALDownloaderInnerStatus.paused ||
            task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused) {
          _callPausedHandler(task.url, task.double_progress);
        }
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _pause, url = $url, error = $error');
    }
  }

  static Future<void> _pauseUrls(List<String> urls) async {
    for (final url in urls) _transitUrl(url);
    for (final url in urls) {
      await _pause(url);
      _unwaitUrl(url);
    }
  }

  static double ttt = 0;

  static Future<void> _pauseAll() async {
    for (final task in _tasks) _transitTask(task);
    for (final task in _tasks) {
      await _pause(task.url);
      _unwaitTask(task);
    }
  }

  static Future<void> _cancel(String url) async {
    try {
      final task = _getTaskFromUrl(url);

      aldDebugPrint(
          'ALDownloader | _cancel, url = $url, url is ${task?.innerStatus.alDescription}');

      if (task == null) {
        _addOrUpdateTaskForUrl(url, '', _ALDownloaderInnerStatus.prepared, 0,
            '', '', _ALDownloaderTaskWaitingPhase.nonWaiting);
      } else if (task.waitingPhase ==
              _ALDownloaderTaskWaitingPhase.transiting ||
          task.waitingPhase == _ALDownloaderTaskWaitingPhase.waiting ||
          task.innerStatus == _ALDownloaderInnerStatus.enqueued ||
          task.innerStatus == _ALDownloaderInnerStatus.running) {
        await _removeTaskWithCallHandler(task);
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _cancel, url = $url, error = $error');
    }
  }

  static Future<void> _cancelUrls(List<String> urls) async {
    for (final url in urls) _transitUrl(url);
    for (final url in urls) await _cancel(url);
  }

  static Future<void> _cancelAll() async {
    for (final task in _tasks) _transitTask(task);
    for (final task in _tasks) await _cancel(task.url);
  }

  static Future<void> _remove(String url) async {
    try {
      final task = _getTaskFromUrl(url);

      aldDebugPrint(
          'ALDownloader | _remove, url = $url, url is ${task?.innerStatus.alDescription}');

      if (task == null) {
        _addOrUpdateTaskForUrl(url, '', _ALDownloaderInnerStatus.prepared, 0,
            '', '', _ALDownloaderTaskWaitingPhase.nonWaiting);
      } else {
        await _removeTaskWithCallHandler(task);
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _remove, url = $url, error = $error');
    }
  }

  static Future<void> _removeUrls(List<String> urls) async {
    for (final url in urls) _transitUrl(url);
    for (final url in urls) await _remove(url);
  }

  static Future<void> _removeAll() async {
    for (final task in _tasks) _transitTask(task);
    for (final task in _tasks) await _remove(task.url);
  }

  /// Manager custom download tasks
  ///
  /// **purpose**
  ///
  /// avoid frequent I/O
  ///
  /// **discussion**
  ///
  /// Add or update the task for [url].
  static _ALDownloadTask _addOrUpdateTaskForUrl(
      String? url,
      String taskId,
      _ALDownloaderInnerStatus innerStatus,
      int progress,
      String savedDir,
      String fileName,
      _ALDownloaderTaskWaitingPhase waitingPhase) {
    if (url == null)
      throw 'ALDownloader | _addOrUpdateTaskForUrl, error = url is null';

    _ALDownloadTask? task;

    try {
      task = _tasks.firstWhere((element) => element.url == url);
      task.savedDir = savedDir;
      task.fileName = fileName;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;
      task.waitingPhase = waitingPhase;
    } catch (error) {
      aldDebugPrint('ALDownloader | _addOrUpdateTaskForUrl, error = $error');
    }

    if (task == null) {
      task = _ALDownloadTask(url);
      task.savedDir = savedDir;
      task.fileName = fileName;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;
      task.waitingPhase = waitingPhase;
      task.pIndex = _tasks.length;

      _tasks.add(task);
    }

    if (task.innerStatus == _ALDownloaderInnerStatus.enqueued ||
        task.innerStatus == _ALDownloaderInnerStatus.running) {
      if (!_goingTasks.contains(task)) _goingTasks.add(task);
    } else {
      if (_goingTasks.contains(task)) _goingTasks.remove(task);
    }

    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kSyncTaskToRoot;
    message.content = {ALDownloaderConstant.kTask: task};

    ALDownloaderHeader.portALToRoot?.send(message);

    return task;
  }

  /// Do work on root isolate
  static void doWorkOnRootIsolate(ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;
    if (action == ALDownloaderConstant.kSyncTaskToRoot) {
      final task = content[ALDownloaderConstant.kTask];
      _addOrUpdateTaskForUrl(task.url, task.taskId, task.innerStatus,
          task.progress, task.savedDir, task.fileName, task.waitingPhase);
    } else if (action == ALDownloaderConstant.kCallInterface) {
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      final isNeedCallProgressHandler =
          content[ALDownloaderConstant.kIsNeedCallProgressHandler];
      final isNeedCallSucceededHandler =
          content[ALDownloaderConstant.kIsNeedCallSucceededHandler];
      final isNeedCallFailedHandler =
          content[ALDownloaderConstant.kIsNeedCallFailedHandler];
      final isNeedCallPausedHandler =
          content[ALDownloaderConstant.kIsNeedCallPausedHandler];
      final progress = content[ALDownloaderConstant.kProgress];
      final isNeedRemoveInterface =
          content[ALDownloaderConstant.kIsNeedRemoveInterface];
      final inteface = _idInterfaceKVs[id];
      ALDownloaderHeader.callDownloaderHandlerInterface(
          inteface,
          isNeedCallProgressHandler,
          isNeedCallSucceededHandler,
          isNeedCallFailedHandler,
          isNeedCallPausedHandler,
          progress);

      if (isNeedRemoveInterface) _idInterfaceKVs.remove(id);
    }
  }

  /// Do work on ALDownloader isolate
  static void doWorkOnALIsolate(ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;

    if (action == ALDownloaderConstant.kInitiallize) {
      _qInitialize();
    } else if (action == ALDownloaderConstant.kConfigurePrint) {
      final enabled = content[ALDownloaderConstant.kEnabled];
      final frequentEnabled = content[ALDownloaderConstant.kFrequentEnabled];
      ALDownloaderPrintConfig.enabled = enabled;
      ALDownloaderPrintConfig.frequentEnabled = frequentEnabled;
    } else if (action == ALDownloaderConstant.kAddDownloaderHandlerInterface) {
      final url = content[ALDownloaderConstant.kUrl];
      final downloaderHandlerInterface =
          content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _qAddDownloaderHandlerInterface(downloaderHandlerInterface, url);
    } else if (action ==
        ALDownloaderConstant.kAddForeverDownloaderHandlerInterface) {
      final url = content[ALDownloaderConstant.kUrl];
      final downloaderHandlerInterface =
          content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _qAddForeverDownloaderHandlerInterface(downloaderHandlerInterface, url);
    } else if (action ==
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForUrl) {
      final url = content[ALDownloaderConstant.kUrl];
      _qRemoveDownloaderHandlerInterfaceForUrl(url);
    } else if (action ==
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForId) {
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _qRemoveDownloaderHandlerInterfaceForId(id);
    } else if (action ==
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForAll) {
      _qRemoveDownloaderHandlerInterfaceForAll();
    } else {
      if (ALDownloaderHeader.initializedCompleter.isCompleted) {
        _doWorkWhichMustBeAfterInitializedOnALIsolate(message);
      } else {
        ALDownloaderHeader.initializedCompleter.future.then(
            (_) => _doWorkWhichMustBeAfterInitializedOnALIsolate(message));
      }
    }
  }

  static void _doWorkWhichMustBeAfterInitializedOnALIsolate(
      ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;

    if (action == ALDownloaderConstant.kDownload) {
      final url = content[ALDownloaderConstant.kUrl];
      final downloaderHandlerInterfaceId =
          content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      final headers = content[ALDownloaderConstant.kHeaders];
      _qDownload(url,
          downloaderHandlerInterfaceId: downloaderHandlerInterfaceId,
          headers: headers);
    } else if (action == ALDownloaderConstant.kPause) {
      final url = content[ALDownloaderConstant.kUrl];
      _qPause(url);
    } else if (action == ALDownloaderConstant.kPauseAll) {
      _qPauseAll();
    } else if (action == ALDownloaderConstant.kCancel) {
      final url = content[ALDownloaderConstant.kUrl];
      _qCancel(url);
    } else if (action == ALDownloaderConstant.kCancelAll) {
      _qCancelAll();
    } else if (action == ALDownloaderConstant.kRemove) {
      final url = content[ALDownloaderConstant.kUrl];
      _qRemove(url);
    } else if (action == ALDownloaderConstant.kRemoveAll) {
      _qRemoveAll();
    }
  }

  /// Register service which is used for that communication between [FlutterDownloader] isolate and ALDownloader isolate by [IsolateNameServer]
  static void _registerServiceForCommunicationBetweenFAndAL() {
    final receivePort = ReceivePort();

    IsolateNameServer.registerPortWithName(
        receivePort.sendPort, _kPortForFToAL);
    receivePort.listen((dynamic data) {
      final taskId = data[0];

      final originalStatusValue = data[1];
      final originalStatus = DownloadTaskStatus(originalStatusValue);

      final progress = data[2];

      _processDataFromFPort(taskId, originalStatus, progress);
    });
  }

  /// The callback binded by [FlutterDownloader]
  @pragma('vm:entry-point')
  static void _downloadCallback(
      String taskId, DownloadTaskStatus originalStatus, int progress) {
    final send = IsolateNameServer.lookupPortByName(_kPortForFToAL);
    final originalStatusValue = originalStatus.value;

    send?.send([taskId, originalStatusValue, progress]);
  }

  /// Process the [FlutterDownloader]'s callback
  static void _processDataFromFPort(
      String taskId, DownloadTaskStatus originalStatus, int progress) {
    aldDebugPrint(
        'ALDownloader | _processDataFromFPort | original, taskId = $taskId, original status = $originalStatus, original progress = $progress',
        isFrequentPrint: true);

    _ALDownloaderInnerStatus innerStatus = _transferStatus(originalStatus);

    final task = _getTaskFromTaskId(taskId);

    if (task == null) {
      aldDebugPrint(
          'ALDownloader | _processDataFromFPort, the function return, because task is not found, taskId = $taskId');
      return;
    }

    if (task.innerStatus == _ALDownloaderInnerStatus.prepared ||
        task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
      aldDebugPrint(
          'ALDownloader | _processDataFromFPort, the function return, because task is ${task.innerStatus.alDescription}, taskId = $taskId');
      return;
    }

    final url = task.url;

    _addOrUpdateTaskForUrl(url, taskId, innerStatus, progress, task.savedDir,
        task.fileName, task.waitingPhase);

    _callHandlerForBusiness1(task);

    if (task.isMayRedownloadAboutPause &&
        task.innerStatus == _ALDownloaderInnerStatus.paused) {
      task.isMayRedownloadAboutPause = false;
      _qDownload(url, headers: task.headers);
    }

    aldDebugPrint(
        'ALDownloader | _processDataFromFPort | processed, taskId = $taskId, url = $url, innerStatus = $innerStatus, progress = $progress, double_progress = ${task.double_progress}',
        isFrequentPrint: true);
  }

  /// Load [FlutterDownloader]'s database task to the memory cache
  static Future<void> _loadTasks() async {
    final originalTasks = await FlutterDownloader.loadTasks();

    if (originalTasks != null) {
      aldDebugPrint(
          'ALDownloader | _loadTasks, original tasks length = ${originalTasks.length}');

      for (final element in originalTasks) {
        final originalTaskId = element.taskId;
        final originalUrl = element.url;
        final originalSavedDir = element.savedDir;
        final originalFileName = element.filename ?? '';
        final originalStatus = element.status;
        final originalProgress = element.progress;

        aldDebugPrint(
            'ALDownloader | _loadTasks, original url = $originalUrl, original taskId = $originalTaskId, original status = $originalStatus');

        final task = _ALDownloadTask(originalUrl);
        task.taskId = originalTaskId;

        if (originalSavedDir.endsWith('/')) {
          task.savedDir = originalSavedDir;
        } else {
          task.savedDir = originalSavedDir + '/';
        }
        task.fileName = originalFileName;
        task.innerStatus = _transferStatus(originalStatus);
        task.progress = originalProgress;
        _tasks.add(task);

        final isShouldRemoveDataForSavedDir =
            await _isShouldRemoveDataForInitialization(
                task.url, task.innerStatus, task.savedDir, task.filePath);
        if (isShouldRemoveDataForSavedDir) await _removeTask(task);

        aldDebugPrint(
            'ALDownloader | _loadTasks, url = ${task.url}, taskId = ${task.taskId}, innerStatus = ${task.innerStatus}, isShouldRemoveDataForSavedDir = $isShouldRemoveDataForSavedDir');
      }

      aldDebugPrint(
          'ALDownloader | _loadTasks, tasks length = ${_tasks.length}');

      for (final task in _tasks) {
        if (task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
          _processFailedEventForUrlProgress(task.url, 0);
        } else {
          // If the task is normal, call handler directly.
          _callHandlerForBusiness1(task);
        }
      }
    }
  }

  /// Call handler for business 1
  static void _callHandlerForBusiness1(_ALDownloadTask task) {
    final innerStatus = task.innerStatus;
    if (innerStatus == _ALDownloaderInnerStatus.enqueued ||
        innerStatus == _ALDownloaderInnerStatus.running) {
      _processProgressEventForTask(task);
    } else if (innerStatus == _ALDownloaderInnerStatus.complete) {
      _processSucceededEventForTask(task);
    } else if (innerStatus == _ALDownloaderInnerStatus.canceled ||
        innerStatus == _ALDownloaderInnerStatus.failed) {
      _processFailedEventForUrlProgress(task.url, -0.01);
    } else if (innerStatus == _ALDownloaderInnerStatus.paused) {
      _processPausedEventForTask(task);
    }
  }

  /// Verify data and then determine whether to delete data from disk
  ///
  /// for initialization
  static Future<bool> _isShouldRemoveDataForInitialization(
      String url,
      _ALDownloaderInnerStatus innerStatus,
      String savedDir,
      String filePath) async {
    if (innerStatus == _ALDownloaderInnerStatus.prepared) return false;
    if (!(await _isInRootPathForPath(savedDir))) return true;

    bool aBool = innerStatus == _ALDownloaderInnerStatus.enqueued ||
        innerStatus == _ALDownloaderInnerStatus.running;

    if (!aBool) {
      if (innerStatus == _ALDownloaderInnerStatus.complete ||
          innerStatus == _ALDownloaderInnerStatus.paused) {
        aBool =
            !(await ALDownloaderFileManagerIMP.isExistPhysicalFilePathForUrl(
                url));
      } else {
        aBool = false;
      }
    }

    if (!aBool) {
      final shouldFilePath =
          await ALDownloaderFileManagerIMP.getVirtualFilePathForUrl(url);
      if (filePath != shouldFilePath) aBool = true;
    }

    return aBool;
  }

  /// Verify data and then determine whether to delete data from disk
  static Future<bool> _isShouldRemoveData(
      String url,
      _ALDownloaderInnerStatus innerStatus,
      String savedDir,
      String filePath) async {
    if (innerStatus == _ALDownloaderInnerStatus.prepared) return false;
    if (!(await _isInRootPathForPath(savedDir))) return true;

    bool aBool;
    if (innerStatus == _ALDownloaderInnerStatus.complete ||
        innerStatus == _ALDownloaderInnerStatus.paused) {
      aBool = !(await ALDownloaderFileManagerIMP.isExistPhysicalFilePathForUrl(
          url));
    } else {
      aBool = false;
    }

    if (!aBool) {
      final shouldFilePath =
          await ALDownloaderFileManagerIMP.getVirtualFilePathForUrl(url);
      if (filePath != shouldFilePath) aBool = true;
    }

    return aBool;
  }

  /// Whether path is in root path
  static Future<bool> _isInRootPathForPath(String path) async {
    if (path == '') return false;

    // Delete previous versions's data.
    if (path.contains('/flutter/al_')) return false;

    final isSavedDirInRootPath =
        await ALDownloaderFileManagerIMP.isInRootPathForPath(path);

    return isSavedDirInRootPath;
  }

  /// Get task from custom download tasks by [url]
  static _ALDownloadTask? _getTaskFromUrl(String url) {
    _ALDownloadTask? task;
    try {
      task = _tasks.firstWhere((element) => url == element.url);
    } catch (error) {
      aldDebugPrint('ALDownloader | _getTaskFromUrl, error = $error');
    }
    return task;
  }

  /// Get task id from custom download tasks by [url]
  // ignore: unused_element
  static String? _getTaskIdFromUrl(String url) {
    String? taskId;
    try {
      taskId = _tasks.firstWhere((element) => url == element.url).taskId;
    } catch (error) {
      aldDebugPrint('ALDownloader | _getTaskIdWith, error = $error');
    }
    return taskId;
  }

  /// Get task from custom download tasks by [taskId]
  // ignore: unused_element
  static _ALDownloadTask? _getTaskFromTaskId(String taskId) {
    _ALDownloadTask? task;
    try {
      task = _tasks.firstWhere((element) => taskId == element.taskId);
    } catch (error) {
      aldDebugPrint('ALDownloader | _getTaskFromTaskId, error = $error');
    }
    return task;
  }

  /// Get url from custom download tasks by [taskId]
  // ignore: unused_element
  static String? _getUrlFromTaskId(String taskId) {
    String? url;
    try {
      url = _tasks.firstWhere((element) => taskId == element.taskId).url;
    } catch (error) {
      aldDebugPrint('ALDownloader | _getUrlWithTaskId, error = $error');
    }
    return url;
  }

  static bool get _isLimitedForGoingTasks {
    final isLimited = _goingTasks.length >= _kMaxConcurrentTaskCount;
    return isLimited;
  }

  static Future<void> _pauseTaskPretendedlyWithCallHandler(
      _ALDownloadTask task) async {
    await _pauseTaskPretendedly(task);

    _processPausedEventForTask(task);
  }

  static Future<void> _pauseTaskPretendedly(_ALDownloadTask task) async {
    final taskId = task.taskId;

    _addOrUpdateTaskForUrl(
        task.url,
        taskId,
        _ALDownloaderInnerStatus.pretendedPaused,
        task.progress,
        task.savedDir,
        task.fileName,
        task.waitingPhase);

    if (taskId.length > 0)
      await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static Future<void> _removeTaskWithCallHandler(_ALDownloadTask task) async {
    final url = task.url;

    await _removeTask(task);

    _processFailedEventForUrlProgress(url, 0);
  }

  static Future<void> _removeTask(_ALDownloadTask task) async {
    final taskId = task.taskId;

    _addOrUpdateTaskForUrl(
        task.url,
        taskId,
        _ALDownloaderInnerStatus.deprecated,
        task.progress,
        task.savedDir,
        task.fileName,
        task.waitingPhase);

    if (taskId.length > 0)
      await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static void _processProgressEventForTask(_ALDownloadTask task) {
    _callProgressHandler(task.url, task.double_progress);
  }

  static void _processSucceededEventForTask(_ALDownloadTask task) {
    _unwaitTask(task);
    _callSucceededHandler(task.url, task.double_progress);
    _downloadWaitingTasks();
  }

  // ignore: unused_element
  static void _processFailedEventForTask(_ALDownloadTask task) {
    _unwaitTask(task);
    _callFailedHandler(task.url, task.double_progress);
    _downloadWaitingTasks();
  }

  static void _processPausedEventForTask(_ALDownloadTask task) {
    _unwaitTask(task);
    _callPausedHandler(task.url, task.double_progress);
    _downloadWaitingTasks();
  }

  static void _processFailedEventForUrlProgress(String url, double progress) {
    _unwaitUrl(url);
    _callFailedHandler(url, progress);
    _downloadWaitingTasks();
  }

  static void _callProgressHandler(String url, double progress) {
    final binders = _urlBinderKVs[url];
    if (binders == null) return;

    for (final element in binders) {
      final downloaderHandlerInterfaceId = element.downloaderHandlerInterfaceId;
      _callInterface(
          downloaderHandlerInterfaceId, true, false, false, false, progress);
    }
  }

  static void _callSucceededHandler(String url, double progress) {
    final binders = _urlBinderKVs[url];
    if (binders == null) return;

    final aList = <_ALDownloaderBinder>[];
    aList.addAll(binders);

    for (final element in aList) {
      final downloaderHandlerInterfaceId = element.downloaderHandlerInterfaceId;
      _callInterface(
          downloaderHandlerInterfaceId, true, true, false, false, progress,
          isNeedRemoveInterface: !element.isForever);
      if (!element.isForever) binders.remove(element);
    }

    if (binders.length == 0) _urlBinderKVs.remove(url);
  }

  static void _callFailedHandler(String url, double progress) {
    final binders = _urlBinderKVs[url];
    if (binders == null) return;

    final aList = <_ALDownloaderBinder>[];
    aList.addAll(binders);

    for (final element in aList) {
      final downloaderHandlerInterfaceId = element.downloaderHandlerInterfaceId;
      _callInterface(
          downloaderHandlerInterfaceId, true, false, true, false, progress,
          isNeedRemoveInterface: !element.isForever);
      if (!element.isForever) binders.remove(element);
    }

    if (binders.length == 0) _urlBinderKVs.remove(url);
  }

  static void _callPausedHandler(String url, double progress) {
    final binders = _urlBinderKVs[url];
    if (binders == null) return;

    for (final element in binders) {
      final downloaderHandlerInterfaceId = element.downloaderHandlerInterfaceId;
      bool isNeedCallProgressHandler = progress > -0.01;

      _callInterface(downloaderHandlerInterfaceId, isNeedCallProgressHandler,
          false, false, true, progress);
    }
  }

  /// call interface for all isolates
  static void _callInterface(
      String downloaderHandlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress,
      {bool isNeedRemoveInterface = false}) {
    // Call interface for root isolate
    ALDownloaderHeader.processDownloaderHandlerInterfaceOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderIMP,
        downloaderHandlerInterfaceId,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress,
        isNeedRemoveInterface: isNeedRemoveInterface);

    // Call interface for current isolate
    _processDownloaderHandlerInterfaceOnCurrentIsolate(
        downloaderHandlerInterfaceId,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress);
  }

  static void _processDownloaderHandlerInterfaceOnCurrentIsolate(
      String downloaderHandlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress) {
    final downloaderHandlerInterface =
        _idInterfaceKVs[downloaderHandlerInterfaceId];
    ALDownloaderHeader.callDownloaderHandlerInterface(
        downloaderHandlerInterface,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress);
  }

  // ignore: unused_element
  static bool _isWaitingUrl(String url) {
    final task = _getTaskFromUrl(url);
    return _isWaitingTask(task);
  }

  static bool _isWaitingTask(_ALDownloadTask? task) {
    return task?.waitingPhase == _ALDownloaderTaskWaitingPhase.waiting;
  }

  // ignore: unused_element
  static void _waitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _waitTask(task);
  }

  static void _waitTask(_ALDownloadTask? task) {
    _assignTaskWaitingPhase(task, _ALDownloaderTaskWaitingPhase.waiting);
  }

  static void _transitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _transitTask(task);
  }

  static void _transitTask(_ALDownloadTask? task) {
    if (!_isWaitingTask(task)) return;

    _assignTaskWaitingPhase(task, _ALDownloaderTaskWaitingPhase.transiting);
  }

  static void _unwaitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _unwaitTask(task);
  }

  static void _unwaitTask(_ALDownloadTask? task) {
    _assignTaskWaitingPhase(task, _ALDownloaderTaskWaitingPhase.nonWaiting);
  }

  static void _assignTaskWaitingPhase(
      _ALDownloadTask? task, _ALDownloaderTaskWaitingPhase waitingPhase) {
    if (task == null) return;

    _addOrUpdateTaskForUrl(task.url, task.taskId, task.innerStatus,
        task.progress, task.savedDir, task.fileName, waitingPhase);

    switch (waitingPhase) {
      case _ALDownloaderTaskWaitingPhase.waiting:
        {
          if (!_waitingTasks.contains(task)) {
            _waitingTasks.add(task);
            _waitingTasks.sort((a, b) => a.pIndex.compareTo(b.pIndex));
          }
        }
        break;

      default:
        {
          _waitingTasks.remove(task);
        }
        break;
    }
  }

  static void _downloadWaitingTasks() {
    final expectedExecuteTasksCount =
        _kMaxConcurrentTaskCount - _goingTasks.length;

    for (int i = 0; i < expectedExecuteTasksCount; i++) {
      if (_waitingTasks.length > i) {
        final task = _waitingTasks[i];
        _qDownload(task.url, headers: task.headers);
      }
    }
  }

  static _ALDownloaderInnerStatus _transferStatus(DownloadTaskStatus status) {
    if (status == DownloadTaskStatus.enqueued) {
      return _ALDownloaderInnerStatus.enqueued;
    } else if (status == DownloadTaskStatus.running) {
      return _ALDownloaderInnerStatus.running;
    } else if (status == DownloadTaskStatus.complete) {
      return _ALDownloaderInnerStatus.complete;
    } else if (status == DownloadTaskStatus.failed) {
      return _ALDownloaderInnerStatus.failed;
    } else if (status == DownloadTaskStatus.canceled) {
      return _ALDownloaderInnerStatus.canceled;
    } else if (status == DownloadTaskStatus.paused) {
      return _ALDownloaderInnerStatus.paused;
    }

    return _ALDownloaderInnerStatus.undefined;
  }

  /// A dirty flag that [initialize] executed
  static bool _isInitialized = false;

  /// A map that key is id and value is [ALDownloaderHandlerInterface].
  ///
  /// Key is generated by [ALDownloaderHeader.uuid].
  static final _idInterfaceKVs = <String, ALDownloaderHandlerInterface>{};

  /// Send port for communication from [FlutterDownloader] isolate to ALDownloader isolate
  static final _kPortForFToAL = '_kPortForFToAL';

  /// ALDownloader event queue
  static final _queue = Queue();

  /// Custom download tasks
  static final _tasks = <_ALDownloadTask>[];

  /// Going download tasks
  static final _goingTasks = <_ALDownloadTask>[];

  /// Waiting download tasks
  static final _waitingTasks = <_ALDownloadTask>[];

  /// A map that key is url and value is binder list.
  static final _urlBinderKVs = <String, List<_ALDownloaderBinder>>{};

  /// Max concurrent task count
  static final _kMaxConcurrentTaskCount = 7;

  /// Privatize constructor
  ALDownloaderIMP._();
}

/// A class of custom download task
class _ALDownloadTask {
  final String url;

  String savedDir = '';

  String fileName = '';

  String taskId = '';

  int get progress => _progress;

  set progress(int value) {
    _progress = value;

    double_progress =
        double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;
  }

  int _progress = 0;

  _ALDownloaderInnerStatus innerStatus = _ALDownloaderInnerStatus.undefined;

  _ALDownloaderTaskWaitingPhase waitingPhase =
      _ALDownloaderTaskWaitingPhase.nonWaiting;

  // ignore: non_constant_identifier_names
  double double_progress = 0;

  Map<String, String> headers = const {};

  bool isMayRedownloadAboutPause = false;

  int pIndex = 0;

  String get filePath => savedDir + fileName;

  _ALDownloadTask(this.url);
}

/// A binder for binding some elements such as [url], [downloaderHandlerInterfaceId] and more
class _ALDownloaderBinder {
  final String url;

  final ALDownloaderHandlerInterfaceId downloaderHandlerInterfaceId;

  final bool isForever;

  /// Whether [_ALDownloaderBinder] generates by ALDownloader inner
  bool isInner = true;

  _ALDownloaderBinder(
      this.url, this.downloaderHandlerInterfaceId, this.isForever);
}

/// An enumeration of inner status
///
/// It is used to supplement some statuses for [DownloadTaskStatus].
///
/// **discussion**
///
/// It has supplemented the fllowing statuses at present.
///
/// [prepared], [deprecated], [pretendedPaused]
///
/// It may supplement more statuses in the future.
enum _ALDownloaderInnerStatus {
  prepared,
  undefined,
  enqueued,
  running,
  complete,
  failed,
  canceled,
  paused,
  pretendedPaused,
  deprecated
}

/// An enumeration of task waiting phase
///
/// [transiting]
///
/// It is a transitional status that used for some scenes while transiting to [nonWaiting] and duration is very short.
enum _ALDownloaderTaskWaitingPhase { nonWaiting, transiting, waiting }

/// An enumeration extension of inner status
extension _ALDownloaderInnerStatusExtension on _ALDownloaderInnerStatus {
  String get alDescription => const [
        'prepared',
        'undefined',
        'enqueued',
        'running',
        'complete',
        'failed',
        'canceled',
        'paused',
        'pretendedPaused',
        'deprecated'
      ][index];
}
