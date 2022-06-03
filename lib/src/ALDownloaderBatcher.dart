import 'dart:async';
import 'ALDownloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderStatus.dart';
import 'internal/ALDownloaderPrint.dart';

/// ALDownloaderBatcher
///
/// batch download
///
/// progress = number of succeeded urls / number of all urls
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
  /// Summarize the download status for a set of urls.
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
  /// number of succeeded urls / number of all urls
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
        final aProgress = binder.progress;

        aldDebugPrint(
            "ALDownloaderBatcher | progress = $aProgress, progress for url = $progress, url = $url",
            isFrequentPrint: true);

        final progressHandler = downloaderHandlerInterface?.progressHandler;
        if (progressHandler != null) progressHandler(aProgress);
      }, succeededHandler: () {
        aldDebugPrint("ALDownloaderBatcher | download succeeded, url = $url");

        binder._callBackCount++;

        if (binder._isCallBackCompleted) {
          if (binder._isSucceeded) {
            final succeededHandler =
                downloaderHandlerInterface?.succeededHandler;
            if (succeededHandler != null) succeededHandler();
          } else {
            final failedHandler = downloaderHandlerInterface?.failedHandler;
            if (failedHandler != null) failedHandler();
          }
        }
      }, failedHandler: () {
        aldDebugPrint("ALDownloaderBatcher | download failed, url = $url");

        binder._callBackCount++;

        if (binder._isCallBackCompleted) {
          final failedHandler = downloaderHandlerInterface?.failedHandler;
          if (failedHandler != null) failedHandler();
        }
      }, pausedHandler: () {
        aldDebugPrint("ALDownloaderBatcher | download paused, url = $url");

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

  /// Pause downloads
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

  /// Cancel downloads
  ///
  /// This is a multiple of [ALDownloader.cancel], see [ALDownloader.cancel].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static Future<void> cancel(List<String> urls) async {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) await ALDownloader.cancel(url);
  }

  /// Remove downloads
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

  /// Remove duplicated urls
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

/// A binder for binding some elements such as url, downloader interface and so on for ALDownloaderBatcher
class _ALDownloaderBatcherBinder {
  /// Get result whether [_targetUrls] are all succeeded
  bool get _isSucceeded => _succeededUrls.length == _targetUrls.length;

  /// Get succeeded urls
  List<String> get _succeededUrls {
    List<String> aList;

    try {
      aList = _completeKVs.entries
          .where(
              (element) => element.value && _targetUrls.contains(element.key))
          .map((e) => e.key)
          .toList();

      aldDebugPrint("get _succeededUrls result = $aList",
          isFrequentPrint: true);
    } catch (error) {
      aList = <String>[];
      aldDebugPrint("get _succeededUrls error = $error");
    }

    return aList;
  }

  /// Get failed urls
  // ignore: unused_element
  List<String> get _failedUrls {
    List<String> aList;

    try {
      aList = _completeKVs.entries
          .where(
              (element) => !element.value && _targetUrls.contains(element.key))
          .map((e) => e.key)
          .toList();

      aldDebugPrint(
          "_ALDownloaderBatcherBinder | get _failedUrls, result = $aList",
          isFrequentPrint: true);
    } catch (error) {
      aList = <String>[];
      aldDebugPrint(
          "_ALDownloaderBatcherBinder | get _failedUrls, error = $error");
    }

    return aList;
  }

  /// Get progress
  ///
  /// progress = number of succeeded urls / number of all urls
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
      aldDebugPrint("_ALDownloaderBatcherBinder | get progress, $error");
    }

    return aDouble;
  }

  /// Get succeeded/failed call back count
  ///
  /// If it is equal to [_targetUrls.length], represent all the call back completed.
  int _callBackCount = 0;

  /// Check whether all the call back completed.
  bool get _isCallBackCompleted => _callBackCount == _targetUrls.length;

  /// Get result whether [_targetUrls] are all completed
  ///
  /// Just completed, it may be succeeded or failed.
  // ignore: unused_element
  bool get _isCompleted =>
      _completeKVs.keys.toSet().containsAll(_targetUrls.toSet());

  /// A set of completed key-value pairs of [ALDownloader]
  Map<String, bool> get _completeKVs => ALDownloader.completedKVs;

  /// Urls that need to download
  final List<String> _targetUrls;

  /// Privatize constructor
  _ALDownloaderBatcherBinder._(this._targetUrls);
}
