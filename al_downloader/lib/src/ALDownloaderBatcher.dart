import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ALDownloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderPersistentFileManager.dart';
import 'ALDownloaderStatus.dart';

/// ALDownloader拓展
///
/// 批量下载
/// 进度 = 单个已成功的任务 / 所有任务
class ALDownloaderBatcher {
  /// 下载
  ///
  /// [urls] url列表
  ///
  /// [downloaderHandlerInterface] 回调句柄池
  static Future<void> downloadUrls(List<String> urls,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) async {
    addALDownloaderHandlerInterface(downloaderHandlerInterface, urls);

    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls) await ALDownloader.download(url);
  }

  /// 总结一组url的下载状态
  ///
  /// **parameters**
  ///
  /// [urls] 一组url
  ///
  /// **return**
  ///
  /// [ALDownloaderStatus] 下载状态
  static ALDownloaderStatus getDownloadStatusForUrls(List<String> urls) {
    final Map<String, ALDownloaderStatus> aMap = {};
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls) {
      final aStatus = ALDownloader.getDownloadStatusForUrl(url);

      if (aStatus == ALDownloaderStatus.downloading) {
        // 有正在下载的任务
        return ALDownloaderStatus.downloading;
      } else if (aStatus == ALDownloaderStatus.pausing) {
        // 有暂停的任务
        return ALDownloaderStatus.pausing;
      }

      aMap[url] = aStatus;
    }

    final allStatus = aMap.values.toSet();

    if (allStatus.contains(ALDownloaderStatus.downloadFailed)) {
      // 无正在下载的任务 && 无暂停的任务 && 有一个失败
      return ALDownloaderStatus.downloadFailed;
    } else if (allStatus
            .difference({ALDownloaderStatus.downloadSuccced}).length ==
        0) {
      // 无正在下载的任务 && 无暂停的任务 && 无失败 && 全都已成功
      return ALDownloaderStatus.downloadSuccced;
    }
    // 无正在下载的任务 && 无失败 && 无暂停的任务 && 有一部分未成功 && 无暂停
    return ALDownloaderStatus.unstarted;
  }

  /// 获取一组url的下载进度
  ///
  /// 下载成功条数/总条数
  ///
  /// **parameters**
  ///
  /// [urls] 一组url
  ///
  /// **return**
  ///
  /// [double] 下载进度
  static double getProgressForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);
    final binder = _ALDownloaderBatcherBinder._(aNonDuplicatedUrls);
    final progress = binder.progress;
    return progress;
  }

  /// 添加监听
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] 回调句柄池
  ///
  /// [urls] url列表
  static void addALDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface,
      List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    final binder = _ALDownloaderBatcherBinder._(aNonDuplicatedUrls);

    for (final url in aNonDuplicatedUrls) {
      final aDownloaderHandlerInterface =
          ALDownloaderHandlerInterface(progressHandler: (progress) {
        debugPrint("ALDownloaderBatcher | 正在下载， url = $url");

        final progressHandler = downloaderHandlerInterface?.progressHandler;
        if (progressHandler != null) progressHandler(binder.progress);
      }, successHandler: () {
        debugPrint("ALDownloaderBatcher | 下载成功， url = $url");

        if (binder._isSuccess)
          _tryToCallBackForCompletion(binder, downloaderHandlerInterface);
      }, failureHandler: () {
        debugPrint("ALDownloaderBatcher | 下载失败， url = $url");

        if (binder._isOver && !binder._isSuccess) {
          final failureHandler = downloaderHandlerInterface?.failureHandler;
          if (failureHandler != null) failureHandler();
        }
      }, pausedHandler: () {
        debugPrint("ALDownloaderBatcher | 已暂停， url = $url");
        final pausedHandler = downloaderHandlerInterface?.pausedHandler;
        if (pausedHandler != null) pausedHandler();
      });

      ALDownloader.addALDownloaderHandlerInterface(
          aDownloaderHandlerInterface, url);
    }
  }

  /// 移除监听
  ///
  /// **parameters**
  ///
  /// [urls] 资源远端地址列表
  static void removeALDownloaderHandlerInterfaceForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    aNonDuplicatedUrls.forEach((element) =>
        ALDownloader.removeALDownloaderHandlerInterfaceForUrl(element));
  }

  /// 暂停下载一组url
  ///
  /// **parameters**
  ///
  /// [urls] 资源远端地址列表
  static Future<void> pause(List<String> urls) async {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls) await ALDownloader.pause(url);
  }

  /// 移除下载资源
  ///
  /// 包括1. ALDownloader内存缓存 2.Flutterdownloader数据库索引 3.持久化文件数据
  ///
  /// **parameters**
  ///
  /// [urls] 资源远端地址列表
  static Future<void> clear(List<String> urls) async {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls) {
      await ALDownloader.cancel(url);
      await ALDownloader.remove(url);
    }
  }

  /// 删除[aboutGeneralUrl]对应资源所在的整个文件夹和文件夹内容
  ///
  /// 由于[clear]方法不能完全确保持久化数据被删除，所以需要调用此方法删除文件夹
  ///
  /// **parameters**
  ///
  /// [aboutGeneralUrl] url
  static void removeDirectory(String aboutGeneralUrl) async {
    final pathOfDirctory = await ALDownloaderPersistentFileManager
        .getAbsolutePathOfDirectoryWithUrl(aboutGeneralUrl);

    debugPrint(
        "ALDownloaderProlongation removeDirectory | pathOfDirctory = $pathOfDirctory");

    try {
      final directory = Directory(pathOfDirctory);
      directory.deleteSync(recursive: true);
    } catch (error) {
      debugPrint("ALDownloaderProlongation removeDirectory | error = $error");
    }
  }

  /// ------------------------------------ Private API ------------------------------------

  static void _tryToCallBackForCompletion(_ALDownloaderBatcherBinder binder,
      ALDownloaderHandlerInterface? downloaderHandlerInterface) {
    if (binder._isSuccess) {
      final successHandler = downloaderHandlerInterface?.successHandler;
      if (successHandler != null) successHandler();
    } else {
      final failureHandler = downloaderHandlerInterface?.failureHandler;
      if (failureHandler != null) failureHandler();
    }
  }

  // 去重
  static List<String> _getNonDuplicatedUrlsFrom(List<String> urls) {
    final aNonDuplicatedUrls = <String>[];
    for (final element in urls) {
      if (!aNonDuplicatedUrls.contains(element)) {
        aNonDuplicatedUrls.add(element);
      }
    }
    return aNonDuplicatedUrls;
  }

  ALDownloaderBatcher._();
}

