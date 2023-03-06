import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:queue/queue.dart';
import '../ALDownloaderHandlerInterface.dart';
import '../ALDownloaderStatus.dart';
import '../ALDownloaderTypeDefine.dart';
import '../internal/ALDownloaderConstant.dart';
import '../internal/ALDownloaderFileManagerDefault.dart';
import '../internal/ALDownloaderHeader.dart';
import '../internal/ALDownloaderInnerStatus.dart';
import '../internal/ALDownloaderIsolateLauncher.dart';
import '../internal/ALDownloaderMapExtension.dart';
import '../internal/ALDownloaderMessage.dart';
import '../internal/ALDownloaderPrint.dart';
import '../internal/ALDownloaderPrintConfig.dart';
import '../internal/ALDownlaoderStringExtension.dart';
import '../internal/ALDownloaderTask.dart';
import '../internal/ALDownloaderTaskWaitingPhase.dart';
import 'ALDownloaderFileManagerIMP.dart';

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
      {String? directoryPath,
      String? fileName,
      Map<String, String>? headers,
      bool redownloadIfNeeded = false,
      ALDownloaderHandlerInterface? downloaderHandlerInterface}) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kDownload;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kUrl: url,
      ALDownloaderConstant.kDirectoryPath: directoryPath,
      ALDownloaderConstant.kFileName: fileName,
      ALDownloaderConstant.kHeaders: headers,
      ALDownloaderConstant.kRedownloadIfNeeded: redownloadIfNeeded,
    };

    ALDownloaderHandlerInterfaceId? id;
    if (downloaderHandlerInterface != null) {
      id = ALDownloaderHeader.uuid.v1();
      _idDynamicKVs[id] = downloaderHandlerInterface;
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
    _idDynamicKVs[id] = downloaderHandlerInterface;
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
    _idDynamicKVs[id] = downloaderHandlerInterface;
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

  static Future<ALDownloaderStatus> getStatusForUrl(String url) async {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kGetStatusForUrl;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<ALDownloaderStatus>();
    _idDynamicKVs[id] =
        (ALDownloaderStatus status) => aCompleter.complete(status);

    message.content[ALDownloaderConstant.kStatusHandlerId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static Future<double> getProgressForUrl(String url) async {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kGetProgressForUrl;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<double>();
    _idDynamicKVs[id] = (double progress) => aCompleter.complete(progress);

    message.content[ALDownloaderConstant.kProgressHandlerId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static void cDownload(String url,
      {String? directoryPath,
      String? fileName,
      Map<String, String>? headers,
      bool redownloadIfNeeded = false,
      ALDownloaderHandlerInterface? downloaderHandlerInterface}) {
    String? id;
    if (downloaderHandlerInterface != null) {
      id = ALDownloaderHeader.uuid.v1();
      _idDynamicKVs[id] = downloaderHandlerInterface;
    }

    _qDownload(url,
        directoryPath: directoryPath,
        fileName: fileName,
        headers: headers,
        redownloadIfNeeded: redownloadIfNeeded,
        downloaderHandlerInterfaceId: id);
  }

  static ALDownloaderHandlerInterfaceId cAddDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final id = ALDownloaderHeader.uuid.v1();
    _idDynamicKVs[id] = downloaderHandlerInterface;

    _qAddDownloaderHandlerInterface(id, url, isInner: false);

    return id;
  }

  static void cAddForeverDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final id = ALDownloaderHeader.uuid.v1();
    _idDynamicKVs[id] = downloaderHandlerInterface;
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

  static ALDownloaderStatus cGetStatusForUrl(String url) =>
      _getStatusForUrl(url);

  static void cGetProgressForUrl(String url) => _getProgressForUrl(url);

  static void _launchALIsolate() =>
      ALDownloaderIsolateLauncher.launchALIsolate();

  static void _qInitialize() {
    _queue.add(() async {
      await _initialize();
      ALDownloaderHeader.initializedCompleter.complete();
    });
  }

  static void _qDownload(String url,
      {String? directoryPath,
      String? fileName,
      Map<String, String>? headers,
      bool redownloadIfNeeded = false,
      String? downloaderHandlerInterfaceId,
      bool isNeedUpdateInputs = true}) {
    _queue.add(() => _download(url,
        directoryPath: directoryPath,
        fileName: fileName,
        headers: headers,
        redownloadIfNeeded: redownloadIfNeeded,
        downloaderHandlerInterfaceId: downloaderHandlerInterfaceId,
        isNeedUpdateInputs: isNeedUpdateInputs));
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
    });
  }

  static void _qPause(String url) => _queue.add(() => _pause(url));

  static void _qPauseUrls(List<String> urls) =>
      _queue.add(() => _pauseUrls(urls));

  static void _qPauseAll() => _queue.add(() => _pauseAll());

  static void _qCancel(String url) => _queue.add(() => _cancel(url));

  static void _qCancelUrls(List<String> urls) =>
      _queue.add(() => _cancelUrls(urls));

  static void _qCancelAll() => _queue.add(() => _cancelAll());

  static void _qRemove(String url) => _queue.add(() => _remove(url));

  static void _qRemoveUrls(List<String> urls) =>
      _queue.add(() => _removeUrls(urls));

  static void _qRemoveAll() => _queue.add(() => _removeAll());

  static void _dGetStatusForUrl(String statusHandlerId, String url) {
    final status = _getStatusForUrl(url);
    _processStatusHandlerOnComingRootIsolate(statusHandlerId, status);
  }

  static void _dGetProgressForUrl(String progressHandlerId, String url) {
    final progress = _getProgressForUrl(url);
    _processProgressHandlerOnComingRootIsolate(progressHandlerId, progress);
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
      {String? directoryPath,
      String? fileName,
      Map<String, String>? headers,
      bool redownloadIfNeeded = false,
      String? downloaderHandlerInterfaceId,
      bool isNeedUpdateInputs = true}) async {
    if (downloaderHandlerInterfaceId != null) {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterfaceId, false);
      _addBinder(url, aBinder);
    }

    ALDownloaderTask? task = _getTaskFromUrl(url);

    if (task == null)
      task = _addOrUpdateTaskForUrl(url, '', ALDownloaderInnerStatus.prepared,
          0, null, null, ALDownloaderTaskWaitingPhase.unwaiting);

    if (isNeedUpdateInputs &&
        (task.innerStatus == ALDownloaderInnerStatus.prepared ||
            redownloadIfNeeded)) {
      task.willParameters = {
        'headers': headers,
        'directoryPath': directoryPath,
        'fileName': fileName,
        'redownloadIfNeeded': redownloadIfNeeded
      };
    }

    if (_isLimitedForGoingTasks) {
      if (task.innerStatus == ALDownloaderInnerStatus.prepared ||
          task.innerStatus == ALDownloaderInnerStatus.pretendedPaused ||
          task.innerStatus == ALDownloaderInnerStatus.deprecated ||
          task.innerStatus == ALDownloaderInnerStatus.canceled ||
          task.innerStatus == ALDownloaderInnerStatus.failed ||
          task.innerStatus == ALDownloaderInnerStatus.paused) {
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

    final willParameters = task.willParameters;
    String? willDirectoryPath = willParameters?['directoryPath'];
    String? willFileName = willParameters?['fileName'];
    final Map<String, String>? willHeaders = willParameters?['headers'];
    final bool redownloadIfNeededInConsumable =
        willParameters?['redownloadIfNeeded'] ?? false;

    if (willDirectoryPath == null || willFileName == null) {
      willDirectoryPath =
          await ALDownloaderFileManagerDefault.getVirtualDirectoryPathForUrl(
              url);
      willFileName = ALDownloaderFileManagerDefault.getFileNameForUrl(url);
    } else {
      if (!willDirectoryPath.endsWith('/'))
        willDirectoryPath = willDirectoryPath + '/';
    }

    if (await _isShouldRemoveData(task, willHeaders, willDirectoryPath,
        willFileName, redownloadIfNeededInConsumable)) {
      await _removeTask(task);
    }

    if (task.innerStatus == ALDownloaderInnerStatus.prepared ||
        task.innerStatus == ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == ALDownloaderInnerStatus.deprecated) {
      aldDebugPrint(
          'ALDownloader | try to download url, url status is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}');

      final alist = await _generateDownloadConfig(task, willDirectoryPath,
          willFileName, willHeaders, redownloadIfNeeded);

      final fSavedDir = alist[0];
      final fFileName = alist[1];
      final fHeaders = alist[2];

      // Enqueue a task.
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: fSavedDir,
          fileName: fFileName,
          headers: fHeaders ?? const {},
          showNotification: false,
          openFileFromNotification: false);

      if (taskId != null) {
        aldDebugPrint(
            'ALDownloader | try to download url, a download task of url generates succeeded, url = $url, taskId = $taskId, innerStatus = enqueued');

        _addOrUpdateTaskForUrl(url, taskId, ALDownloaderInnerStatus.enqueued, 0,
            fSavedDir, fFileName, task.waitingPhase);
        task.headers = fHeaders;
        task.redownloadIfNeeded = redownloadIfNeededInConsumable;

        _callProgressHandler(url, 0);
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, but a download task of url generates failed, url = $url, taskId = null');
      }
    } else if (task.innerStatus == ALDownloaderInnerStatus.complete) {
      aldDebugPrint(
          'ALDownloader | try to download url, but url status is succeeded, url = $url, taskId = ${task.taskId}');

      _callSucceededHandler(task.url, task.double_progress);
    } else if (task.innerStatus == ALDownloaderInnerStatus.canceled ||
        task.innerStatus == ALDownloaderInnerStatus.failed) {
      final previousTaskId = task.taskId;
      final previousStatusDescription = task.innerStatus.alDescription;

      final taskIdForRetry = await FlutterDownloader.retry(taskId: task.taskId);

      if (taskIdForRetry != null) {
        final progress = task.progress;

        _addOrUpdateTaskForUrl(
            url,
            taskIdForRetry,
            ALDownloaderInnerStatus.enqueued,
            progress,
            task.savedDir,
            task.fileName,
            task.waitingPhase);

        _processProgressEventForTask(task);

        aldDebugPrint(
            'ALDownloader | try to download url, url status is $previousStatusDescription previously and retries succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForRetry, innerStatus = enqueued');
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, url status is $previousStatusDescription previously but retries failed, url = $url, previous taskId = $previousTaskId, taskId = null');
      }
    } else if (task.innerStatus == ALDownloaderInnerStatus.paused) {
      final previousTaskId = task.taskId;

      final taskIdForResumption =
          await FlutterDownloader.resume(taskId: task.taskId);
      if (taskIdForResumption != null) {
        aldDebugPrint(
            'ALDownloader | try to download url, url status is paused previously and resumes succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForResumption');

        _addOrUpdateTaskForUrl(
            url,
            taskIdForResumption,
            Platform.isAndroid
                ? ALDownloaderInnerStatus.paused
                : ALDownloaderInnerStatus.running,
            task.progress,
            task.savedDir,
            task.fileName,
            task.waitingPhase);
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, url status is paused previously but resumes failed, url = $url, previous taskId = $previousTaskId, taskId = null');
      }
    } else if (task.innerStatus == ALDownloaderInnerStatus.running) {
      aldDebugPrint(
          'ALDownloader | try to download url, but url status is running, url may re-download after being paused, url = $url, taskId = ${task.taskId}');

      task.isMayRedownloadAboutPause = true;
    } else {
      aldDebugPrint(
          'ALDownloader | try to download url, but url status is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}');
    }
  }

  static Future<void> _pause(String url) async {
    try {
      ALDownloaderTask? task = _getTaskFromUrl(url);

      aldDebugPrint(
          'ALDownloader | _pause, url = $url, url status is ${task?.innerStatus.alDescription}');

      if (task == null) return;

      final taskId = task.taskId;

      if (task.innerStatus == ALDownloaderInnerStatus.enqueued) {
        await _pauseTaskPretendedlyWithCallHandler(task);
      } else if (task.innerStatus == ALDownloaderInnerStatus.running) {
        if (Platform.isAndroid) {
          if (ALDownloaderFileManagerIMP.cIsExistPhysicalFilePath(
              task.filePath)) {
            await FlutterDownloader.pause(taskId: taskId);
            task.isMayRedownloadAboutPause = false;
          } else {
            await _pauseTaskPretendedlyWithCallHandler(task);
          }
        } else {
          await FlutterDownloader.pause(taskId: taskId);
          task.isMayRedownloadAboutPause = false;
        }
      } else if (task.waitingPhase == ALDownloaderTaskWaitingPhase.transiting ||
          task.waitingPhase == ALDownloaderTaskWaitingPhase.waiting) {
        if (task.innerStatus == ALDownloaderInnerStatus.paused ||
            task.innerStatus == ALDownloaderInnerStatus.pretendedPaused) {
          _processPausedEventForTask(task);
          task.isMayRedownloadAboutPause = false;
        } else {
          await _pauseTaskPretendedlyWithCallHandler(task);
        }
      } else if (task.innerStatus == ALDownloaderInnerStatus.paused ||
          task.innerStatus == ALDownloaderInnerStatus.pretendedPaused) {
        _callPausedHandler(task.url, task.double_progress);
        task.isMayRedownloadAboutPause = false;
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _pause, url = $url, error: $error');
    }
  }

  static Future<void> _pauseUrls(List<String> urls) async {
    for (final url in urls) _transitUrl(url);
    for (final url in urls) await _pause(url);
  }

  static Future<void> _pauseAll() async {
    for (final task in _tasks) _transitTask(task);
    for (final task in _tasks) await _pause(task.url);
  }

  static Future<void> _cancel(String url) async {
    try {
      final task = _getTaskFromUrl(url);

      aldDebugPrint(
          'ALDownloader | _cancel, url = $url, url status is ${task?.innerStatus.alDescription}');

      if (task == null) return;

      if (task.waitingPhase == ALDownloaderTaskWaitingPhase.transiting ||
          task.waitingPhase == ALDownloaderTaskWaitingPhase.waiting ||
          task.innerStatus == ALDownloaderInnerStatus.enqueued ||
          task.innerStatus == ALDownloaderInnerStatus.running) {
        await _removeTaskWithCallHandler(task);
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _cancel, url = $url, error: $error');
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
          'ALDownloader | _remove, url = $url, url status is ${task?.innerStatus.alDescription}');

      if (task == null) return;

      await _removeTaskWithCallHandler(task);
    } catch (error) {
      aldDebugPrint('ALDownloader | _remove, url = $url, error: $error');
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

  static ALDownloaderStatus _getStatusForUrl(String url) {
    ALDownloaderStatus status;

    final task = _getTaskFromUrl(url);

    if (task == null) {
      status = ALDownloaderStatus.unstarted;
    } else {
      final innerStatus = task.innerStatus;
      if (task.waitingPhase == ALDownloaderTaskWaitingPhase.transiting ||
          task.waitingPhase == ALDownloaderTaskWaitingPhase.waiting) {
        // ALDownloaderTaskWaitingPhase.transiting and ALDownloaderTaskWaitingPhase.waiting as downloading
        status = ALDownloaderStatus.downloading;
      } else if (innerStatus == ALDownloaderInnerStatus.prepared ||
          innerStatus == ALDownloaderInnerStatus.undefined ||
          innerStatus == ALDownloaderInnerStatus.deprecated) {
        status = ALDownloaderStatus.unstarted;
      } else if (innerStatus == ALDownloaderInnerStatus.enqueued ||
          innerStatus == ALDownloaderInnerStatus.running) {
        status = ALDownloaderStatus.downloading;
      } else if (innerStatus == ALDownloaderInnerStatus.canceled ||
          innerStatus == ALDownloaderInnerStatus.failed) {
        status = ALDownloaderStatus.failed;
      } else if (innerStatus == ALDownloaderInnerStatus.pretendedPaused ||
          innerStatus == ALDownloaderInnerStatus.paused) {
        status = ALDownloaderStatus.paused;
      } else {
        status = ALDownloaderStatus.succeeded;
      }
    }

    return status;
  }

  static double _getProgressForUrl(String url) {
    final task = _getTaskFromUrl(url);

    // ignore: non_constant_identifier_names
    double double_progress = task == null ? 0 : task.double_progress;

    return double_progress;
  }

  static Future<List<dynamic>> _generateDownloadConfig(
      ALDownloaderTask task,
      String willDirectoryPath,
      String willFileName,
      Map<String, String>? willHeaders,
      bool redownloadIfNeeded) async {
    String fSavedDir;
    String fFileName;
    Map<String, String>? fHeaders;

    final cSavedDir = task.savedDir;
    final cFileName = task.fileName;
    final cHeaders = task.headers;

    if (cSavedDir != null && cFileName != null) {
      fSavedDir = cSavedDir;
      fFileName = cFileName;
      fHeaders = cHeaders;
    } else {
      final model = await ALDownloaderFileManagerIMP.cLazyGetPathModel(
          willDirectoryPath, willFileName);

      fSavedDir = model.directoryPath;
      fFileName = model.fileName;
      fHeaders = willHeaders;
    }

    return [fSavedDir, fFileName, fHeaders];
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
  static ALDownloaderTask _addOrUpdateTaskForUrl(
      String? url,
      String taskId,
      ALDownloaderInnerStatus innerStatus,
      int progress,
      String? savedDir,
      String? fileName,
      ALDownloaderTaskWaitingPhase waitingPhase) {
    if (url == null)
      throw 'ALDownloader | _addOrUpdateTaskForUrl, error: url is null';

    ALDownloaderTask? task;

    try {
      task = _tasks.firstWhere((element) => element.url == url);
      task.savedDir = savedDir;
      task.fileName = fileName;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;
      task.waitingPhase = waitingPhase;
    } catch (error) {
      aldDebugPrint('ALDownloader | _addOrUpdateTaskForUrl, error: $error');
    }

    if (task == null) {
      task = ALDownloaderTask(url);
      task.savedDir = savedDir;
      task.fileName = fileName;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;
      task.waitingPhase = waitingPhase;
      task.pIndex = _tasks.length;

      _tasks.add(task);
    }

    if (task.innerStatus == ALDownloaderInnerStatus.enqueued ||
        task.innerStatus == ALDownloaderInnerStatus.running) {
      if (!_goingTasks.contains(task)) _goingTasks.add(task);
    } else {
      if (_goingTasks.contains(task)) _goingTasks.remove(task);
    }

    return task;
  }

  /// Do work on root isolate
  static void doWorkOnRootIsolate(ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;
    if (action == ALDownloaderConstant.kCallInterface) {
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
      final inteface = _idDynamicKVs[id];

      ALDownloaderHeader.callDownloaderHandlerInterface(
          inteface,
          isNeedCallProgressHandler,
          isNeedCallSucceededHandler,
          isNeedCallFailedHandler,
          isNeedCallPausedHandler,
          progress);

      if (isNeedRemoveInterface) _idDynamicKVs.remove(id);
    } else if (action == ALDownloaderConstant.kCallStatusHandler) {
      final id = content[ALDownloaderConstant.kStatusHandlerId];
      final status = content[ALDownloaderConstant.kStatus];
      final handler = _idDynamicKVs[id];

      if (handler != null) handler(status);

      _idDynamicKVs.remove(id);
    } else if (action == ALDownloaderConstant.kCallProgressHandler) {
      final id = content[ALDownloaderConstant.kProgressHandlerId];
      final progress = content[ALDownloaderConstant.kProgress];
      final handler = _idDynamicKVs[id];

      if (handler != null) handler(progress);

      _idDynamicKVs.remove(id);
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
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _qAddDownloaderHandlerInterface(id, url);
    } else if (action ==
        ALDownloaderConstant.kAddForeverDownloaderHandlerInterface) {
      final url = content[ALDownloaderConstant.kUrl];
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _qAddForeverDownloaderHandlerInterface(id, url);
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
      final directoryPath = content[ALDownloaderConstant.kDirectoryPath];
      final fileName = content[ALDownloaderConstant.kFileName];
      final headers = content[ALDownloaderConstant.kHeaders];
      final redownloadIfNeeded =
          content[ALDownloaderConstant.kRedownloadIfNeeded];
      _qDownload(url,
          directoryPath: directoryPath,
          fileName: fileName,
          headers: headers,
          redownloadIfNeeded: redownloadIfNeeded,
          downloaderHandlerInterfaceId: downloaderHandlerInterfaceId);
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
    } else if (action == ALDownloaderConstant.kGetStatusForUrl) {
      final id = content[ALDownloaderConstant.kStatusHandlerId];
      final url = content[ALDownloaderConstant.kUrl];
      _dGetStatusForUrl(id, url);
    } else if (action == ALDownloaderConstant.kGetProgressForUrl) {
      final id = content[ALDownloaderConstant.kProgressHandlerId];
      final url = content[ALDownloaderConstant.kUrl];
      _dGetProgressForUrl(id, url);
    }
  }

  /// Register service which is used for that communication between [FlutterDownloader] isolate and ALDownloader isolate by [IsolateNameServer]
  static void _registerServiceForCommunicationBetweenFAndAL() {
    final receivePort = ReceivePort();

    IsolateNameServer.registerPortWithName(
        receivePort.sendPort, _kPortForFToAL);
    receivePort.listen((dynamic data) {
      try {
        final taskId = data[0];

        final originalStatusValue = data[1];
        final originalStatus = DownloadTaskStatus(originalStatusValue);

        final progress = data[2];

        _processDataFromFPort(taskId, originalStatus, progress);
      } catch (error) {
        aldDebugPrint(
            'ALDownloader | _registerServiceForCommunicationBetweenFAndAL | listen | error: $error',
            isFrequentPrint: true);
      }
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

    ALDownloaderInnerStatus innerStatus = _transferStatus(originalStatus);

    final task = _getTaskFromTaskId(taskId);

    if (task == null) {
      aldDebugPrint(
          'ALDownloader | _processDataFromFPort, the function return, because task is not found, taskId = $taskId');
      return;
    }

    if (task.innerStatus == ALDownloaderInnerStatus.prepared ||
        task.innerStatus == ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == ALDownloaderInnerStatus.deprecated) {
      aldDebugPrint(
          'ALDownloader | _processDataFromFPort, the function return, because task is ${task.innerStatus.alDescription}, taskId = $taskId');
      return;
    }

    final url = task.url;

    _addOrUpdateTaskForUrl(url, taskId, innerStatus, progress, task.savedDir,
        task.fileName, task.waitingPhase);

    _callHandlerForBusiness1(task);

    if (task.isMayRedownloadAboutPause &&
        task.innerStatus == ALDownloaderInnerStatus.paused) {
      task.isMayRedownloadAboutPause = false;
      _qDownload(url, isNeedUpdateInputs: false);
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

        final task = ALDownloaderTask(originalUrl);
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
            await _isShouldRemoveDataForInitialization(task);
        if (isShouldRemoveDataForSavedDir) {
          await _removeTask(task);
        }

        aldDebugPrint(
            'ALDownloader | _loadTasks, url = ${task.url}, taskId = ${task.taskId}, innerStatus = ${task.innerStatus}, isShouldRemoveDataForSavedDir = $isShouldRemoveDataForSavedDir');
      }

      aldDebugPrint(
          'ALDownloader | _loadTasks, tasks length = ${_tasks.length}');

      for (final task in _tasks) {
        if (task.innerStatus == ALDownloaderInnerStatus.deprecated) {
          _processFailedEventForUrlProgress(task.url, 0);
        } else {
          // If the task is normal, call handler directly.
          _callHandlerForBusiness1(task);
        }
      }
    }
  }

  /// Call handler for business 1
  static void _callHandlerForBusiness1(ALDownloaderTask task) {
    final innerStatus = task.innerStatus;
    if (innerStatus == ALDownloaderInnerStatus.enqueued ||
        innerStatus == ALDownloaderInnerStatus.running) {
      _processProgressEventForTask(task);
    } else if (innerStatus == ALDownloaderInnerStatus.complete) {
      _processSucceededEventForTask(task);
    } else if (innerStatus == ALDownloaderInnerStatus.canceled ||
        innerStatus == ALDownloaderInnerStatus.failed) {
      _processFailedEventForUrlProgress(task.url, -0.01);
    } else if (innerStatus == ALDownloaderInnerStatus.paused) {
      _processPausedEventForTask(task);
    }
  }

  /// Verify data and then determine whether to delete data from disk
  ///
  /// for initialization
  static Future<bool> _isShouldRemoveDataForInitialization(
      ALDownloaderTask task) async {
    final url = task.url;
    final innerStatus = task.innerStatus;
    final filePath = task.filePath;

    if (innerStatus == ALDownloaderInnerStatus.prepared) return false;

    if (filePath != null && filePath.contains('/al_flutter/')) {
      if (!(await ALDownloaderFileManagerDefault.isInRootPathForPath(filePath)))
        return true;

      final shouldFilePath =
          await ALDownloaderFileManagerDefault.getVirtualFilePathForUrl(url);
      if (filePath != shouldFilePath) return true;
    }

    bool aBool = innerStatus == ALDownloaderInnerStatus.enqueued ||
        innerStatus == ALDownloaderInnerStatus.running;

    if (!aBool) {
      if (innerStatus == ALDownloaderInnerStatus.complete ||
          innerStatus == ALDownloaderInnerStatus.paused) {
        aBool =
            !(ALDownloaderFileManagerIMP.cIsExistPhysicalFilePath(filePath));
      } else {
        aBool = false;
      }
    }

    return aBool;
  }

  /// Verify data and then determine whether to delete data from disk
  static Future<bool> _isShouldRemoveData(
      ALDownloaderTask task,
      Map? willHeaders,
      String willSavedDir,
      String willFileName,
      bool redownloadIfNeeded) async {
    final savedDir = task.savedDir;
    final finaName = task.fileName;
    final innerStatus = task.innerStatus;
    final filePath = task.filePath;
    final headers = task.headers;

    if (innerStatus == ALDownloaderInnerStatus.prepared) return false;

    if (redownloadIfNeeded) {
      final isSameSavedDir =
          ALDownloaderStringExtension.isEqualTwoString(savedDir, willSavedDir);

      final isSameFileName =
          ALDownloaderStringExtension.isEqualTwoString(finaName, willFileName);

      final isSameHeaders =
          ALDownloaderMapExtension.isEqualTwoMap(headers, willHeaders);

      if (!isSameSavedDir || !isSameFileName || !isSameHeaders) return true;
    }

    if (innerStatus == ALDownloaderInnerStatus.pretendedPaused) return false;

    if (filePath != null && filePath.contains('/al_flutter/')) {
      if (!(await ALDownloaderFileManagerDefault.isInRootPathForPath(filePath)))
        return true;
    }

    bool aBool;
    if (innerStatus == ALDownloaderInnerStatus.complete ||
        innerStatus == ALDownloaderInnerStatus.paused) {
      aBool = !ALDownloaderFileManagerIMP.cIsExistPhysicalFilePath(filePath);
    } else {
      aBool = false;
    }

    return aBool;
  }

  /// Get task from custom download tasks by [url]
  static ALDownloaderTask? _getTaskFromUrl(String url) {
    ALDownloaderTask? task;
    try {
      task = _tasks.firstWhere((element) => url == element.url);
    } catch (error) {
      aldDebugPrint('ALDownloader | _getTaskFromUrl, error: $error');
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
      aldDebugPrint('ALDownloader | _getTaskIdWith, error: $error');
    }
    return taskId;
  }

  /// Get task from custom download tasks by [taskId]
  // ignore: unused_element
  static ALDownloaderTask? _getTaskFromTaskId(String taskId) {
    ALDownloaderTask? task;
    try {
      task = _tasks.firstWhere((element) => taskId == element.taskId);
    } catch (error) {
      aldDebugPrint('ALDownloader | _getTaskFromTaskId, error: $error');
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
      aldDebugPrint('ALDownloader | _getUrlWithTaskId, error: $error');
    }
    return url;
  }

  static bool get _isLimitedForGoingTasks {
    final isLimited = _goingTasks.length >= _kMaxConcurrentTaskCount;
    return isLimited;
  }

  static Future<void> _pauseTaskPretendedlyWithCallHandler(
      ALDownloaderTask task) async {
    await _pauseTaskPretendedly(task);

    _processPausedEventForTask(task);
  }

  static Future<void> _pauseTaskPretendedly(ALDownloaderTask task) async {
    final taskId = task.taskId;

    _addOrUpdateTaskForUrl(
        task.url,
        taskId,
        ALDownloaderInnerStatus.pretendedPaused,
        0,
        task.savedDir,
        task.fileName,
        task.waitingPhase);

    task.isMayRedownloadAboutPause = false;

    if (taskId.length > 0)
      await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static Future<void> _removeTaskWithCallHandler(ALDownloaderTask task) async {
    final url = task.url;

    await _removeTask(task);

    _processFailedEventForUrlProgress(url, 0);
  }

  static Future<void> _removeTask(ALDownloaderTask task) async {
    final taskId = task.taskId;

    _addOrUpdateTaskForUrl(task.url, taskId, ALDownloaderInnerStatus.deprecated,
        0, null, null, task.waitingPhase);

    task.willParameters = null;
    task.headers = null;
    task.redownloadIfNeeded = false;
    task.isMayRedownloadAboutPause = false;

    if (taskId.length > 0)
      await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static void _processProgressEventForTask(ALDownloaderTask task) {
    _callProgressHandler(task.url, task.double_progress);
  }

  static void _processSucceededEventForTask(ALDownloaderTask task) {
    _unwaitTask(task);
    _callSucceededHandler(task.url, task.double_progress);
    _downloadWaitingTasks();
  }

  // ignore: unused_element
  static void _processFailedEventForTask(ALDownloaderTask task) {
    _unwaitTask(task);
    _callFailedHandler(task.url, task.double_progress);
    _downloadWaitingTasks();
  }

  static void _processPausedEventForTask(ALDownloaderTask task) {
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

  /// Call interface for all isolates
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

  static void _processStatusHandlerOnComingRootIsolate(
      String statusHandlerId, ALDownloaderStatus status) {
    ALDownloaderHeader.processStatusHandlerOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderIMP, statusHandlerId, status);
  }

  static void _processProgressHandlerOnComingRootIsolate(
      String progressHandlerId, double progress) {
    ALDownloaderHeader.processProgressHandlerOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderIMP, progressHandlerId, progress);
  }

  static void _processDownloaderHandlerInterfaceOnCurrentIsolate(
      String downloaderHandlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress) {
    final downloaderHandlerInterface =
        _idDynamicKVs[downloaderHandlerInterfaceId];
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

  static bool _isWaitingTask(ALDownloaderTask? task) {
    return task?.waitingPhase == ALDownloaderTaskWaitingPhase.waiting;
  }

  // ignore: unused_element
  static void _waitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _waitTask(task);
  }

  static void _waitTask(ALDownloaderTask? task) {
    _assignTaskWaitingPhase(task, ALDownloaderTaskWaitingPhase.waiting);
  }

  static void _transitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _transitTask(task);
  }

  static void _transitTask(ALDownloaderTask? task) {
    if (!_isWaitingTask(task)) return;

    _assignTaskWaitingPhase(task, ALDownloaderTaskWaitingPhase.transiting);
  }

  static void _unwaitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _unwaitTask(task);
  }

  static void _unwaitTask(ALDownloaderTask? task) {
    _assignTaskWaitingPhase(task, ALDownloaderTaskWaitingPhase.unwaiting);
  }

  static void _assignTaskWaitingPhase(
      ALDownloaderTask? task, ALDownloaderTaskWaitingPhase waitingPhase) {
    if (task == null) return;

    _addOrUpdateTaskForUrl(task.url, task.taskId, task.innerStatus,
        task.progress, task.savedDir, task.fileName, waitingPhase);

    switch (waitingPhase) {
      case ALDownloaderTaskWaitingPhase.waiting:
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
        _qDownload(task.url, isNeedUpdateInputs: false);
      }
    }
  }

  static ALDownloaderInnerStatus _transferStatus(DownloadTaskStatus status) {
    if (status == DownloadTaskStatus.enqueued) {
      return ALDownloaderInnerStatus.enqueued;
    } else if (status == DownloadTaskStatus.running) {
      return ALDownloaderInnerStatus.running;
    } else if (status == DownloadTaskStatus.complete) {
      return ALDownloaderInnerStatus.complete;
    } else if (status == DownloadTaskStatus.failed) {
      return ALDownloaderInnerStatus.failed;
    } else if (status == DownloadTaskStatus.canceled) {
      return ALDownloaderInnerStatus.canceled;
    } else if (status == DownloadTaskStatus.paused) {
      return ALDownloaderInnerStatus.paused;
    }

    return ALDownloaderInnerStatus.undefined;
  }

  static void _addBinder(String url, _ALDownloaderBinder binder) {
    List<_ALDownloaderBinder>? binders = _urlBinderKVs[url];
    if (binders == null) {
      binders = <_ALDownloaderBinder>[];
      _urlBinderKVs[url] = binders;
    }
    binders.add(binder);
  }

  /// A dirty flag that [initialize] executed
  static bool _isInitialized = false;

  /// A map that key is id and value may be the fllowing type
  ///
  /// [ALDownloaderHandlerInterface], [ALDownloaderProgressHandler] and mores
  ///
  /// Key is generated by [ALDownloaderHeader.uuid].
  static final _idDynamicKVs = <String, dynamic>{};

  /// Send port for communication from [FlutterDownloader] isolate to ALDownloader isolate
  static final _kPortForFToAL = '_kPortForFToAL';

  /// ALDownloader event queue
  static final _queue = Queue();

  /// Custom download tasks
  static List<ALDownloaderTask> get _tasks => ALDownloaderHeader.tasks;

  /// Going download tasks
  static final _goingTasks = <ALDownloaderTask>[];

  /// Waiting download tasks
  static final _waitingTasks = <ALDownloaderTask>[];

  /// A map that key is url and value is binder list.
  static final _urlBinderKVs = <String, List<_ALDownloaderBinder>>{};

  /// Max concurrent task count
  static final _kMaxConcurrentTaskCount = 7;

  /// Privatize constructor
  ALDownloaderIMP._();
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
