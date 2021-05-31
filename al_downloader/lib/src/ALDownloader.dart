import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderPersistentFileManager.dart';
import 'ALDownloaderStatus.dart';

/// 下载器
class ALDownloader {
  /// ---------------------- Public API ----------------------

  /// 初始化
  ///
  /// 可以主动调用，也可以懒调用
  ///
  /// 懒调用：调用[download]方法时
  static initialize() async {
    if (!_isInitial) {
      // 一个保证这个作用域只执行一次的脏标记
      _isInitial = true;

      // 初始化
      await FlutterDownloader.initialize(debug: false);

      // 注册回调
      FlutterDownloader.registerCallback(_downloadCallback);

      // 注册isolate通信服务
      _addIsolateNameServerPortService();

      // 从database取出当前所有任务，并执行需要执行的任务
      await _loadAndTryToRunTask();
    }
  }

  /// 下载资源
  ///
  /// **parameters**
  ///
  /// [url] 资源远端地址
  ///
  /// [downloaderHandlerInterface] 下载句柄池
  ///
  /// [subDirectoryName] 子文件夹名称
  static download(String url,
      {ALDownloaderHandlerInterface downloaderHandlerInterface,
      String subDirectoryName}) async {
    if (url == null) throw "ALDownloader download error = url为空";

    if (downloaderHandlerInterface != null) {
      final aBinder = _ALDownloaderBinder(url, downloaderHandlerInterface);
      _alDownloaderBinders.add(aBinder);
    }

    await initialize();

    final anALDownloadTask = _getALDownloadTaskFromUrl(url);

    if (anALDownloadTask == null) {
      // 根据[url]获取文件的`物理目录路径`和`文件名`
      final alDownloaderPathComponentModel =
          await ALDownloaderPersistentFileManager
              .lazyGetALDownloaderPathModelFromUrl(url,
                  subDirectoryName: subDirectoryName);

      // 加入任务队列
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: alDownloaderPathComponentModel.dir,
          fileName: alDownloaderPathComponentModel.fileName,
          showNotification: false,
          openFileFromNotification: false);

      _addALDownloadTaskOrReplaceALDownloadTaskId(
          url, taskId, DownloadTaskStatus.enqueued);

      debugPrint("ALDownloader | 生成了一个下载任务, 下载状态 = enquued， taskId = $taskId");
    } else if (anALDownloadTask.status == DownloadTaskStatus.failed ||
        anALDownloadTask.status == DownloadTaskStatus.canceled) {
      final newTaskIdForRetry =
          await FlutterDownloader.retry(taskId: anALDownloadTask.taskId);
      if (newTaskIdForRetry != null) {
        debugPrint("ALDownloader | newTaskIdForRetry不会空");
        _addALDownloadTaskOrReplaceALDownloadTaskId(
            url, newTaskIdForRetry, DownloadTaskStatus.undefined);
      }
    } else if (anALDownloadTask.status == DownloadTaskStatus.paused) {
      final newTaskIdForResume =
          await FlutterDownloader.resume(taskId: anALDownloadTask.taskId);
      if (newTaskIdForResume != null)
        _addALDownloadTaskOrReplaceALDownloadTaskId(
            url, newTaskIdForResume, DownloadTaskStatus.undefined);
    } else if (anALDownloadTask.status == DownloadTaskStatus.complete) {
      debugPrint(
          "ALDownloader | try to download downloadtaskOfUrl = $url, url is complete");
      _alDownloaderBinders?.forEach((element) {
        if (element.forUrl == url)
          element.downloaderHandlerHolder?.successHandler();
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

  /// 添加下载句柄池
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] 下载句柄池
  ///
  /// [url] 绑定的资源远端地址
  static void addALDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface, String url) {
    if (downloaderHandlerInterface != null) {
      final aBinder = _ALDownloaderBinder(url, downloaderHandlerInterface);
      _alDownloaderBinders.add(aBinder);
    }
  }

  /// 移除下载句柄池
  ///
  /// **parameters**
  ///
  /// [url] 资源远端地址
  static void removeALDownloaderHandlerInterfaceForUrl(String url) =>
      _alDownloaderBinders.removeWhere((element) => url == element.forUrl);

  /// 移除所有句柄
  static void removeALDownloaderHandlerInterfaceForAll() =>
      _alDownloaderBinders.clear();

  /// 获取[url]的下载状态
  ///
  /// **parameters**
  ///
  /// [url] 资源远端地址
  ///
  ///  **return**
  ///
  /// 下载状态[ALDownloaderStatus]
  static ALDownloaderStatus getDownloadStatusForUrl(String url) {
    ALDownloaderStatus alDownloaderStatus;

    try {
      final anALDownloadTask = _getALDownloadTaskFromUrl(url);
      final downloadTaskStatus = anALDownloadTask.status;

      if (downloadTaskStatus == DownloadTaskStatus.canceled ||
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

  /// 获取已完结的url
  ///
  /// 下载成功或下载失败的资源url会添加到这个池子里
  ///
  /// **return**
  ///
  /// 已经完结的url[url: bool]
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

  /// 取消下载
  ///
  /// 已下载的字节数会删除
  ///
  /// **parameters**
  ///
  /// [url] 资源远端地址
  static cancel(String url) async {
    final alDownloadTask = _getALDownloadTaskFromUrl(url);
    if (alDownloadTask.status == DownloadTaskStatus.running) {
      final taskId = alDownloadTask.taskId;
      await FlutterDownloader.cancel(taskId: taskId);
      alDownloadTask.status = DownloadTaskStatus.canceled;
    }
  }

  /// 取消所有正在下载的任务
  ///
  /// 已下载的字节数会删除
  static cancelAll() async {
    await FlutterDownloader.cancelAll();
    for (final downloadTask in _alDownloadTasks) {
      if (downloadTask.status == DownloadTaskStatus.running) {
        downloadTask.status = DownloadTaskStatus.canceled;
      }
    }
  }

  /// 暂停下载
  ///
  /// 已下载的字节数不会删除
  ///
  /// 状态为undefined/enqueued/failed会移除下载队列
  ///
  /// **parameters**
  ///
  /// [url] 资源远端地址
  static pause(String url) async {
    try {
      final alDownloadTask = _getALDownloadTaskFromUrl(url);
      debugPrint(
          "ALDownloader | pause 将要暂停的url = url = $url, alDownloadTask.status = ${alDownloadTask.status}");

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

  /// 暂停所有正在下载的任务；移除正在队列的任务
  static pauseAll() async {
    final aTemp = [];
    aTemp.addAll(_alDownloadTasks);
    for (final alDownloadTask in aTemp) {
      final url = alDownloadTask.url;
      await pause(url);
    }
  }

  /// 移除[url]对应的ALDownloader资源
  ///
  /// **parameters**
  ///
  /// [url] 资源远端地址
  static remove(String url) async {
    try {
      final alDownloaderTask = _getALDownloadTaskFromUrl(url);
      await FlutterDownloader.remove(
          taskId: alDownloaderTask.taskId,
          shouldDeleteContent:
              true); // Delete a download task from DB & delete file
      _alDownloadTasks.remove(alDownloaderTask);
    } catch (error) {
      debugPrint(
          "ALDownloader | remove alDownloaderTask of url = $url, error = $error");
    }
  }

  /// 移除所有`url`对应的ALDownloader资源
  static removeAll() async {
    for (final alDownloadTask in _alDownloadTasks) remove(alDownloadTask.url);
  }

  /// ---------------------- Private API ----------------------

  /// 维护 自定义下载任务列表
  ///
  /// 目的：避免频繁I/O
  ///
  /// 添加一个新的自定义任务 或 更新[url]映射的已有任务的taskId
  static void _addALDownloadTaskOrReplaceALDownloadTaskId(
      String url, String taskId, DownloadTaskStatus status) {
    if (url == null) {
      debugPrint(
          "_addALDownloadTaskOrReplaceALDownloadTaskId error url == null");
      return;
    }

    _ALDownloadTask anALDownloadTask;

    try {
      anALDownloadTask =
          _alDownloadTasks.firstWhere((element) => element.url == url);
      anALDownloadTask.taskId = taskId;
      anALDownloadTask.status = status;
    } catch (error) {
      debugPrint(
          "ALDownloader | _addALDownloadTaskOrReplaceALDownloadTaskId error = $error");
    }

    if (anALDownloadTask == null) {
      anALDownloadTask = _ALDownloadTask(url);
      anALDownloadTask.taskId = taskId;
      anALDownloadTask.status = status;

      _alDownloadTasks.add(anALDownloadTask);
    }
  }

  /// 向 [IsolateNameServer] 注册 [registerPortWithName]服务
  ///
  /// 用于下载isolate和主isolate间的通信
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

  /// 被[FlutterDownloader]绑定的回调
  static void _downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName(_kDownloaderSendPort);
    send.send([id, status, progress]);
  }

  /// 处理[FlutterDownloader]回调数据
  static void _processDataFromPort(
      String id, DownloadTaskStatus status, int progress) {
    final alDownloadTask = _getALDownloadTaskFromTaskId(id);

    if (alDownloadTask == null) {
      debugPrint("没有找到内存中的alDownloadTask， id = $id");
      return;
    }

    final url = alDownloadTask.url;

    _addALDownloadTaskOrReplaceALDownloadTaskId(url, id, status);

    // ignore: non_constant_identifier_names
    final double_progress =
        double.tryParse(((progress / 100).toStringAsFixed(2)));

    if (status == DownloadTaskStatus.complete) {
      debugPrint(
          "ALDownloader | _downloadCallback \n 下载成功 url = $url \nid = $id ");
      _alDownloaderBinders?.forEach((element) {
        if (element.forUrl == url) {
          element.downloaderHandlerHolder?.progressHandler(double_progress);
          element.downloaderHandlerHolder?.successHandler();
        }
      });
      _alDownloaderBinders.removeWhere((element) => element.forUrl == url);
    } else if (status == DownloadTaskStatus.failed) {
      debugPrint(
          "ALDownloader | _downloadCallback \n 下载失败 url = $url \nid = $id ");
      _alDownloaderBinders?.forEach((element) {
        if (element.forUrl == url) {
          element.downloaderHandlerHolder?.progressHandler(double_progress);
          element.downloaderHandlerHolder?.failureHandler();
        }
      });
    } else if (status == DownloadTaskStatus.running) {
      _alDownloaderBinders?.forEach((element) {
        if (element.forUrl == url)
          element.downloaderHandlerHolder?.progressHandler(double_progress);
      });
    } else if (status == DownloadTaskStatus.paused) {
      _alDownloaderBinders?.forEach((element) {
        if (element.forUrl == url)
          element.downloaderHandlerHolder?.pausedHandler();
      });
    }

    debugPrint(
        "ALDownloader | _downloadCallback \nid = $id \nurl = $url \nstatus = $status \nprogress = $progress \ndouble_progress = $double_progress");
  }

  /// 加载[FlutterDownloader]本地数据库任务到内存缓存 & 尝试执行任务
  static _loadAndTryToRunTask() async {
    final tasks = await FlutterDownloader.loadTasks();
    tasks.forEach((element) {
      debugPrint(
          "_loadAndTryToRunTask element url = ${element.url}, status = ${element.status}, element url = ${element.taskId}");
    });
    debugPrint(
        "ALDownloader | _loadAndTryToRunTask tasks.length = ${tasks.length}");
    final aList = tasks.map((element) {
      final anALDownloadTask = _ALDownloadTask(element.url);
      anALDownloadTask.taskId = element.taskId;
      anALDownloadTask.status = element.status;
      return anALDownloadTask;
    }).toList();
    _alDownloadTasks.addAll(aList);
  }

  /// 根据url从自定义映射的下载事件列表中取[_ALDownloadTask]
  static _ALDownloadTask _getALDownloadTaskFromUrl(String url) {
    var anALDownloadTask;
    try {
      anALDownloadTask =
          _alDownloadTasks.firstWhere((element) => url == element.url);
    } catch (error) {
      debugPrint("ALDownloader | _getALDownloadTaskFromUrl, error = $error");
    }
    return anALDownloadTask;
  }

  /// 根据url从自定义的下载事件列表中取taskId
  // ignore: unused_element
  static String _getTaskIdFromUrl(String url) {
    var taskId;
    try {
      taskId =
          _alDownloadTasks.firstWhere((element) => url == element.url).taskId;
    } catch (error) {
      debugPrint("ALDownloader | _getTaskIdWith, error = $error");
    }
    return taskId;
  }

  /// 根据url从自定义的下载事件列表中取[_ALDownloadTask]
  // ignore: unused_element
  static _ALDownloadTask _getALDownloadTaskFromTaskId(String taskId) {
    var anALDownloadTask;
    try {
      anALDownloadTask =
          _alDownloadTasks.firstWhere((element) => taskId == element.taskId);
    } catch (error) {
      debugPrint("ALDownloader | _getALDownloadTaskFromTaskId, error = $error");
    }
    return anALDownloadTask;
  }

  /// 根据taskId从自定义映射的下载事件列表中取url
  // ignore: unused_element
  static String _getUrlWith(String taskId) {
    var url;
    try {
      url = _alDownloadTasks
          .firstWhere((element) => taskId == element.taskId)
          .url;
    } catch (error) {
      debugPrint("ALDownloader | _getUrlWith, error = $error");
    }
    return url;
  }

  // 是否初始化本下载器
  static bool _isInitial = false;

  // 下载任务自定义列表
  static final List<_ALDownloadTask> _alDownloadTasks = [];

  // 绑定器池
  static final List<_ALDownloaderBinder> _alDownloaderBinders = [];

  // 发送端口key
  static final _kDownloaderSendPort = "al_downloader_send_port";

  // 接收端口对象
  static final ReceivePort _receivePort = ReceivePort();

  // 私有化创建方法
  ALDownloader._();
}

/// 自定义下载任务
class _ALDownloadTask {
  final String url;

  String taskId;
  String subDirectoryName;
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;

  _ALDownloadTask(this.url);
}

/// 下载涉及的元素的绑定器
class _ALDownloaderBinder {
  _ALDownloaderBinder(this.forUrl, this.downloaderHandlerHolder);
  final String forUrl;
  final ALDownloaderHandlerInterface downloaderHandlerHolder;
}
