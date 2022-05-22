import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ALDownloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderStatus.dart';

/// ALDownloaderBatcher
///
/// batch download
///
/// progress = number of succeeded tasks / number of all tasks
class ALDownloaderBatcher {
  /// Download
  ///
  /// [urls] urls
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  static Future<void> downloadUrls(List<String> urls,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) async {
    addDownloaderHandlerInterface(downloaderHandlerInterface, urls);

    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) await ALDownloader.download(url);
  }

  /// Get download status
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// **return**
  ///
  /// [ALDownloaderStatus] download status
  static ALDownloaderStatus getDownloadStatusForUrls(List<String> urls) {
    final Map<String, ALDownloaderStatus> aMap = {};
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) {
      final aStatus = ALDownloader.getDownloadStatusForUrl(url);

      if (aStatus == ALDownloaderStatus.downloading) {
        // Contain downloading task.
        return ALDownloaderStatus.downloading;
      } else if (aStatus == ALDownloaderStatus.paused) {
        // Contain paused task.
        return ALDownloaderStatus.paused;
      }

      aMap[url] = aStatus;
    }

    final allStatus = aMap.values.toSet();

    if (allStatus.contains(ALDownloaderStatus.failed)) {
      // Do not Contained downloaded task && Do not contain paused task && Contain failed task.
      return ALDownloaderStatus.failed;
    } else if (allStatus.difference({ALDownloaderStatus.succeeded}).length ==
        0) {
      // Do not contain downloading task && Do not contain paused task && Do not contain failed task && Tasks are all succeeded.
      return ALDownloaderStatus.succeeded;
    }
    // Do not contain downloading task && Do not contain failed task && Do not contain paused task && Contain task which is not succeeded.
    return ALDownloaderStatus.unstarted;
  }

  /// Get download progress
  ///
  /// number of successful tasks / number of all tasks
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// **return**
  ///
  /// [double] download progress
  static double getProgressForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);
    final binder = _ALDownloaderBatcherBinder._(aNonDuplicatedUrls);
    final progress = binder.progress;
    return progress;
  }

  /// Add a downloader handler interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// [urls] urls
  static void addDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface,
      List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    final binder = _ALDownloaderBatcherBinder._(aNonDuplicatedUrls);

    for (final url in aNonDuplicatedUrls) {
      final aDownloaderHandlerInterface =
          ALDownloaderHandlerInterface(progressHandler: (progress) {
        debugPrint("ALDownloaderBatcher | downloading, url = $url");

        final progressHandler = downloaderHandlerInterface?.progressHandler;
        if (progressHandler != null) progressHandler(binder.progress);
      }, succeededHandler: () {
        debugPrint("ALDownloaderBatcher | download succeeded, url = $url");

        if (binder._completeKVs == null) binder._completeKVs = {};

        binder._completeKVs![url] = true;

        if (binder._isOver) {
          if (binder._isSucceeded) {
            final succeededHandler =
                downloaderHandlerInterface?.succeededHandler;
            if (succeededHandler != null) succeededHandler();
          } else {
            final failedHandler = downloaderHandlerInterface?.failedHandler;
            if (failedHandler != null) failedHandler();
          }

          binder._completeKVs = null;
        }
      }, failedHandler: () {
        debugPrint("ALDownloaderBatcher | download failed, url = $url");

        if (binder._completeKVs == null) binder._completeKVs = {};

        binder._completeKVs![url] = false;

        if (binder._isOver) {
          final failedHandler = downloaderHandlerInterface?.failedHandler;
          if (failedHandler != null) failedHandler();
          binder._completeKVs = null;
        }
      }, pausedHandler: () {
        debugPrint("ALDownloaderBatcher | download paused, url = $url");

        final pausedHandler = downloaderHandlerInterface?.pausedHandler;
        if (pausedHandler != null) pausedHandler();
      });

      ALDownloader.addDownloaderHandlerInterface(
          aDownloaderHandlerInterface, url);
    }
  }

  /// Remove downloader handler interfaces
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void removeDownloaderHandlerInterfaceForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    aNonDuplicatedUrls.forEach((element) =>
        ALDownloader.removeDownloaderHandlerInterfaceForUrl(element));
  }

  /// Pause download
  ///
  /// This is a multiple of [ALDownloader.pause], see [ALDownloader.pause].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static Future<void> pause(List<String> urls) async {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) await ALDownloader.pause(url);
  }

  /// Remove download
  ///
  /// This is a multiple of [ALDownloader.remove], see [ALDownloader.remove].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static Future<void> remove(List<String> urls) async {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) await ALDownloader.remove(url);
  }

  // Remove duplicated urls
  static List<String> _getNonDuplicatedUrlsFromUrls(List<String> urls) {
    final aNonDuplicatedUrls = <String>[];
    for (final element in urls) {
      if (!aNonDuplicatedUrls.contains(element))
        aNonDuplicatedUrls.add(element);
    }
    return aNonDuplicatedUrls;
  }

  ALDownloaderBatcher._();
}

/// A binder for binding some element such as url and download ininterface for ALDownloaderBatcher
class _ALDownloaderBatcherBinder {
  /// Get result of whether [_targetUrls] are all succeeded
  bool get _isSucceeded => _succeededUrls.length == _targetUrls.length;

  /// Get succeeded urls
  List<String> get _succeededUrls {
    List<String> aList;

    try {
      if (_completeKVs == null) return <String>[];
      aList = _completeKVs!.entries
          .where((element) => element.value)
          .map((e) => e.key)
          .toList();

      debugPrint("get _succeededUrls result = $aList");
    } catch (error) {
      aList = <String>[];
      debugPrint("get _succeededUrls error = $error");
    }

    return aList;
  }

  /// Get failed urls
  // ignore: unused_element
  List<String> get _failedUrls {
    List<String> aList;

    try {
      if (_completeKVs == null) return <String>[];
      aList = _completeKVs!.entries
          .where((element) => !element.value)
          .map((e) => e.key)
          .toList();

      debugPrint("get _failedUrls result = $aList");
    } catch (error) {
      aList = <String>[];
      debugPrint("get _failedUrls error = $error");
    }

    return aList;
  }

  /// Get progress
  ///
  /// progress = number of succeeded tasks / number of all tasks
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

  /// Get result whether [_targetUrls] are completed
  ///
  /// Just completed, it may be successful or failed.
  bool get _isOver {
    if (_completeKVs == null) return false;
    return _completeKVs!.length == _targetUrls.length;
  }

  /// A set of completed key-value pairs of [ALDownloader]
  Map<String, bool>? _completeKVs;

  /// Urls that need to be downloaded
  final List<String> _targetUrls;

  /// Privatize constructor
  _ALDownloaderBatcherBinder._(this._targetUrls);
}
