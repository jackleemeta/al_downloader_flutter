import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderPersistentFileManager.dart';
import 'ALDownloaderStatus.dart';
import 'internal/ALDownloaderPrint.dart';

/// ALDownloader
class ALDownloader {
  /// Initialize
  ///
  /// It can be called actively or called lazily when [download] is called.
  static Future<void> initialize() async {
    if (!_isInitial) {
      // Initialize flutterDownloader.
      await FlutterDownloader.initialize(debug: false, ignoreSsl: true);

      // Register FlutterDownloader callback.
      FlutterDownloader.registerCallback(_downloadCallback);

      // Register the isolate communication service.
      _addIsolateNameServerPortService();

      // Extract all current tasks from database and execute the tasks that need to execute.
      await _loadAndTryToRunTask();

      // a dirty flag that guarantees that this scope is executed only once
      _isInitial = true;
    }
  }

  /// Download
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  static Future<void> download(String? url,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) async {
    if (url == null)
      throw "ALDownloader | try to download url, but url is null";

    if (downloaderHandlerInterface != null) {
      final aBinder =
          _ALDownloaderBinder(url, downloaderHandlerInterface, false);
      _binders.add(aBinder);
    }

    await initialize();

    var task = _getTaskFromUrl(url);

    if (task != null) {
      if (await _isShouldRemoveData(task.savedDir, url, task.innerStatus)) {
        await _removeTask(task);
        task = null;
      }
    }

    if (task == null ||
        task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
      if (task == null) {
        aldDebugPrint(
            "ALDownloader | try to download url, the url is initial, url = $url, taskId = null");
      } else {
        aldDebugPrint(
            "ALDownloader | try to download url, the url is deprecated, url = $url, taskId = ${task.taskId}");
      }

      // Add a prepared task to represent placeholder.
      _addOrUpdateTaskForUrl(url, "", _ALDownloaderInnerStatus.prepared, 0, "");

      // Get 'physical directory path' and 'file name' of the file by url.
      final alDownloaderPathComponentModel =
          await ALDownloaderPersistentFileManager
              .lazyGetALDownloaderPathModelForUrl(url);

      final dir = alDownloaderPathComponentModel.dir;

      // Enqueue a task.
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: dir,
          fileName: alDownloaderPathComponentModel.fileName,
          showNotification: false,
          openFileFromNotification: false);

      if (taskId != null) {
        aldDebugPrint(
            "ALDownloader | try to download url, a download task of the url generates succeeded, url = $url, taskId = $taskId, innerStatus = enqueued");

        _addOrUpdateTaskForUrl(
            url, taskId, _ALDownloaderInnerStatus.enqueued, 0, dir);
      } else {
        aldDebugPrint(
            "ALDownloader | try to download url, but a download task of the url generates failed, url = $url, taskId = null");
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.canceled ||
        task.innerStatus == _ALDownloaderInnerStatus.failed) {
      final previousTaskId = task.taskId;
      final previousStatusDescription = task.innerStatus.alDescription;

      final taskIdForRetry = await FlutterDownloader.retry(taskId: task.taskId);

      if (taskIdForRetry != null) {
        _addOrUpdateTaskForUrl(url, taskIdForRetry,
            _ALDownloaderInnerStatus.enqueued, task.progress, "");
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
            _ALDownloaderInnerStatus.running, task.progress, "");
      } else {
        aldDebugPrint(
            "ALDownloader | try to download url, the url is paused previously but resumes failed, url = $url, previous taskId = $previousTaskId, taskId = null");
      }
    } else if (task.innerStatus == _ALDownloaderInnerStatus.complete) {
      aldDebugPrint(
          "ALDownloader | try to download url, but the url is succeeded, url = $url, taskId = ${task.taskId}");

      _binders.forEach((element) {
        if (element.url == url) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) {
            // ignore: non_constant_identifier_names
            final int_progress = task == null ? 0 : task.progress;
            // ignore: non_constant_identifier_names
            final double_progress =
                double.tryParse(((int_progress / 100).toStringAsFixed(2))) ?? 0;
            progressHandler(double_progress);
          }

          final succeededHandler =
              element.downloaderHandlerHolder.succeededHandler;
          if (succeededHandler != null) succeededHandler();
        }
      });
      _binders
          .removeWhere((element) => element.url == url && !element.isForever);
    } else if (task.innerStatus == _ALDownloaderInnerStatus.running) {
      aldDebugPrint(
          "ALDownloader | try to download url, but the url is running, url = $url, taskId = ${task.taskId}");
    } else if (task.innerStatus == _ALDownloaderInnerStatus.enqueued) {
      aldDebugPrint(
          "ALDownloader | try to download url, but the url is enqueued, url = $url, taskId = ${task.taskId}");
    } else if (task.innerStatus == _ALDownloaderInnerStatus.prepared) {
      aldDebugPrint(
          "ALDownloader | try to download url, but the url is prepared, url = $url, taskId = ${task.taskId}");
    } else {
      aldDebugPrint(
          "ALDownloader | try to download url, but the url is unknown, url = $url, taskId = ${task.taskId}");
    }
  }

  /// Add a downloader handler interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// [url] url
  static void addDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface, String? url) {
    if (downloaderHandlerInterface == null || url == null) return;
    final aBinder = _ALDownloaderBinder(url, downloaderHandlerInterface, false);
    _binders.add(aBinder);
  }

  /// Add a forever downloader handler interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is a forever interface which never is destroyed unless [removeDownloaderHandlerInterfaceForUrl] or [removeDownloaderHandlerInterfaceForAll] is called.
  ///
  /// [url] url
  static void addForeverDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface, String? url) {
    if (downloaderHandlerInterface == null || url == null) return;
    final aBinder = _ALDownloaderBinder(url, downloaderHandlerInterface, true);
    _binders.add(aBinder);
  }

  /// Remove downloader handler interface
  ///
  /// **parameters**
  ///
  /// [url] url
  static void removeDownloaderHandlerInterfaceForUrl(String url) =>
      _binders.removeWhere((element) => url == element.url);

  /// Remove all downloader handler interfaces
  static void removeDownloaderHandlerInterfaceForAll() => _binders.clear();

  /// Get download status
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [ALDownloaderStatus] download status
  static ALDownloaderStatus getDownloadStatusForUrl(String url) {
    ALDownloaderStatus status;

    try {
      final task = _getTaskFromUrl(url);
      final innerStatus = task?.innerStatus;

      if (innerStatus == null ||
          innerStatus == _ALDownloaderInnerStatus.prepared ||
          innerStatus == _ALDownloaderInnerStatus.undefined ||
          innerStatus == _ALDownloaderInnerStatus.enqueued ||
          innerStatus == _ALDownloaderInnerStatus.deprecated)
        status = ALDownloaderStatus.unstarted;
      else if (innerStatus == _ALDownloaderInnerStatus.running)
        status = ALDownloaderStatus.downloading;
      else if (innerStatus == _ALDownloaderInnerStatus.paused)
        status = ALDownloaderStatus.paused;
      else if (innerStatus == _ALDownloaderInnerStatus.canceled ||
          innerStatus == _ALDownloaderInnerStatus.failed)
        status = ALDownloaderStatus.failed;
      else
        status = ALDownloaderStatus.succeeded;
    } catch (error) {
      status = ALDownloaderStatus.unstarted;
      aldDebugPrint(
          "ALDownloader | getDownloadStatusForUrl = $url, error = $error");
    }

    return status;
  }

  /// Get download progress
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [double] download progress
  static double getDownloadProgressForUrl(String url) {
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

  /// Pause download
  ///
  /// Stop download, but the incomplete data will not be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static Future<void> pause(String url) async {
    assert(_isInitial,
        "ALDownloader | ALDownloader.initialize or ALDownloader.download must be called first");

    try {
      final task = _getTaskFromUrl(url);

      if (task == null ||
          task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
        if (task == null) {
          aldDebugPrint(
              "ALDownloader | pause, url = $url, but url's task is null");
        } else {
          aldDebugPrint(
              "ALDownloader | pause, url = $url, but url is deprecated");
        }

        _callFailedHandler(url);
      } else {
        final taskId = task.taskId;
        if (task.innerStatus == _ALDownloaderInnerStatus.running) {
          if (Platform.isAndroid) {
            if (await ALDownloaderPersistentFileManager
                .isExistAbsolutePhysicalPathOfFileForUrl(url)) {
              await FlutterDownloader.pause(taskId: taskId);
            } else {
              await _removeTaskWithCallHandler(task);
            }
          } else {
            await FlutterDownloader.pause(taskId: taskId);
          }
        } else if (task.innerStatus == _ALDownloaderInnerStatus.undefined ||
            task.innerStatus == _ALDownloaderInnerStatus.enqueued) {
          await _removeTaskWithCallHandler(task);
        }
      }
    } catch (error) {
      aldDebugPrint("ALDownloader | pause, url = $url, error = $error");
    }
  }

  /// Pause all downloads
  ///
  /// This is a multiple of [pause], see [pause].
  static Future<void> pauseAll() async {
    final aTemp = <_ALDownloadTask>[];
    aTemp.addAll(_tasks);
    for (final task in aTemp) {
      final url = task.url;
      await pause(url);
    }
  }

  /// Cancel download
  ///
  /// Stop download, and the incomplete data will be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static Future<void> cancel(String url) async {
    assert(_isInitial,
        "ALDownloader | ALDownloader.initialize or ALDownloader.download must be called first");

    try {
      final task = _getTaskFromUrl(url);

      if (task == null ||
          task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
        if (task == null) {
          aldDebugPrint(
              "ALDownloader | cancel, url = $url, but url's task is null");
        } else {
          aldDebugPrint(
              "ALDownloader | cancel, url = $url, but url is deprecated");
        }

        _callFailedHandler(url);
      } else {
        if (task.innerStatus == _ALDownloaderInnerStatus.running ||
            task.innerStatus == _ALDownloaderInnerStatus.enqueued ||
            task.innerStatus == _ALDownloaderInnerStatus.undefined) {
          await _removeTaskWithCallHandler(task);
        }
      }
    } catch (error) {
      aldDebugPrint("ALDownloader | cancel, url = $url, error = $error");
    }
  }

  /// Cancel all downloads
  ///
  /// This is a multiple of [cancel], see [cancel].
  static Future<void> cancelAll() async {
    final aTemp = <_ALDownloadTask>[];
    aTemp.addAll(_tasks);
    for (final task in aTemp) {
      final url = task.url;
      await cancel(url);
    }
  }

  /// Remove download
  ///
  /// Remove download, and all the data will be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static Future<void> remove(String url) async {
    assert(_isInitial,
        "ALDownloader | ALDownloader.initialize or ALDownloader.download must be called first");

    try {
      final task = _getTaskFromUrl(url);

      if (task == null ||
          task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
        if (task == null) {
          aldDebugPrint(
              "ALDownloader | remove, url = $url, but url's task is null");
        } else {
          aldDebugPrint(
              "ALDownloader | remove, url = $url, but url is deprecated");
        }

        _callFailedHandler(url);
      } else {
        await _removeTaskWithCallHandler(task);
      }
    } catch (error) {
      aldDebugPrint("ALDownloader | remove, url = $url, error = $error");
    }
  }

  /// Remove all downloads
  ///
  /// This is a multiple of [remove], see [remove].
  static Future<void> removeAll() async {
    final aTemp = <_ALDownloadTask>[];
    aTemp.addAll(_tasks);
    for (final task in aTemp) {
      final url = task.url;
      await remove(url);
    }
  }

  /// Get a completed set of key-value pairs which the structure is [url: succeeded/failed]
  ///
  /// Url and result(succeeded/failed) are added to the pool.
  static Map<String, bool> get completedKVs => _completedKVs;

  /// Manager custom download tasks
  ///
  /// **purpose**
  ///
  /// avoid frequent I/O
  ///
  /// **discusstion**
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
  /// It is used for communication between download isolate and main isolate.
  static void _addIsolateNameServerPortService() {
    IsolateNameServer.registerPortWithName(
        _receivePort.sendPort, _kDownloaderSendPort);
    _receivePort.listen((dynamic data) {
      final taskId = data[0];
      final originalStatus = data[1];
      final progress = data[2];
      _processDataFromPort(taskId, originalStatus, progress);
    });
  }

  /// The callback binded by [FlutterDownloader]
  static void _downloadCallback(
      String taskId, DownloadTaskStatus originalStatus, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName(_kDownloaderSendPort);
    send?.send([taskId, originalStatus, progress]);
  }

  /// Process the [FlutterDownloader]'s callback
  static void _processDataFromPort(
      String taskId, DownloadTaskStatus originalStatus, int progress) {
    aldDebugPrint(
        "ALDownloader | _processDataFromPort | original, taskId = $taskId, original status = $originalStatus, original progress = $progress",
        isFrequentPrint: true);

    _ALDownloaderInnerStatus innerStatus = transferStatus(originalStatus);

    final task = _getTaskFromTaskId(taskId);

    if (task == null) {
      aldDebugPrint(
          "ALDownloader | _processDataFromPort, the func return, because task is not found, taskId = $taskId");
      return;
    }

    if (task.innerStatus == _ALDownloaderInnerStatus.deprecated) {
      aldDebugPrint(
          "ALDownloader | _processDataFromPort, the func return, because task is deprecated, taskId = $taskId");
      return;
    }

    final url = task.url;

    _addOrUpdateTaskForUrl(url, taskId, innerStatus, progress, "");

    if (innerStatus == _ALDownloaderInnerStatus.complete) {
      _completedKVs[url] = true;
    } else if (innerStatus == _ALDownloaderInnerStatus.failed ||
        innerStatus == _ALDownloaderInnerStatus.canceled) {
      _completedKVs[url] = false;
    }

    // ignore: non_constant_identifier_names
    final double_progress =
        double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;

    _callHandlerBusiness1(taskId, url, innerStatus, double_progress);

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
        task.innerStatus = transferStatus(originalStatus);
        task.progress = originalProgress;
        _tasks.add(task);

        final isShouldRemoveDataForSavedDir =
            await _isShouldRemoveDataForInitialization(
                task.savedDir, task.url, task.innerStatus);
        if (isShouldRemoveDataForSavedDir) {
          // If the task should be deleted, call back throught calling [_removeTaskWithCallHandler].
          await _removeTaskWithCallHandler(task);
        } else {
          if (task.innerStatus == _ALDownloaderInnerStatus.complete) {
            _completedKVs[task.url] = true;
          } else if (task.innerStatus == _ALDownloaderInnerStatus.failed ||
              task.innerStatus == _ALDownloaderInnerStatus.canceled) {
            _completedKVs[task.url] = false;
          }

          // If the task is normal, call back directly.
          // ignore: non_constant_identifier_names
          final double_progress =
              double.tryParse(((task.progress / 100).toStringAsFixed(2))) ?? 0;
          _callHandlerBusiness1(
              task.taskId, task.url, task.innerStatus, double_progress);
        }

        aldDebugPrint(
            "ALDownloader | _loadAndTryToRunTask, url = ${task.url}, taskId = ${task.taskId}, innerStatus = ${task.innerStatus}, isShouldRemoveDataForSavedDir = $isShouldRemoveDataForSavedDir");
      }
    }

    aldDebugPrint(
        "ALDownloader | _loadAndTryToRunTask, tasks length = ${_tasks.length}");
  }

  /// Process business 1 for call handler
  static void _callHandlerBusiness1(
      String taskId,
      String url,
      _ALDownloaderInnerStatus innerStatus,
      // ignore: non_constant_identifier_names
      double double_progress) {
    if (innerStatus == _ALDownloaderInnerStatus.complete) {
      _binders.forEach((element) {
        if (element.url == url) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) progressHandler(double_progress);

          final succeededHandler =
              element.downloaderHandlerHolder.succeededHandler;
          if (succeededHandler != null) succeededHandler();
        }
      });
    } else if (innerStatus == _ALDownloaderInnerStatus.paused) {
      _binders.forEach((element) {
        if (element.url == url) {
          if (double_progress > -0.01) {
            final progressHandler =
                element.downloaderHandlerHolder.progressHandler;
            if (progressHandler != null) progressHandler(double_progress);
          }

          final pausedHandler = element.downloaderHandlerHolder.pausedHandler;
          if (pausedHandler != null) pausedHandler();
        }
      });
    } else if (innerStatus == _ALDownloaderInnerStatus.canceled ||
        innerStatus == _ALDownloaderInnerStatus.failed) {
      _binders.forEach((element) {
        if (element.url == url) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) progressHandler(-0.01);

          final failedHandler = element.downloaderHandlerHolder.failedHandler;
          if (failedHandler != null) failedHandler();
        }
      });
    } else if (innerStatus == _ALDownloaderInnerStatus.running) {
      _binders.forEach((element) {
        if (element.url == url) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) progressHandler(double_progress);
        }
      });
    }

    if (innerStatus == _ALDownloaderInnerStatus.complete ||
        innerStatus == _ALDownloaderInnerStatus.failed ||
        innerStatus == _ALDownloaderInnerStatus.canceled) {
      _binders
          .removeWhere((element) => element.url == url && !element.isForever);
    }
  }

  /// Verify data and then determine whether to delete data from disk
  ///
  /// for initialization
  static Future<bool> _isShouldRemoveDataForInitialization(
      String savedDir, String url, _ALDownloaderInnerStatus innerStatus) async {
    if (innerStatus == _ALDownloaderInnerStatus.prepared) return false;
    if (!(await ALDownloader._isInRootPathForPath(savedDir))) return true;
    bool aBool;
    if (innerStatus == _ALDownloaderInnerStatus.complete) {
      aBool = !(await ALDownloaderPersistentFileManager
          .isExistAbsolutePhysicalPathOfFileForUrl(url));
    } else {
      aBool = false;
    }

    if (!aBool)
      aBool = Platform.isIOS &&
          (innerStatus == _ALDownloaderInnerStatus.undefined ||
              innerStatus == _ALDownloaderInnerStatus.enqueued ||
              innerStatus == _ALDownloaderInnerStatus.running);

    return aBool;
  }

  /// Verify data and then determine whether to delete data from disk
  static Future<bool> _isShouldRemoveData(
      String savedDir, String url, _ALDownloaderInnerStatus innerStatus) async {
    if (innerStatus == _ALDownloaderInnerStatus.prepared) return false;
    if (!(await ALDownloader._isInRootPathForPath(savedDir))) return true;
    if (innerStatus == _ALDownloaderInnerStatus.complete) {
      final aBool = await ALDownloaderPersistentFileManager
          .isExistAbsolutePhysicalPathOfFileForUrl(url);
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
        await ALDownloaderPersistentFileManager.isInRootPathWithPath(path);

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

    _callFailedHandler(url);
  }

  static Future<void> _removeTask(_ALDownloadTask task) async {
    final taskId = task.taskId;
    final url = task.taskId;

    _completedKVs[url] = false;
    task.innerStatus = _ALDownloaderInnerStatus.deprecated;
    await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static void _callFailedHandler(String url) {
    _binders.forEach((element) {
      if (element.url == url) {
        final progressHandler = element.downloaderHandlerHolder.progressHandler;
        if (progressHandler != null) progressHandler(0);

        final failedHandler = element.downloaderHandlerHolder.failedHandler;
        if (failedHandler != null) failedHandler();
      }
    });

    _binders.removeWhere((element) => element.url == url && !element.isForever);
  }

  static _ALDownloaderInnerStatus transferStatus(DownloadTaskStatus status) {
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

  /// Custom download tasks
  static final List<_ALDownloadTask> _tasks = [];

  /// A binder list for binding element such as url, downloader interface, forever flag and so on
  static final List<_ALDownloaderBinder> _binders = [];

  /// This is same as [completedKVs], see [completedKVs]
  static final Map<String, bool> _completedKVs = {};

  /// Send port key
  static final _kDownloaderSendPort = "al_downloader_send_port";

  /// Receive port
  static final ReceivePort _receivePort = ReceivePort();

  /// Privatize constructor
  ALDownloader._();
}

/// A class of custom download task
class _ALDownloadTask {
  final String url;

  String savedDir = "";

  String taskId = "";

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
/// It has supplemented [prepared] and [deprecated] at present and may supplement more statuses in the future.
enum _ALDownloaderInnerStatus {
  prepared,
  undefined,
  enqueued,
  running,
  complete,
  failed,
  canceled,
  paused,
  deprecated
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
        "deprecated"
      ][index];
}
