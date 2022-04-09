import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderPersistentFileManager.dart';
import 'ALDownloaderStatus.dart';

/// ALDownloader
class ALDownloader {
  /// ---------------------- Public API ----------------------

  /// initialize
  ///
  /// called or lazy call
  ///
  /// lazy call：when call [download]
  static Future<void> initialize() async {
    if (!_isInitial) {
      // FlutterDownloader initialize
      await FlutterDownloader.initialize(debug: false);

      // register FlutterDownloader callback
      FlutterDownloader.registerCallback(_downloadCallback);

      // register the isolate communication service
      _addIsolateNameServerPortService();

      // extract all current tasks from database and execute the tasks that need to be executed
      await _loadAndTryToRunTask();

      // a dirty flag that guarantees that this scope is executed only once
      _isInitial = true;
    }
  }

  /// download
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// [downloaderHandlerInterface] the download handle interface
  static Future<void> download(String? url,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) async {
    if (url == null) throw "ALDownloader | download error = url is null";

    if (downloaderHandlerInterface != null) {
      final aBinder = _ALDownloaderBinder(url, downloaderHandlerInterface);
      _alDownloaderBinders.add(aBinder);
    }

    await initialize();

    var anALDownloadTask = _getALDownloadTaskFromUrl(url);

    final isExist = await ALDownloaderPersistentFileManager
        .isExistAbsolutePhysicalPathOfFileForUrl(url);
    if (!isExist &&
        anALDownloadTask != null &&
        anALDownloadTask.status == DownloadTaskStatus.complete) {
      await _innerRemove(url);
      anALDownloadTask = null;
    }

    if (anALDownloadTask == null) {
      // get the 'physical directory path' and 'file name' of the file by URL
      final alDownloaderPathComponentModel =
          await ALDownloaderPersistentFileManager
              .lazyGetALDownloaderPathModelFromUrl(url);

      // equeued a task
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: alDownloaderPathComponentModel.dir,
          fileName: alDownloaderPathComponentModel.fileName,
          showNotification: false,
          openFileFromNotification: false);

      if (taskId != null)
        _addALDownloadTaskOrReplaceALDownloadTaskId(
            url, taskId, DownloadTaskStatus.enqueued, 0);

      debugPrint(
          "ALDownloader | a download task was generated, download status = enqueued, taskId = $taskId");
    } else if (anALDownloadTask.status == DownloadTaskStatus.failed ||
        anALDownloadTask.status == DownloadTaskStatus.canceled) {
      final newTaskIdForRetry =
          await FlutterDownloader.retry(taskId: anALDownloadTask.taskId);
      if (newTaskIdForRetry != null) {
        debugPrint("ALDownloader | newTaskIdForRetry = $newTaskIdForRetry");
        _addALDownloadTaskOrReplaceALDownloadTaskId(url, newTaskIdForRetry,
            DownloadTaskStatus.undefined, anALDownloadTask.progress);
      }
    } else if (anALDownloadTask.status == DownloadTaskStatus.paused) {
      final newTaskIdForResume =
          await FlutterDownloader.resume(taskId: anALDownloadTask.taskId);
      if (newTaskIdForResume != null)
        _addALDownloadTaskOrReplaceALDownloadTaskId(url, newTaskIdForResume,
            DownloadTaskStatus.undefined, anALDownloadTask.progress);
    } else if (anALDownloadTask.status == DownloadTaskStatus.complete) {
      debugPrint(
          "ALDownloader | try to download downloadtaskOfUrl = $url, url is complete");
      _alDownloaderBinders.forEach((element) {
        if (element.forUrl == url) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) {
            // ignore: non_constant_identifier_names
            final int_progress =
                anALDownloadTask == null ? 0 : anALDownloadTask.progress;
            // ignore: non_constant_identifier_names
            final double_progress =
                double.tryParse(((int_progress / 100).toStringAsFixed(2))) ?? 0;
            progressHandler(double_progress);
          }

          final successHandler = element.downloaderHandlerHolder.successHandler;
          if (successHandler != null) successHandler();
        }
      });
      _alDownloaderBinders.removeWhere((element) => element.forUrl == url);
    } else if (anALDownloadTask.status == DownloadTaskStatus.running) {
      debugPrint(
          "ALDownloader | try to download downloadtaskOfUrl = $url, but url is running");
    } else if (anALDownloadTask.status == DownloadTaskStatus.enqueued) {
      debugPrint(
          "ALDownloader | try to download downloadtaskOfUrl = $url, but url is enqueued");
    } else {
      debugPrint(
          "ALDownloader | try to download downloadtaskOfUrl = $url, but url is undefined");
    }
  }

  /// add a download handle interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] download handle interface
  ///
  /// [url] url
  static void addALDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface,
      String? forUrl) {
    if (downloaderHandlerInterface == null || forUrl == null) return;
    final aBinder = _ALDownloaderBinder(forUrl, downloaderHandlerInterface);
    _alDownloaderBinders.add(aBinder);
  }

  /// remove a download handle interface
  ///
  /// **parameters**
  ///
  /// [url] url
  static void removeALDownloaderHandlerInterfaceForUrl(String url) =>
      _alDownloaderBinders.removeWhere((element) => url == element.forUrl);

  /// remove all download handle interfaces
  static void removeALDownloaderHandlerInterfaceForAll() =>
      _alDownloaderBinders.clear();

  /// get the download status of [url]
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// download status [ALDownloaderStatus]
  static ALDownloaderStatus getDownloadStatusForUrl(String url) {
    ALDownloaderStatus alDownloaderStatus;

    try {
      final anALDownloadTask = _getALDownloadTaskFromUrl(url);
      final downloadTaskStatus = anALDownloadTask?.status;

      if (downloadTaskStatus == null ||
          downloadTaskStatus == DownloadTaskStatus.canceled ||
          downloadTaskStatus == DownloadTaskStatus.undefined ||
          downloadTaskStatus == DownloadTaskStatus.enqueued)
        alDownloaderStatus = ALDownloaderStatus.unstarted;
      else if (downloadTaskStatus == DownloadTaskStatus.running)
        alDownloaderStatus = ALDownloaderStatus.downloading;
      else if (downloadTaskStatus == DownloadTaskStatus.paused)
        alDownloaderStatus = ALDownloaderStatus.pausing;
      else if (downloadTaskStatus == DownloadTaskStatus.failed)
        alDownloaderStatus = ALDownloaderStatus.downloadFailed;
      else
        alDownloaderStatus = ALDownloaderStatus.downloadSuccced;
    } catch (error) {
      alDownloaderStatus = ALDownloaderStatus.unstarted;
      debugPrint(
          "ALDownloader | getDownloadStatusForUrl = $url, error = $error");
    }
    return alDownloaderStatus;
  }

  /// get the download progress of [url]
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// download progress
  static double getDownloadProgressForUrl(String url) {
    double alDownloaderProgress;

    try {
      final anALDownloadTask = _getALDownloadTaskFromUrl(url);

      int progress = (anALDownloadTask == null ? 0 : anALDownloadTask.progress);

      // ignore: non_constant_identifier_names
      alDownloaderProgress =
          double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;
    } catch (error) {
      alDownloaderProgress = 0;
      debugPrint(
          "ALDownloader | getDownloadProgressForUrl = $url, error = $error");
    }
    return alDownloaderProgress;
  }

  /// get the completed urls
  ///
  /// urls for resources that download successfully or fail are added to the pool
  ///
  /// **return**
  ///
  /// completed urls - [url: bool]
  static Map<String, bool> get urlResults {
    final Map<String, bool> aMap = {};
    try {
      _alDownloadTasks.forEach((element) {
        if (element.status == DownloadTaskStatus.complete) {
          aMap[element.url] = true;
        } else if (element.status == DownloadTaskStatus.failed) {
          aMap[element.url] = false;
        }
      });
    } catch (error) {
      debugPrint("ALDownloader | get urlResults error = $error");
    }
    return aMap;
  }

  /// cancel download
  ///
  /// the incomplete bytes will be deleted
  ///
  /// **parameters**
  ///
  /// [url] url
  static Future<void> cancel(String url) async {
    final alDownloadTask = _getALDownloadTaskFromUrl(url);

    if (alDownloadTask == null) return;

    if (alDownloadTask.status == DownloadTaskStatus.running) {
      final taskId = alDownloadTask.taskId;
      await FlutterDownloader.cancel(taskId: taskId);
      alDownloadTask.status = DownloadTaskStatus.canceled;
    }
  }

  /// cancel all tasks that are downloading
  ///
  /// the incomplete bytes will be deleted
  static Future<void> cancelAll() async {
    await FlutterDownloader.cancelAll();
    for (final downloadTask in _alDownloadTasks) {
      if (downloadTask.status == DownloadTaskStatus.running)
        downloadTask.status = DownloadTaskStatus.canceled;
    }
  }

  /// pause download
  ///
  /// the incomplete bytes will not be deleted
  ///
  /// task of undefined/enqueued/failed will be removed from the download queue
  ///
  /// **parameters**
  ///
  /// [url] url
  static Future<void> pause(String url) async {
    assert(_isInitial,
        "ALDownloader.initialize or ALDownloader.download must be called first");

    try {
      final alDownloadTask = _getALDownloadTaskFromUrl(url);

      if (alDownloadTask == null) {
        debugPrint(
            "ALDownloader | pause, to be suspended url = $url, but url's alDownloadTask is null");
        return;
      }

      debugPrint(
          "ALDownloader | pause, to be suspended url = $url, alDownloadTask.status = ${alDownloadTask.status}");

      final taskId = alDownloadTask.taskId;
      if (alDownloadTask.status == DownloadTaskStatus.undefined ||
          alDownloadTask.status == DownloadTaskStatus.enqueued ||
          alDownloadTask.status == DownloadTaskStatus.failed) {
        _alDownloadTasks.remove(alDownloadTask);
        await FlutterDownloader.remove(
            taskId: taskId, shouldDeleteContent: true);
      } else if (alDownloadTask.status == DownloadTaskStatus.running) {
        await FlutterDownloader.pause(taskId: taskId);
      }
    } catch (error) {
      debugPrint("ALDownloader | pause error = $error");
    }
  }

  /// pause all tasks
  ///
  /// this is a multiple of [pause], see [pause]
  static Future<void> pauseAll() async {
    final aTemp = [];
    aTemp.addAll(_alDownloadTasks);
    for (final alDownloadTask in aTemp) {
      final url = alDownloadTask.url;
      await pause(url);
    }
  }

  /// remove the ALDownloader data corresponding to [url]
  ///
  /// it will automatically cancel the downloading url
  ///
  /// **parameters**
  ///
  /// [url] url
  static Future<void> remove(String url) async {
    assert(_isInitial,
        "ALDownloader.initialize or ALDownloader.download must be called first");

    await _innerRemove(url);
  }

  /// remove ALDownloader data corresponding to all urls
  static Future<void> removeAll() async {
    for (final alDownloadTask in _alDownloadTasks) remove(alDownloadTask.url);
  }

  /// ---------------------- Private API ----------------------

  /// maintain custom download tasks
  ///
  /// purpose: avoid frequent I/O
  ///
  /// add a new custom task or update the [url] mapping of the existing task's taskId
  static void _addALDownloadTaskOrReplaceALDownloadTaskId(
      String? url, String taskId, DownloadTaskStatus status, int progress) {
    if (url == null) {
      debugPrint(
          "_addALDownloadTaskOrReplaceALDownloadTaskId error url == null");
      return;
    }

    _ALDownloadTask? anALDownloadTask;

    try {
      anALDownloadTask =
          _alDownloadTasks.firstWhere((element) => element.url == url);
      anALDownloadTask.taskId = taskId;
      anALDownloadTask.status = status;
      anALDownloadTask.progress = progress;
    } catch (error) {
      debugPrint(
          "ALDownloader | _addALDownloadTaskOrReplaceALDownloadTaskId error = $error");
    }

    if (anALDownloadTask == null) {
      anALDownloadTask = _ALDownloadTask(url);
      anALDownloadTask.taskId = taskId;
      anALDownloadTask.status = status;
      anALDownloadTask.progress = progress;

      _alDownloadTasks.add(anALDownloadTask);
    }
  }

  /// register send port and receive port for [IsolateNameServer]
  ///
  /// used for communication between download isolate and the main isolate
  static void _addIsolateNameServerPortService() {
    IsolateNameServer.registerPortWithName(
        _receivePort.sendPort, _kDownloaderSendPort);
    _receivePort.listen((dynamic data) {
      final id = data[0];
      final status = data[1];
      final progress = data[2];
      _processDataFromPort(id, status, progress);
    });
  }

  /// the callback binded by [FlutterDownloader]
  static void _downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName(_kDownloaderSendPort);
    send?.send([id, status, progress]);
  }

  /// process the [FlutterDownloader]'s callback
  static void _processDataFromPort(
      String id, DownloadTaskStatus status, int progress) {
    final alDownloadTask = _getALDownloadTaskFromTaskId(id);

    if (alDownloadTask == null) {
      debugPrint("not found alDownloadTask, id = $id");
      return;
    }

    final url = alDownloadTask.url;

    _addALDownloadTaskOrReplaceALDownloadTaskId(url, id, status, progress);

    // ignore: non_constant_identifier_names
    final double_progress =
        double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;

    if (status == DownloadTaskStatus.complete) {
      debugPrint(
          "ALDownloader | _downloadCallback \n download successfully url = $url \nid = $id ");
      _alDownloaderBinders.forEach((element) {
        if (element.forUrl == url) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) progressHandler(double_progress);

          final successHandler = element.downloaderHandlerHolder.successHandler;
          if (successHandler != null) successHandler();
        }
      });
      _alDownloaderBinders.removeWhere((element) => element.forUrl == url);
    } else if (status == DownloadTaskStatus.failed) {
      debugPrint(
          "ALDownloader | _downloadCallback \n download failed url = $url \nid = $id ");
      _alDownloaderBinders.forEach((element) {
        if (element.forUrl == url) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) progressHandler(double_progress);

          final failureHandler = element.downloaderHandlerHolder.failureHandler;
          if (failureHandler != null) failureHandler();
        }
      });
    } else if (status == DownloadTaskStatus.running) {
      _alDownloaderBinders.forEach((element) {
        if (element.forUrl == url) {
          final progressHandler =
              element.downloaderHandlerHolder.progressHandler;
          if (progressHandler != null) progressHandler(double_progress);
        }
      });
    } else if (status == DownloadTaskStatus.paused) {
      _alDownloaderBinders.forEach((element) {
        if (element.forUrl == url) {
          final pausedHandler = element.downloaderHandlerHolder.pausedHandler;
          if (pausedHandler != null) pausedHandler();
        }
      });
    }

    debugPrint(
        "ALDownloader | _downloadCallback \nid = $id \nurl = $url \nstatus = $status \nprogress = $progress \ndouble_progress = $double_progress");
  }

  /// load [FlutterDownloader]'s local database task to the memory cache, and attempt to execute the tasks
  static Future<void> _loadAndTryToRunTask() async {
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks != null) {
      debugPrint(
          "ALDownloader | _loadAndTryToRunTask `Flutterdownloader` tasks length = ${tasks.length}");

      tasks.forEach((element) {
        debugPrint(
            "_loadAndTryToRunTask `Flutterdownloader` task element url = ${element.url}, status = ${element.status}, element url = ${element.taskId}");
      });

      for (var element in tasks) {
        if (element.savedDir.contains("/flutter/al_")) {
          await FlutterDownloader.remove(
              taskId: element.taskId,
              shouldDeleteContent:
                  true); // Delete a download task from DB & delete file
        } else {
          final anALDownloadTask = _ALDownloadTask(element.url);
          anALDownloadTask.taskId = element.taskId;
          anALDownloadTask.status = element.status;
          anALDownloadTask.progress = element.progress;
          _alDownloadTasks.add(anALDownloadTask);
        }
      }
    }

    final aTemp = [];
    aTemp.addAll(_alDownloadTasks);
    for (final element in aTemp) {
      final url = element.url;
      final isExist = await ALDownloaderPersistentFileManager
          .isExistAbsolutePhysicalPathOfFileForUrl(url);
      if (!isExist && element.status == DownloadTaskStatus.complete)
        await _innerRemove(url);
    }

    debugPrint(
        "ALDownloader | _loadAndTryToRunTask `ALDownloader` tasks length = ${_alDownloadTasks.length}");

    _alDownloadTasks.forEach((element) {
      debugPrint(
          "_loadAndTryToRunTask `ALDownloader` task element url = ${element.url}, status = ${element.status}, element url = ${element.taskId}");
    });
  }

  /// get task from custom download tasks by [url]
  static _ALDownloadTask? _getALDownloadTaskFromUrl(String url) {
    _ALDownloadTask? anALDownloadTask;
    try {
      anALDownloadTask =
          _alDownloadTasks.firstWhere((element) => url == element.url);
    } catch (error) {
      debugPrint("ALDownloader | _getALDownloadTaskFromUrl, error = $error");
    }
    return anALDownloadTask;
  }

  /// get task id from custom download tasks by [url]
  // ignore: unused_element
  static String? _getTaskIdFromUrl(String url) {
    String? taskId;
    try {
      taskId =
          _alDownloadTasks.firstWhere((element) => url == element.url).taskId;
    } catch (error) {
      debugPrint("ALDownloader | _getTaskIdWith, error = $error");
    }
    return taskId;
  }

  /// get task from custom download tasks by [taskId]
  // ignore: unused_element
  static _ALDownloadTask? _getALDownloadTaskFromTaskId(String taskId) {
    _ALDownloadTask? anALDownloadTask;
    try {
      anALDownloadTask =
          _alDownloadTasks.firstWhere((element) => taskId == element.taskId);
    } catch (error) {
      debugPrint("ALDownloader | _getALDownloadTaskFromTaskId, error = $error");
    }
    return anALDownloadTask;
  }

  /// get url from custom download tasks by [taskId]
  // ignore: unused_element
  static String? _getUrlWithTaskId(String taskId) {
    String? url;
    try {
      url = _alDownloadTasks
          .firstWhere((element) => taskId == element.taskId)
          .url;
    } catch (error) {
      debugPrint("ALDownloader | _getUrlWithTaskId, error = $error");
    }
    return url;
  }

  static Future<void> _innerRemove(String url) async {
    try {
      final alDownloaderTask = _getALDownloadTaskFromUrl(url);

      if (alDownloaderTask == null) {
        debugPrint(
            "ALDownloader | _innerRemove alDownloaderTask of url = $url, url's  _ALDownloadTask is null");
        return;
      }

      await FlutterDownloader.remove(
          taskId: alDownloaderTask.taskId,
          shouldDeleteContent:
              true); // Delete a download task from DB & delete file
      _alDownloadTasks.remove(alDownloaderTask);
    } catch (error) {
      debugPrint(
          "ALDownloader | _innerRemove alDownloaderTask of url = $url, error = $error");
    }
  }

  /// a dirty flag that guarantees that this scope is executed only once
  static bool _isInitial = false;

  /// custom download tasks
  static final List<_ALDownloadTask> _alDownloadTasks = [];

  /// a binder list for binding element of url and download ininterface
  static final List<_ALDownloaderBinder> _alDownloaderBinders = [];

  /// send port key
  static final _kDownloaderSendPort = "al_downloader_send_port";

  /// receive port
  static final ReceivePort _receivePort = ReceivePort();

  /// privatize constructor
  ALDownloader._();
}

/// class of custom download task
class _ALDownloadTask {
  final String url;

  String taskId = "";
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;

  _ALDownloadTask(this.url);
}

/// a binder for binding element of url and download ininterface
/// it may bind more elements in the future
class _ALDownloaderBinder {
  _ALDownloaderBinder(this.forUrl, this.downloaderHandlerHolder);
  final String forUrl;
  final ALDownloaderHandlerInterface downloaderHandlerHolder;
}
