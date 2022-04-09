import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ALDownloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderStatus.dart';

/// ALDownloaderBatcher
///
/// batch download
/// progress = number of successful tasks / number of all tasks
class ALDownloaderBatcher {
  /// download
  ///
  /// [urls] urls
  ///
  /// [downloaderHandlerInterface] the download handle interface
  static Future<void> downloadUrls(List<String> urls,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) async {
    addALDownloaderHandlerInterface(downloaderHandlerInterface, urls);

    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls) await ALDownloader.download(url);
  }

  /// summarize the download status of a set of urls
  ///
  /// **parameters**
  ///
  /// [urls] s set of url
  ///
  /// **return**
  ///
  /// [ALDownloaderStatus] download status
  static ALDownloaderStatus getDownloadStatusForUrls(List<String> urls) {
    final Map<String, ALDownloaderStatus> aMap = {};
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls) {
      final aStatus = ALDownloader.getDownloadStatusForUrl(url);

      if (aStatus == ALDownloaderStatus.downloading) {
        // contain downloading task
        return ALDownloaderStatus.downloading;
      } else if (aStatus == ALDownloaderStatus.pausing) {
        // contain paused task
        return ALDownloaderStatus.pausing;
      }

      aMap[url] = aStatus;
    }

    final allStatus = aMap.values.toSet();

    if (allStatus.contains(ALDownloaderStatus.downloadFailed)) {
      // not contain downloaded task && not contain paused task && contain one failed task at least
      return ALDownloaderStatus.downloadFailed;
    } else if (allStatus
            .difference({ALDownloaderStatus.downloadSucceeded}).length ==
        0) {
      // not contain downloading task && not contain paused task && not contain failed task && task is all successful
      return ALDownloaderStatus.downloadSucceeded;
    }
    // not contain downloading task && not contain failed task && not contain paused task && contain unsuccessful task
    return ALDownloaderStatus.unstarted;
  }

  /// get download progress of a set of urls
  ///
  /// number of successful tasks / number of all tasks
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// **return**
  ///
  /// [double] download progress of urls
  static double getProgressForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);
    final binder = _ALDownloaderBatcherBinder._(aNonDuplicatedUrls);
    final progress = binder.progress;
    return progress;
  }

  /// add a download handle interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] download handle interface
  ///
  /// [urls] urls
  static void addALDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface,
      List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    final binder = _ALDownloaderBatcherBinder._(aNonDuplicatedUrls);

    for (final url in aNonDuplicatedUrls) {
      final aDownloaderHandlerInterface =
          ALDownloaderHandlerInterface(progressHandler: (progress) {
        debugPrint("ALDownloaderBatcher | downloading, the url = $url");

        final progressHandler = downloaderHandlerInterface?.progressHandler;
        if (progressHandler != null) progressHandler(binder.progress);
      }, successHandler: () {
        debugPrint(
            "ALDownloaderBatcher | download successfully, the url = $url");

        if (binder._isSuccess)
          _tryToCallBackForCompletion(binder, downloaderHandlerInterface);
      }, failureHandler: () {
        debugPrint("ALDownloaderBatcher | download failed, the url = $url");

        if (binder._isOver && !binder._isSuccess) {
          final failureHandler = downloaderHandlerInterface?.failureHandler;
          if (failureHandler != null) failureHandler();
        }
      }, pausedHandler: () {
        debugPrint("ALDownloaderBatcher | download paused, the url = $url");
        final pausedHandler = downloaderHandlerInterface?.pausedHandler;
        if (pausedHandler != null) pausedHandler();
      });

      ALDownloader.addALDownloaderHandlerInterface(
          aDownloaderHandlerInterface, url);
    }
  }

  /// remove a download handle interface
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void removeALDownloaderHandlerInterfaceForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    aNonDuplicatedUrls.forEach((element) =>
        ALDownloader.removeALDownloaderHandlerInterfaceForUrl(element));
  }

  /// pause downloading a set of urls
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static Future<void> pause(List<String> urls) async {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls) await ALDownloader.pause(url);
  }

  /// clear download
  ///
  /// including: 1.ALDownloader memory cache 2.Flutterdownloader database index 3.Persist file data
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static Future<void> clear(List<String> urls) async {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFrom(urls);

    for (final url in aNonDuplicatedUrls) {
      await ALDownloader.cancel(url);
      await ALDownloader.remove(url);
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

  // remove duplication of urls
  static List<String> _getNonDuplicatedUrlsFrom(List<String> urls) {
    final aNonDuplicatedUrls = <String>[];
    for (final element in urls) {
      if (!aNonDuplicatedUrls.contains(element))
        aNonDuplicatedUrls.add(element);
    }
    return aNonDuplicatedUrls;
  }

  ALDownloaderBatcher._();
}

/// a binder for binding element of url and download ininterface for ALDownloaderBatcher
class _ALDownloaderBatcherBinder {
  bool get _isSuccess => _succeededUrls.length == _targetUrls.length;

  List<String> get _succeededUrls {
    List<String> aList;

    try {
      aList = _alDownloaderUrlDownloadedKVs.entries
          .where(
              (element) => element.value && _targetUrls.contains(element.key))
          .map((e) => e.key)
          .toList();

      debugPrint("get _succeededUrls result = $aList");
    } catch (error) {
      aList = <String>[];
      debugPrint("get _succeededUrls error = $error");
    }

    return aList;
  }

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

  /// process
  ///
  /// progress = number of successful tasks / number of all tasks
  double get progress {
    double aDouble = 0;

    try {
      if (_targetUrls.length == 0) {
        aDouble = 0;
      } else {
        dynamic result = _succeededUrls.length / _targetUrls.length;
        result = result.toStringAsFixed(2);
        aDouble = double.tryParse(result) ?? 0;
      }
    } catch (error) {
      aDouble = 0;
      debugPrint("$error");
    }

    return aDouble;
  }

  /// all download tasks are completed
  /// just completed, it may be successful or failed
  bool get _isOver => _alDownloaderUrlDownloadedKVs.keys
      .toSet()
      .containsAll(_targetUrls.toSet());

  /// download status for ALDownloader
  static Map<String, bool> get _alDownloaderUrlDownloadedKVs =>
      ALDownloader.urlResults;

  /// need to download urls
  final List<String> _targetUrls;

  /// privatize constructor
  _ALDownloaderBatcherBinder._(this._targetUrls);
}
