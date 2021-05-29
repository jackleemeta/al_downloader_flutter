import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ALDownloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderPersistentFileManager.dart';

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
  ///
  /// [subDirectoryName] 子文件夹名称
  static Future<void> downloadUrls(List<String> urls,
      {ALDownloaderHandlerInterface downloaderHandlerInterface,
      String subDirectoryName}) async {
    addALDownloaderHandlerInterface(downloaderHandlerInterface, urls);

    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls)
      await ALDownloader.download(url, subDirectoryName: subDirectoryName);
  }

  /// 添加监听
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] 回调句柄池
  ///
  /// [urls] url列表
  static void addALDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface,
      List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    final binder = _ALDownloaderBatcherBinder._(aNonDuplicatedUrls);

    for (final url in aNonDuplicatedUrls) {
      final aDownloaderHandlerInterface =
          ALDownloaderHandlerInterface(progressHandler: (progress) {
        debugPrint("ALDownloaderProlongation | 正在下载， url = $url");

        downloaderHandlerInterface?.progressHandler(binder.progress);
      }, successHandler: () {
        debugPrint("ALDownloaderProlongation | 下载成功， url = $url");

        // 下载成功：ALDownloader中的下载成功个数 = targetUrls
        downloaderHandlerInterface?.progressHandler(binder.progress);

        if (binder._isSuccess)
          _tryToCallBackForCompletion(binder, downloaderHandlerInterface);
      }, failureHandler: () {
        debugPrint("ALDownloaderProlongation | 下载失败， url = $url");

        // 下载失败： ALDownloader中的下载处理过的个数 = targetUrls， 成功的个数 < 总共的个数
        if (binder._isOver && !binder._isSuccess)
          downloaderHandlerInterface?.failureHandler();
      }, pausedHandler: () {
        debugPrint("ALDownloaderProlongation | 已暂停， url = $url");
        downloaderHandlerInterface?.pausedHandler();
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
    urls?.forEach((element) =>
        ALDownloader.removeALDownloaderHandlerInterfaceForUrl(element));
  }

  /// 暂停下载一组url
  ///
  /// **parameters**
  ///
  /// [urls] 资源远端地址列表
  static Future<void> pause(List<String> urls) async {
    for (final url in urls) await ALDownloader.pause(url);
  }

  /// 移除下载资源
  ///
  /// 包括1. ALDownloader内存缓存 2.Flutterdownloader数据库索引 3.持久化文件数据
  ///
  /// **parameters**
  ///
  /// [urls] 资源远端地址列表
  static Future<void> clear(List<String> urls) async {
    for (final url in urls) {
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
  ///
  /// [subDirectoryName] 子文件夹名称
  static void removeDirectory(
      String subDirectoryName, String aboutGeneralUrl) async {
    final pathOfDirctory = await ALDownloaderPersistentFileManager
        .getAbsolutePathOfDirectoryWithUrl(aboutGeneralUrl,
            subDirectoryName: subDirectoryName);

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
      ALDownloaderHandlerInterface downloaderHandlerInterface) {
    if (binder._isSuccess) {
      downloaderHandlerInterface?.successHandler();
    } else {
      downloaderHandlerInterface?.failureHandler();
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
      dynamic result = _succeedUrls.length / _targetUrls.length;
      result = result.toStringAsFixed(2);
      aDouble = double.tryParse(result);
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