/// 下载拓展类涉及的元素的绑定器
class _ALDownloaderBatcherBinder {
  /// 是否成功
  bool get _isSuccess => _succeedUrls.length == _targetUrls.length;

  /// 下载成功的url列表
  List<String> get _succeedUrls {
    List<String> aList;

    try {
      aList = _alDownloaderUrlDownloadedKVs.entries
          .where(
              (element) => element.value && _targetUrls.contains(element.key))
          .map((e) => e.key)
          .toList();

      debugPrint("get _succeedUrls result = $aList");
    } catch (error) {
      aList = <String>[];
      debugPrint("get _succeedUrls error = $error");
    }

    return aList;
  }

  /// 下载失败的url列表
  // ignore: unused_element
  List<String> get _failedUrls {
    List<String> aList;

    try {
      aList = _alDownloaderUrlDownloadedKVs.entries
          .where(
              (element) => !element.value && _targetUrls.contains(element.key))
          .map((e) => e.key)
          .toList();

      debugPrint("get _failedUrls result = $aList");
    } catch (error) {
      aList = <String>[];
      debugPrint("get _failedUrls error = $error");
    }

    return aList;
  }

  /// 进度
  ///
  /// 已下载条数 / 总条数
  double get progress {
    double aDouble = 0;

    try {
      if (_targetUrls.length == 0) {
        aDouble = 0;
      } else {
        dynamic result = _succeedUrls.length / _targetUrls.length;
        result = result.toStringAsFixed(2);
        aDouble = double.tryParse(result) ?? 0;
      }
    } catch (error) {
      aDouble = 0;
      debugPrint("$error");
    }

    return aDouble;
  }

  /// 所有下载任务已收到回调
  bool get _isOver => _alDownloaderUrlDownloadedKVs.keys
      .toSet()
      .containsAll(_targetUrls.toSet());

  /// ALDownloader中的下载状态
  static Map<String, bool> get _alDownloaderUrlDownloadedKVs =>
      ALDownloader.urlResults;

  /// 此次需要下载的url
  final List<String> _targetUrls;

  /// 初始化方法
  _ALDownloaderBatcherBinder._(this._targetUrls);
}
