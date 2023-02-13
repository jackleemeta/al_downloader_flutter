import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:queue/queue.dart';
import 'ALDownloaderFileManagerIMP.dart';
import '../ALDownloaderHandlerInterface.dart';
import '../ALDownloaderStatus.dart';
import '../internal/ALDownloaderPrint.dart';

class ALDownloaderIMP {
  static void initialize() {
    _queue.add(() => _initialize()).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute _initialize, error = $error");
    });
  }

  static void download(String? url,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) {
    if (url == null)
      throw "ALDownloader | try to download url, but url is null";

    final task = _getTaskFromUrl(url);

    if (task == null ||
        task.innerStatus == _ALDownloaderInnerStatus.deprecated ||
        task.innerStatus == _ALDownloaderInnerStatus.ignored) {
      _addOrUpdateTaskForUrl(url, "", _ALDownloaderInnerStatus.prepared, 0, "");
    } else if (task.innerStatus ==
        _ALDownloaderInnerStatus.preparedPretendedPaused) {
      _addOrUpdateTaskForUrl(
          url, "", _ALDownloaderInnerStatus.pretendedPaused, 0, "");
    }

    _queue.add(() => _download(url)).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute _download, error = $error");
    });
  }

  static void addDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface, String? url) {
    _queue.add(() async {
      if (downloaderHandlerInterface == null || url == null) return;
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterface, false);
      _binders.add(aBinder);
    }).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute addDownloaderHandlerInterface, error = $error");
    });
  }

  static void addForeverDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface, String? url) {
    _queue.add(() async {
      if (downloaderHandlerInterface == null || url == null) return;
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterface, true);
      _binders.add(aBinder);
    }).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute addForeverDownloaderHandlerInterface, error = $error");
    });
  }

  static void removeDownloaderHandlerInterfaceForUrl(String url) {
    _queue.add(() async {
      _binders.removeWhere((element) => url == element.url);
    }).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute removeDownloaderHandlerInterfaceForUrl, error = $error");
    });
  }

  /// Remove all downloader handler interfaces
  static void removeDownloaderHandlerInterfaceForAll() {
    _queue.add(() async {
      _binders.clear();
    }).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute removeDownloaderHandlerInterfaceForAll, error = $error");
    });
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
      aldDebugPrint("ALDownloader | getStatusForUrl = $url, error = $error");
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
          "ALDownloader | get download progress for url = $url, error = $error");
    }

    return double_progress;
  }

  static void pause(String url) {
    _preprocessSomeActionForUrl(url);

    _queue.add(() => _pause1(url)).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute _pause1, error = $error");
    });
  }

  static void pauseAll() {
    _preprocessSomeActionForAll();

    _queue.add(() => _pauseAll1()).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute _pauseAll1, error = $error");
    });
  }

  static void cancel(String url) {
    _preprocessSomeActionForUrl(url);

    _queue.add(() => _cancel1(url)).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute _cancel1, error = $error");
    });
  }

  static void cancelAll() {
    _preprocessSomeActionForAll();

    _queue.add(() => _cancelAll1()).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute _cancelAll1, error = $error");
    });
  }

  static void remove(String url) {
    _preprocessSomeActionForUrl(url);

    _queue.add(() => _remove1(url)).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute _remove1, error = $error");
    });
  }

  static void removeAll() {
    _preprocessSomeActionForAll();

    _queue.add(() => _removeAll1()).catchError((error) {
      aldDebugPrint(
          "ALDownloader | queue error | execute _removeAll1, error = $error");
    });
  }

  static Future<void> _initialize() async {
    if (!_isInitial) {
      // Initialize FlutterDownloader.
      await FlutterDownloader.initialize(
        debug: false,
        ignoreSsl: true,
      );

      // Register the isolate communication service.
      _addIsolateNameServerPortService();

      // Register FlutterDownloader callback.
      await FlutterDownloader.registerCallback(_downloadCallback, step: 1);

      // Extract all current tasks from database and execute the tasks that need to execute.
      await _loadAndTryToRunTask();

      // a dirty flag that guarantees that this scope is executed only once
      _isInitial = true;
    }
  }

  static Future<void> _download(String url,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) async {
    if (downloaderHandlerInterface != null) {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterface, false);
      _binders.add(aBinder);
    }

    await _initialize();

    var task = _getTaskFromUrl(url);

    if (task != null) {
      if (await _isShouldRemoveData(task.savedDir, url, task.innerStatus)) {
        await _removeTask(task);
        task = null;
      }
    }

    if (task == null ||
        task.innerStatus == _ALDownloaderInnerStatus.prepared ||
        task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
      if (task == null) {
        aldDebugPrint(
            "ALDownloader | try to download url, the url is initial, url = $url, taskId = null");
      } else {
        aldDebugPrint(
            "ALDownloader | try to download url, the url is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}");
      }

      // Get 'physical directory path' and 'file name' of the file by url.
      final model =
          await ALDownloaderFileManagerIMP.lazyGetPathModelForUrl(url);

      final dir = model.dir;

      // Enqueue a task.
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: dir,
          fileName: model.fileName,
          showNotification: false,
          openFileFromNotification: false);

      if (taskId != null) {
        aldDebugPrint(
            "ALDownloader | try to download url, a download task of the url generates succeeded, url = $url, taskId = $taskId, innerStatus = enqueued");

        _addOrUpdateTaskForUrl(
            url, taskId, _ALDownloaderInnerStatus.enqueued, 0, dir);

        _callProgressHandler(url, 0);
      } else {
        aldDebugPrint(
            "ALDownloader | try to download url, but a download task of the url generates failed, url = $url, taskId = null");
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.complete) {
      aldDebugPrint(
          "ALDownloader | try to download url, but the url is succeeded, url = $url, taskId = ${task.taskId}");

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

        _addOrUpdateTaskForUrl(url, taskIdForRetry,
            _ALDownloaderInnerStatus.enqueued, progress, "");

        // ignore: non_constant_identifier_names
        final double_progress =
            double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;

        _callProgressHandler(url, double_progress);

        aldDebugPrint(
            "ALDownloader | try to download url, the url is $previousStatusDescription previously and retries succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForRetry, innerStatus = enqueued");
      } else {
        aldDebugPrint(
            "ALDownloader | try to download url, the url is $previousStatusDescription previously but retries failed, url = $url, previous taskId = $previousTaskId, taskId = null");
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.paused) {
      final previousTaskId = task.taskId;

      final taskIdForResumption =
          await FlutterDownloader.resume(taskId: task.taskId);
      if (taskIdForResumption != null) {
        aldDebugPrint(
            "ALDownloader | try to download url, the url is paused previously and resumes succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForResumption, innerStatus = running");

        _addOrUpdateTaskForUrl(url, taskIdForResumption,
            _ALDownloaderInnerStatus.paused, task.progress, "");
      } else {
        aldDebugPrint(
            "ALDownloader | try to download url, the url is paused previously but resumes failed, url = $url, previous taskId = $previousTaskId, taskId = null");
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.running) {
      aldDebugPrint(
          "ALDownloader | try to download url, but the url is running, url may re-download after being paused, url = $url, taskId = ${task.taskId}");

      task.isNeedRedownloadAfterPaused = true;
    } else {
      aldDebugPrint(
          "ALDownloader | try to download url, but the url is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}");
    }
  }

  static Future<void> _pause1(String url) async {
    assert(_isInitial,
        "ALDownloader | ALDownloader.initialize or ALDownloader.download must be called first");

    try {
      final task = _getTaskFromUrl(url);

      if (task == null) {
        aldDebugPrint(
            "ALDownloader | _pause1, url = $url, but url's task is null");
      } else {
        final taskId = task.taskId;

        if (task.innerStatus == _ALDownloaderInnerStatus.enqueued) {
          await _pauseTaskPretendedlyWithCallHandler(task);
        } else if (task.innerStatus == _ALDownloaderInnerStatus.running) {
          if (Platform.isAndroid) {
            if (await ALDownloaderFileManagerIMP.isExistPhysicalFilePathForUrl(
                url)) {
              await FlutterDownloader.pause(taskId: taskId);
              task.isNeedRedownloadAfterPaused = false;
            } else {
              await _pauseTaskPretendedlyWithCallHandler(task);
            }
          } else {
            await FlutterDownloader.pause(taskId: taskId);
            task.isNeedRedownloadAfterPaused = false;
          }
        } else {
          aldDebugPrint(
              "ALDownloader | _pause1, url = $url, but url is ${task.innerStatus.alDescription}");
        }
      }
    } catch (error) {
      aldDebugPrint("ALDownloader | _pause1, url = $url, error = $error");
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
    assert(_isInitial,
        "ALDownloader | ALDownloader.initialize or ALDownloader.download must be called first");

    try {
      final task = _getTaskFromUrl(url);

      if (task == null ||
          task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
        if (task == null) {
          aldDebugPrint(
              "ALDownloader | _cancel1, url = $url, but url's task is null");
        } else {
          aldDebugPrint(
              "ALDownloader | _cancel1, url = $url, but url is deprecated");
        }

        _callFailedHandler(url, 0);
      } else if (task.innerStatus == _ALDownloaderInnerStatus.enqueued ||
          task.innerStatus == _ALDownloaderInnerStatus.running) {
        await _removeTaskWithCallHandler(task);
      }
    } catch (error) {
      aldDebugPrint("ALDownloader | _cancel1, url = $url, error = $error");
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
    assert(_isInitial,
        "ALDownloader | ALDownloader.initialize or ALDownloader.download must be called first");

    try {
      final task = _getTaskFromUrl(url);

      if (task == null ||
          task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
        if (task == null) {
          aldDebugPrint(
              "ALDownloader | _remove1, url = $url, but url's task is null");
        } else {
          aldDebugPrint(
              "ALDownloader | _remove1, url = $url, but url is deprecated");
        }

        _callFailedHandler(url, 0);
      } else {
        await _removeTaskWithCallHandler(task);
      }
    } catch (error) {
      aldDebugPrint("ALDownloader | _remove1, url = $url, error = $error");
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
    final url = task.url;
    if (task.innerStatus == _ALDownloaderInnerStatus.prepared) {
      _addOrUpdateTaskForUrl(url, "", _ALDownloaderInnerStatus.ignored, 0, "");
    } else if (task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused) {
      _addOrUpdateTaskForUrl(
          url, "", _ALDownloaderInnerStatus.preparedPretendedPaused, 0, "");
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
  static void _addOrUpdateTaskForUrl(String? url, String taskId,
      _ALDownloaderInnerStatus innerStatus, int progress, String savedDir) {
    if (url == null) {
      aldDebugPrint(
          "ALDownloader | _addOrUpdateTaskForUrl, error = url is null");
      return;
    }

    _ALDownloadTask? task;

    try {
      task = _tasks.firstWhere((element) => element.url == url);
      if (savedDir != "") task.savedDir = savedDir;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;
    } catch (error) {
      aldDebugPrint("ALDownloader | _addOrUpdateTaskForUrl, error = $error");
    }

    if (task == null) {
      task = _ALDownloadTask(url);
      if (savedDir != "") task.savedDir = savedDir;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;

      _tasks.add(task);
    }
  }

  /// Register send port and receive port for [IsolateNameServer]
  ///
  /// It is used for communication between entrypoint isolate and download isolate.
  static void _addIsolateNameServerPortService() {
    IsolateNameServer.registerPortWithName(
        _receivePort.sendPort, _kDownloaderSendPort);
    _receivePort.listen((dynamic data) {
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
    final SendPort? send =
        IsolateNameServer.lookupPortByName(_kDownloaderSendPort);

    final originalStatusValue = originalStatus.value;
    send?.send([taskId, originalStatusValue, progress]);
  }

  /// Process the [FlutterDownloader]'s callback
  static void _processDataFromPort(
      String taskId, DownloadTaskStatus originalStatus, int progress) {
    aldDebugPrint(
        "ALDownloader | _processDataFromPort | original, taskId = $taskId, original status = $originalStatus, original progress = $progress",
        isFrequentPrint: true);

    _ALDownloaderInnerStatus innerStatus = _transferStatus(originalStatus);

    final task = _getTaskFromTaskId(taskId);

    if (task == null) {
      aldDebugPrint(
          "ALDownloader | _processDataFromPort, the func return, because task is not found, taskId = $taskId");
      return;
    }

    if (task.innerStatus == _ALDownloaderInnerStatus.prepared ||
        task.innerStatus == _ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == _ALDownloaderInnerStatus.deprecated ||
        task.innerStatus == _ALDownloaderInnerStatus.ignored ||
        task.innerStatus == _ALDownloaderInnerStatus.preparedPretendedPaused) {
      aldDebugPrint(
          "ALDownloader | _processDataFromPort, the func return, because task is ${task.innerStatus.alDescription}, taskId = $taskId");
      return;
    }

    final url = task.url;

    _addOrUpdateTaskForUrl(url, taskId, innerStatus, progress, "");

    // ignore: non_constant_identifier_names
    final double_progress =
        double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;

    _callHandlerForBusiness1(taskId, url, innerStatus, double_progress);

    if (task.isNeedRedownloadAfterPaused &&
        task.innerStatus == _ALDownloaderInnerStatus.paused) {
      task.isNeedRedownloadAfterPaused = false;
      download(url);
    }

    aldDebugPrint(
        "ALDownloader | _processDataFromPort | processed, taskId = $taskId, url = $url, innerStatus = $innerStatus, progress = $progress, double_progress = $double_progress",
        isFrequentPrint: true);
  }

  /// Load [FlutterDownloader]'s database task to the memory cache, and attempt to execute the tasks
  static Future<void> _loadAndTryToRunTask() async {
    final originalTasks = await FlutterDownloader.loadTasks();

    if (originalTasks != null) {
      aldDebugPrint(
          "ALDownloader | _loadAndTryToRunTask, original tasks length = ${originalTasks.length}");

      for (final element in originalTasks) {
        final originalTaskId = element.taskId;
        final originalUrl = element.url;
        final originalSavedDir = element.savedDir;
        final originalStatus = element.status;
        final originalProgress = element.progress;

        aldDebugPrint(
            "ALDownloader | _loadAndTryToRunTask, original url = $originalUrl, original taskId = $originalTaskId, original status = $originalStatus");

        final task = _ALDownloadTask(originalUrl);
        task.taskId = originalTaskId;
        task.savedDir = originalSavedDir;
        task.innerStatus = _transferStatus(originalStatus);
        task.progress = originalProgress;
        _tasks.add(task);

        final isShouldRemoveDataForSavedDir =
            await _isShouldRemoveDataForInitialization(
                task.savedDir, task.url, task.innerStatus);
        if (isShouldRemoveDataForSavedDir) await _removeTask(task);

        aldDebugPrint(
            "ALDownloader | _loadAndTryToRunTask, url = ${task.url}, taskId = ${task.taskId}, innerStatus = ${task.innerStatus}, isShouldRemoveDataForSavedDir = $isShouldRemoveDataForSavedDir");
      }

      aldDebugPrint(
          "ALDownloader | _loadAndTryToRunTask, tasks length = ${_tasks.length}");

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
      String savedDir, String url, _ALDownloaderInnerStatus innerStatus) async {
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

    if (!aBool)
      aBool = innerStatus == _ALDownloaderInnerStatus.enqueued ||
          innerStatus == _ALDownloaderInnerStatus.running;

    return aBool;
  }

  /// Verify data and then determine whether to delete data from disk
  static Future<bool> _isShouldRemoveData(
      String savedDir, String url, _ALDownloaderInnerStatus innerStatus) async {
    if (innerStatus == _ALDownloaderInnerStatus.prepared ||
        innerStatus == _ALDownloaderInnerStatus.ignored ||
        innerStatus == _ALDownloaderInnerStatus.preparedPretendedPaused)
      return false;

    if (!(await _isInRootPathForPath(savedDir))) return true;

    if (innerStatus == _ALDownloaderInnerStatus.complete ||
        innerStatus == _ALDownloaderInnerStatus.paused) {
      final aBool =
          await ALDownloaderFileManagerIMP.isExistPhysicalFilePathForUrl(url);
      return !aBool;
    } else {
      return false;
    }
  }

  /// Whether path is in root path
  static Future<bool> _isInRootPathForPath(String path) async {
    if (path == "") return false;

    // Delete previous versions's data.
    if (path.contains("/flutter/al_")) return false;

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
      aldDebugPrint("ALDownloader | _getTaskFromUrl, error = $error");
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
      aldDebugPrint("ALDownloader | _getTaskIdWith, error = $error");
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
      aldDebugPrint("ALDownloader | _getTaskFromTaskId, error = $error");
    }
    return task;
  }

  /// Get url from custom download tasks by [taskId]
  // ignore: unused_element
  static String? _getUrlWithTaskId(String taskId) {
    String? url;
    try {
      url = _tasks.firstWhere((element) => taskId == element.taskId).url;
    } catch (error) {
      aldDebugPrint("ALDownloader | _getUrlWithTaskId, error = $error");
    }
    return url;
  }

  static Future<void> _removeTaskWithCallHandler(_ALDownloadTask task) async {
    final url = task.url;

    await _removeTask(task);

    _callFailedHandler(url, 0);
  }

  static Future<void> _removeTask(_ALDownloadTask task) async {
    final taskId = task.taskId;

    task.innerStatus = _ALDownloaderInnerStatus.deprecated;
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
    task.innerStatus = _ALDownloaderInnerStatus.pretendedPaused;
    await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static void _callProgressHandler(String url, double progress) {
    _binders.forEach((element) {
      if (element.url == url) {
        final progressHandler = element.downloaderHandlerHolder.progressHandler;
        if (progressHandler != null) progressHandler(progress);
      }
    });
  }

  static void _callSucceededHandler(String url, double progress) {
    _binders.forEach((element) {
      if (element.url == url) {
        final progressHandler = element.downloaderHandlerHolder.progressHandler;
        if (progressHandler != null) progressHandler(progress);

        final succeededHandler =
            element.downloaderHandlerHolder.succeededHandler;
        if (succeededHandler != null) succeededHandler();
      }
    });

    _binders.removeWhere((element) => element.url == url && !element.isForever);
  }

  static void _callFailedHandler(String url, double progress) {
    _binders.forEach((element) {
      if (element.url == url) {
        final progressHandler = element.downloaderHandlerHolder.progressHandler;
        if (progressHandler != null) progressHandler(progress);

        final failedHandler = element.downloaderHandlerHolder.failedHandler;
        if (failedHandler != null) failedHandler();
      }
    });

    _binders.removeWhere((element) => element.url == url && !element.isForever);
  }

  static void _callPausedHandler(String url, double progress) {
    _binders.forEach((element) {
      if (element.url == url) {
        if (progress > -0.01) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) progressHandler(progress);
        }

        final pausedHandler = element.downloaderHandlerHolder.pausedHandler;
        if (pausedHandler != null) pausedHandler();
      }
    });
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

  /// A dirty flag that guarantees that this scope is executed only once
  static bool _isInitial = false;

  /// ALDownloader event queue
  static final _queue = Queue();

  /// Custom download tasks
  static final List<_ALDownloadTask> _tasks = [];

  /// A binder list for binding element such as url, downloader interface, forever flag and so on
  static final List<_ALDownloaderBinder> _binders = [];

  /// Send port key
  static final _kDownloaderSendPort = "al_downloader_send_port";

  /// Receive port
  static final ReceivePort _receivePort = ReceivePort();

  /// Privatize constructor
  ALDownloaderIMP._();
}

/// A class of custom download task
class _ALDownloadTask {
  final String url;

  String savedDir = "";

  String taskId = "";

  bool isNeedRedownloadAfterPaused = false;

  int progress = 0;

  _ALDownloaderInnerStatus innerStatus = _ALDownloaderInnerStatus.prepared;

  _ALDownloadTask(this.url);
}

/// A binder for binding element of url and downloader interface
///
/// It may bind more elements in the future.
class _ALDownloaderBinder {
  _ALDownloaderBinder(this.url, this.downloaderHandlerHolder, this.isForever);
  final String url;
  final ALDownloaderHandlerInterface downloaderHandlerHolder;
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
        "prepared",
        "undefined",
        "enqueued",
        "running",
        "complete",
        "failed",
        "canceled",
        "paused",
        "pretendedPaused",
        "deprecated",
        "ignored",
        "preparedPretendedPaused"
      ][index];
}
