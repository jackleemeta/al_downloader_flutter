import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:queue/queue.dart';
import 'ALDownloaderFileManagerIMP.dart';
import '../ALDownloaderHandlerInterface.dart';
import '../ALDownloaderStatus.dart';
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
      _configForIsolatesChores();
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

  static void download(String url,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface,
      Map<String, String> headers = const {}}) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kDownload;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kUrl: url,
      ALDownloaderConstant.kHeaders: headers
    };

    if (downloaderHandlerInterface != null) {
      final id = ALDownloaderHeader.uuid.v1();
      _interfaceKVs[id] = downloaderHandlerInterface;
      message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;
    }

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void addDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kAddDownloaderHandlerInterface;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();
    _interfaceKVs[id] = downloaderHandlerInterface;
    message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void addForeverDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kAddForeverDownloaderHandlerInterface;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();
    _interfaceKVs[id] = downloaderHandlerInterface;
    message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeDownloaderHandlerInterfaceForUrl(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action =
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForUrl;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeDownloaderHandlerInterfaceForAll() {
    _qRemoveDownloaderHandlerInterfaceForAll();
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
      final innerStatus = task?.innerStatus;

      if (innerStatus == null ||
          innerStatus == _ALDownloaderInnerStatus.prepared ||
          innerStatus == _ALDownloaderInnerStatus.undefined ||
          innerStatus == _ALDownloaderInnerStatus.deprecated ||
          innerStatus == _ALDownloaderInnerStatus.ignored)
        status = ALDownloaderStatus.unstarted;
      else if (innerStatus == _ALDownloaderInnerStatus.enqueued ||
          innerStatus == _ALDownloaderInnerStatus.running)
        status = ALDownloaderStatus.downloading;
      else if (innerStatus == _ALDownloaderInnerStatus.canceled ||
          innerStatus == _ALDownloaderInnerStatus.failed)
        status = ALDownloaderStatus.failed;
      else if (innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
          innerStatus == _ALDownloaderInnerStatus.paused ||
          innerStatus == _ALDownloaderInnerStatus.preparedPretendedPaused)
        status = ALDownloaderStatus.paused;
      else
        status = ALDownloaderStatus.succeeded;
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
      _interfaceKVs[id] = downloaderHandlerInterface;
    }

    _qDownload(url, downloaderHandlerInterfaceId: id, headers: headers);
  }

  static void cAddDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final id = ALDownloaderHeader.uuid.v1();
    _interfaceKVs[id] = downloaderHandlerInterface;

    _qAddDownloaderHandlerInterface(id, url);
  }

  static void cAddForeverDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    final id = ALDownloaderHeader.uuid.v1();
    _interfaceKVs[id] = downloaderHandlerInterface;
    _qAddForeverDownloaderHandlerInterface(id, url);
  }

  static void cRemoveDownloaderHandlerInterfaceForUrl(String url) =>
      _qRemoveDownloaderHandlerInterfaceForUrl(url);

  static void cPause(String url) => _qPause(url);

  static void cPauseAll() => _qPauseAll();

  static void cCancel(String url) => _qCancel(url);

  static void cCancelAll() => _qCancelAll();

  static void cRemove(String url) => _qRemove(url);

  static void cRemoveAll() => _qRemoveAll();

  static void _configForIsolatesChores() =>
      ALDownloaderIsolateLauncher.configForIsolatesChores();

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
    _ALDownloadTask? task = _getTaskFromUrl(url);

    if (task == null) {
      task = _addOrUpdateTaskForUrl(
          url, '', _ALDownloaderInnerStatus.prepared, 0, '', '');
    } else if (task.innerStatus == _ALDownloaderInnerStatus.deprecated ||
        task.innerStatus == _ALDownloaderInnerStatus.ignored) {
      _addOrUpdateTaskForUrl(
          url, '', _ALDownloaderInnerStatus.prepared, 0, '', '');
    } else if (task.innerStatus ==
        _ALDownloaderInnerStatus.preparedPretendedPaused) {
      _addOrUpdateTaskForUrl(
          url, '', _ALDownloaderInnerStatus.pretendedPaused, 0, '', '');
    }

    task.headers = headers;

    if (_isLimitedForGoingTasks) {
      if (!_waitingTasks.contains(task)) _waitingTasks.add(task);
      aldDebugPrint(
          'ALDownloader | in phase 1 | try to download url, but the going urls are limited, the url will download later, url = $url, taskId = ${task.taskId}');
      return;
    }

    final inputTask = task;

    _queue
        .add(() => _download(inputTask,
            downloaderHandlerInterfaceId: downloaderHandlerInterfaceId))
        .catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qDownload, error = $error');
    });
  }

  static void _qAddDownloaderHandlerInterface(
      String downloaderHandlerInterfaceId, String url) {
    _queue.add(() async {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterfaceId, false);
      _binders.add(aBinder);
    }).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qAddDownloaderHandlerInterface, error = $error');
    });
  }

  static void _qAddForeverDownloaderHandlerInterface(
      String downloaderHandlerInterfaceId, String url) {
    _queue.add(() async {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterfaceId, true);
      _binders.add(aBinder);
    }).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qAddForeverDownloaderHandlerInterface, error = $error');
    });
  }

  static void _qRemoveDownloaderHandlerInterfaceForUrl(String url) {
    _queue.add(() async {
      _binders.removeWhere((element) => url == element.url);
    }).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qRemoveDownloaderHandlerInterfaceForUrl, error = $error');
    });
  }

  static void _qRemoveDownloaderHandlerInterfaceForAll() {
    _queue.add(() async {
      _binders.clear();
    }).catchError((error) {
      aldDebugPrint(
          'ALDownloader | queue error | _qRemoveDownloaderHandlerInterfaceForAll, error = $error');
    });
  }

  static void _qPause(String url) {
    _preprocessSomeActionForUrl(url);

    _queue.add(() => _pause1(url)).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qPause, error = $error');
    });
  }

  static void _qPauseAll() {
    _preprocessSomeActionForAll();

    _queue.add(() => _pauseAll1()).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qPauseAll, error = $error');
    });
  }

  static void _qCancel(String url) {
    _preprocessSomeActionForUrl(url);

    _queue.add(() => _cancel1(url)).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qCancel, error = $error');
    });
  }

  static void _qCancelAll() {
    _preprocessSomeActionForAll();

    _queue.add(() => _cancelAll1()).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qCancelAll, error = $error');
    });
  }

  static void _qRemove(String url) {
    _preprocessSomeActionForUrl(url);

    _queue.add(() => _remove1(url)).catchError((error) {
      aldDebugPrint('ALDownloader | queue error | _qRemove, error = $error');
    });
  }

  static void _qRemoveAll() {
    _preprocessSomeActionForAll();

    _queue.add(() => _removeAll1()).catchError((error) {
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

    // Extract all current tasks from database and try to the execute the tasks.
    await _loadTasks();
  }

  static Future<void> _download(_ALDownloadTask task,
      {String? downloaderHandlerInterfaceId}) async {
    final url = task.url;

    if (downloaderHandlerInterfaceId != null) {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterfaceId, false);
      _binders.add(aBinder);
    }

    if (_isLimitedForGoingTasks) {
      if (!_waitingTasks.contains(task)) _waitingTasks.add(task);
      aldDebugPrint(
          'ALDownloader | in phase 2 | try to download url, going tasks are limited, those will download later, url = $url, taskId = ${task.taskId}');
      return;
    }

    if (await _isShouldRemoveData(
        url, task.innerStatus, task.savedDir, task.filePath))
      await _removeTask(task);

    if (task.innerStatus == _ALDownloaderInnerStatus.prepared ||
        task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
      final url = task.url;

      aldDebugPrint(
          'ALDownloader | try to download url, the url is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}');

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
            'ALDownloader | try to download url, a download task of the url generates succeeded, url = $url, taskId = $taskId, innerStatus = enqueued');

        _addOrUpdateTaskForUrl(url, taskId, _ALDownloaderInnerStatus.enqueued,
            0, directoryPath, fileName);

        _callProgressHandler(url, 0);
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, but a download task of the url generates failed, url = $url, taskId = null');
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.complete) {
      aldDebugPrint(
          'ALDownloader | try to download url, but the url is succeeded, url = $url, taskId = ${task.taskId}');

      // ignore: non_constant_identifier_names
      final int_progress = task.progress;
      // ignore: non_constant_identifier_names
      final double_progress =
          double.tryParse(((int_progress / 100).toStringAsFixed(2))) ?? 0;

      _callSucceededHandler(url, double_progress);
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
            task.fileName);

        // ignore: non_constant_identifier_names
        final double_progress =
            double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;

        _callProgressHandler(url, double_progress);

        aldDebugPrint(
            'ALDownloader | try to download url, the url is $previousStatusDescription previously and retries succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForRetry, innerStatus = enqueued');
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, the url is $previousStatusDescription previously but retries failed, url = $url, previous taskId = $previousTaskId, taskId = null');
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.paused) {
      final previousTaskId = task.taskId;

      final taskIdForResumption =
          await FlutterDownloader.resume(taskId: task.taskId);
      if (taskIdForResumption != null) {
        aldDebugPrint(
            'ALDownloader | try to download url, the url is paused previously and resumes succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForResumption');

        _addOrUpdateTaskForUrl(
            url,
            taskIdForResumption,
            _ALDownloaderInnerStatus.running,
            task.progress,
            task.savedDir,
            task.fileName);
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, the url is paused previously but resumes failed, url = $url, previous taskId = $previousTaskId, taskId = null');
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.running) {
      aldDebugPrint(
          'ALDownloader | try to download url, but the url is running, url may re-download after being paused, url = $url, taskId = ${task.taskId}');

      task.isMayRedownloadAboutPause = true;
    } else {
      aldDebugPrint(
          'ALDownloader | try to download url, but the url is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}');
    }
  }

  static Future<void> _pause1(String url) async {
    try {
      final task = _getTaskFromUrl(url);

      if (task == null) {
        aldDebugPrint(
            'ALDownloader | _pause1, url = $url, but url task is null');
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
        } else {
          aldDebugPrint(
              'ALDownloader | _pause1, url = $url, but url is ${task.innerStatus.alDescription}');
        }
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _pause1, url = $url, error = $error');
    }
  }

  static Future<void> _pauseAll1() async {
    final aTemp = <_ALDownloadTask>[];
    aTemp.addAll(_tasks);
    for (final task in aTemp) {
      final url = task.url;
      await _pause1(url);
    }
  }

  static Future<void> _cancel1(String url) async {
    try {
      final task = _getTaskFromUrl(url);

      if (task == null) {
        aldDebugPrint(
            'ALDownloader | _cancel1, url = $url, but url task is null');

        _addOrUpdateTaskForUrl(
            url, '', _ALDownloaderInnerStatus.deprecated, 0, '', '');
        _callFailedHandler(url, 0);
      } else {
        if (task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
          aldDebugPrint(
              'ALDownloader | _cancel1, url = $url, but url is deprecated');

          _addOrUpdateTaskForUrl(
              url, '', _ALDownloaderInnerStatus.deprecated, 0, '', '');
          _callFailedHandler(url, 0);
        } else if (task.innerStatus == _ALDownloaderInnerStatus.enqueued ||
            task.innerStatus == _ALDownloaderInnerStatus.running) {
          await _removeTaskWithCallHandler(task);
        }
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _cancel1, url = $url, error = $error');
    }
  }

  static Future<void> _cancelAll1() async {
    final aTemp = <_ALDownloadTask>[];
    aTemp.addAll(_tasks);
    for (final task in aTemp) {
      final url = task.url;
      await _cancel1(url);
    }
  }

  static Future<void> _remove1(String url) async {
    try {
      final task = _getTaskFromUrl(url);

      if (task == null) {
        aldDebugPrint(
            'ALDownloader | _remove1, url = $url, but url task is null');

        _addOrUpdateTaskForUrl(
            url, '', _ALDownloaderInnerStatus.deprecated, 0, '', '');

        _callFailedHandler(url, 0);
      } else {
        if (task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
          aldDebugPrint(
              'ALDownloader | _remove1, url = $url, but url is deprecated');

          _addOrUpdateTaskForUrl(
              url, '', _ALDownloaderInnerStatus.deprecated, 0, '', '');
          _callFailedHandler(url, 0);
        } else {
          await _removeTaskWithCallHandler(task);
        }
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _remove1, url = $url, error = $error');
    }
  }

  static Future<void> _removeAll1() async {
    final aTemp = <_ALDownloadTask>[];
    aTemp.addAll(_tasks);
    for (final task in aTemp) {
      final url = task.url;
      await _remove1(url);
    }
  }

  static void _preprocessSomeActionForUrl(String url) {
    final task = _getTaskFromUrl(url);
    if (task != null) _preprocessSomeActionForTask(task);
  }

  static void _preprocessSomeActionForAll() {
    for (final task in _tasks) _preprocessSomeActionForTask(task);
  }

  static void _preprocessSomeActionForTask(_ALDownloadTask task) {
    if (_waitingTasks.contains(task)) _waitingTasks.remove(task);

    final url = task.url;
    if (task.innerStatus == _ALDownloaderInnerStatus.prepared) {
      _addOrUpdateTaskForUrl(
          url, '', _ALDownloaderInnerStatus.ignored, 0, '', '');
    } else if (task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused) {
      _addOrUpdateTaskForUrl(
          url, '', _ALDownloaderInnerStatus.preparedPretendedPaused, 0, '', '');
    }
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
  ///
  /// Specially, [savedDir] does not update while be `null`, also [fileName]. It's reason that avoid real value replacing by `null` from [_processDataFromPort].
  static _ALDownloadTask _addOrUpdateTaskForUrl(
      String? url,
      String taskId,
      _ALDownloaderInnerStatus innerStatus,
      int progress,
      String? savedDir,
      String? fileName) {
    if (url == null)
      throw 'ALDownloader | _addOrUpdateTaskForUrl, error = url is null';

    _ALDownloadTask? task;

    try {
      task = _tasks.firstWhere((element) => element.url == url);
      if (savedDir != null) task.savedDir = savedDir;
      if (fileName != null) task.fileName = fileName;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;
    } catch (error) {
      aldDebugPrint('ALDownloader | _addOrUpdateTaskForUrl, error = $error');
    }

    if (task == null) {
      task = _ALDownloadTask(url);
      if (savedDir != null) task.savedDir = savedDir;
      if (fileName != null) task.fileName = fileName;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;

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
          task.progress, task.savedDir, task.fileName);
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
      final isNeedRemoveInterfaceAfterCallForRoot =
          content[ALDownloaderConstant.kIsNeedRemoveInterfaceAfterCallForRoot];
      final inteface = _interfaceKVs[id];
      ALDownloaderHeader.callInterfaceById(
          inteface,
          isNeedCallProgressHandler,
          isNeedCallSucceededHandler,
          isNeedCallFailedHandler,
          isNeedCallPausedHandler,
          progress);

      if (isNeedRemoveInterfaceAfterCallForRoot) _interfaceKVs.remove(id);
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

      _processDataFromPort(taskId, originalStatus, progress);
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
  static void _processDataFromPort(
      String taskId, DownloadTaskStatus originalStatus, int progress) {
    aldDebugPrint(
        'ALDownloader | _processDataFromPort | original, taskId = $taskId, original status = $originalStatus, original progress = $progress',
        isFrequentPrint: true);

    _ALDownloaderInnerStatus innerStatus = _transferStatus(originalStatus);

    final task = _getTaskFromTaskId(taskId);

    if (task == null) {
      aldDebugPrint(
          'ALDownloader | _processDataFromPort, the func return, because task is not found, taskId = $taskId');
      return;
    }

    if (task.innerStatus == _ALDownloaderInnerStatus.prepared ||
        task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == _ALDownloaderInnerStatus.deprecated ||
        task.innerStatus == _ALDownloaderInnerStatus.ignored ||
        task.innerStatus == _ALDownloaderInnerStatus.preparedPretendedPaused) {
      aldDebugPrint(
          'ALDownloader | _processDataFromPort, the func return, because task is ${task.innerStatus.alDescription}, taskId = $taskId');
      return;
    }

    final url = task.url;

    _addOrUpdateTaskForUrl(url, taskId, innerStatus, progress, null, null);

    // ignore: non_constant_identifier_names
    final double_progress =
        double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;

    _callHandlerForBusiness1(taskId, url, innerStatus, double_progress);

    if (task.isMayRedownloadAboutPause &&
        task.innerStatus == _ALDownloaderInnerStatus.paused) {
      task.isMayRedownloadAboutPause = false;
      _qDownload(url, headers: task.headers);
    }

    aldDebugPrint(
        'ALDownloader | _processDataFromPort | processed, taskId = $taskId, url = $url, innerStatus = $innerStatus, progress = $progress, double_progress = $double_progress',
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
        // ignore: non_constant_identifier_names
        final double_progress =
            double.tryParse(((task.progress / 100).toStringAsFixed(2))) ?? 0;
        if (task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
          _callFailedHandler(task.url, 0);
        } else {
          // If the task is normal, call handler directly.
          _callHandlerForBusiness1(
              task.taskId, task.url, task.innerStatus, double_progress);
        }
      }
    }
  }

  /// Call handler for business 1
  static void _callHandlerForBusiness1(
      String taskId,
      String url,
      _ALDownloaderInnerStatus innerStatus,
      // ignore: non_constant_identifier_names
      double double_progress) {
    if (innerStatus == _ALDownloaderInnerStatus.enqueued ||
        innerStatus == _ALDownloaderInnerStatus.running) {
      _callProgressHandler(url, double_progress);
    } else if (innerStatus == _ALDownloaderInnerStatus.complete) {
      _callSucceededHandler(url, double_progress);
    } else if (innerStatus == _ALDownloaderInnerStatus.canceled ||
        innerStatus == _ALDownloaderInnerStatus.failed) {
      _callFailedHandler(url, -0.01);
    } else if (innerStatus == _ALDownloaderInnerStatus.paused) {
      _callPausedHandler(url, double_progress);
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
    if (innerStatus == _ALDownloaderInnerStatus.prepared ||
        innerStatus == _ALDownloaderInnerStatus.ignored ||
        innerStatus == _ALDownloaderInnerStatus.preparedPretendedPaused)
      return false;
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
    if (innerStatus == _ALDownloaderInnerStatus.prepared ||
        innerStatus == _ALDownloaderInnerStatus.ignored ||
        innerStatus == _ALDownloaderInnerStatus.preparedPretendedPaused)
      return false;
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

  static Future<void> _removeTaskWithCallHandler(_ALDownloadTask task) async {
    final url = task.url;

    await _removeTask(task);

    _callFailedHandler(url, 0);
  }

  static Future<void> _removeTask(_ALDownloadTask task) async {
    final taskId = task.taskId;

    _addOrUpdateTaskForUrl(
        task.url,
        taskId,
        _ALDownloaderInnerStatus.deprecated,
        task.progress,
        task.savedDir,
        task.fileName);

    await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static Future<void> _pauseTaskPretendedlyWithCallHandler(
      _ALDownloadTask task) async {
    final url = task.url;

    await _pauseTaskPretendedly(task);

    // ignore: non_constant_identifier_names
    final double_progress =
        double.tryParse(((task.progress / 100).toStringAsFixed(2))) ?? 0;
    _callPausedHandler(url, double_progress);
  }

  static Future<void> _pauseTaskPretendedly(_ALDownloadTask task) async {
    final taskId = task.taskId;

    _addOrUpdateTaskForUrl(
        task.url,
        taskId,
        _ALDownloaderInnerStatus.pretendedPaused,
        task.progress,
        task.savedDir,
        task.fileName);

    await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static void _callProgressHandler(String url, double progress) {
    _binders.forEach((element) {
      if (element.url == url) {
        final downloaderHandlerInterfaceId =
            element.downloaderHandlerInterfaceId;
        _callInterface(
            downloaderHandlerInterfaceId, true, false, false, false, progress);
      }
    });
  }

  static void _callSucceededHandler(String url, double progress) {
    _binders.forEach((element) {
      if (element.url == url) {
        final downloaderHandlerInterfaceId =
            element.downloaderHandlerInterfaceId;
        _callInterface(
            downloaderHandlerInterfaceId, true, true, false, false, progress,
            isNeedRemoveInterfaceAfterCallForRoot: !element.isForever);
      }
    });

    _binders.removeWhere((element) => element.url == url && !element.isForever);

    _unwait(url);
    _downloadWaitingTasks();
  }

  static void _callFailedHandler(String url, double progress) {
    _binders.forEach((element) {
      if (element.url == url) {
        final downloaderHandlerInterfaceId =
            element.downloaderHandlerInterfaceId;
        _callInterface(
            downloaderHandlerInterfaceId, true, false, true, false, progress,
            isNeedRemoveInterfaceAfterCallForRoot: !element.isForever);
      }
    });

    _binders.removeWhere((element) => element.url == url && !element.isForever);

    _unwait(url);
    _downloadWaitingTasks();
  }

  static void _callPausedHandler(String url, double progress) {
    _binders.forEach((element) {
      if (element.url == url) {
        final downloaderHandlerInterfaceId =
            element.downloaderHandlerInterfaceId;
        if (progress > -0.01)
          _callInterface(downloaderHandlerInterfaceId, true, false, false,
              false, progress);

        _callInterface(
            downloaderHandlerInterfaceId, false, false, false, true, progress);
      }
    });

    _unwait(url);
    _downloadWaitingTasks();
  }

  /// call interface for all isolates
  static void _callInterface(
      String downloaderHandlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress,
      {bool isNeedRemoveInterfaceAfterCallForRoot = false}) {
    // Call interface for root isolate
    ALDownloaderHeader.callInterfaceFromALToRoot(
        ALDownloaderConstant.kALDownloaderIMP,
        downloaderHandlerInterfaceId,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress,
        isNeedRemoveInterfaceAfterCallForRoot:
            isNeedRemoveInterfaceAfterCallForRoot);

    // Call interface for current isolate
    _callInterfaceForCurrentIsolate(
        downloaderHandlerInterfaceId,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress);
  }

  static void _callInterfaceForCurrentIsolate(
      String downloaderHandlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress) {
    final inteface = _interfaceKVs[downloaderHandlerInterfaceId];
    ALDownloaderHeader.callInterfaceById(
        inteface,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress);
  }

  static void _unwait(String url) {
    final task = _getTaskFromUrl(url);
    if (_waitingTasks.contains(task)) _waitingTasks.remove(task);
  }

  static void _downloadWaitingTasks() {
    for (final element in _waitingTasks)
      _qDownload(element.url, headers: element.headers);
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

  /// A map for storaging interfaces
  ///
  /// Key is generated by [ALDownloaderHeader.uuid].
  static final _interfaceKVs = <String, ALDownloaderHandlerInterface>{};

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

  /// A binder list for binding element such as url, downloader interface, forever flag and so on
  static final _binders = <_ALDownloaderBinder>[];

  /// Max concurrent task count
  static final _kMaxConcurrentTaskCount = 10;

  /// Privatize constructor
  ALDownloaderIMP._();
}

/// A class of custom download task
class _ALDownloadTask {
  final String url;

  String savedDir = '';

  String fileName = '';

  String taskId = '';

  int progress = 0;

  Map<String, String> headers = const {};

  _ALDownloaderInnerStatus innerStatus = _ALDownloaderInnerStatus.undefined;

  bool isMayRedownloadAboutPause = false;

  String get filePath => savedDir + fileName;

  _ALDownloadTask(this.url);
}

/// A binder for binding element of url and downloader interface
///
/// It may bind more elements in the future.
class _ALDownloaderBinder {
  _ALDownloaderBinder(
      this.url, this.downloaderHandlerInterfaceId, this.isForever);
  final String url;
  final String downloaderHandlerInterfaceId;
  final bool isForever;
}

/// An enumeration of inner status
///
/// It is used to supplement some statuses for [DownloadTaskStatus].
///
/// **discussion**
///
/// It has supplemented the fllowing statuses at present.
///
/// [prepared], [deprecated], [pretendedPaused], [ignored], [preparedPretendedPaused]
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
  deprecated,
  ignored,
  preparedPretendedPaused
}

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
        'deprecated',
        'ignored',
        'preparedPretendedPaused'
      ][index];
}
