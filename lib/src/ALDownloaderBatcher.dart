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
  static void downloadUrls(List<String> urls,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) {
    addDownloaderHandlerInterface(downloaderHandlerInterface, urls);

    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) ALDownloader.download(url);
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
  static ALDownloaderStatus getStatusForUrls(List<String> urls) {
    final Map<String, ALDownloaderStatus> aMap = {};
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) {
      final aStatus = ALDownloader.getStatusForUrl(url);

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
      // Do not contain downloaded task && Do not contain paused task && Contain failed task.
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
    final progress = binder._progress;
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
      final aDownloaderHandlerInterface = ALDownloaderHandlerInterface(
          progressHandler: (progress) {},
          succeededHandler: () {
            binder._completedKVs[url] = true;

            final progress = binder._progress;

            aldDebugPrint(
                "ALDownloaderBatcher | in succeededHandler | download progress = $progress, url = $url",
                isFrequentPrint: true);

            final progressHandler = downloaderHandlerInterface?.progressHandler;
            if (progressHandler != null) progressHandler(progress);

            if (binder._isCompletedHandlerCalled) {
              if (binder._isSucceeded) {
                aldDebugPrint(
                    "ALDownloaderBatcher | in succeededHandler | download succeeded, urls = $urls");

                final succeededHandler =
                    downloaderHandlerInterface?.succeededHandler;
                if (succeededHandler != null) succeededHandler();
              } else {
                aldDebugPrint(
                    "ALDownloaderBatcher | in succeededHandler | download failed, succeeded urls = ${binder._succeededUrls}, failed urls = ${binder._failedUrls}");

                final failedHandler = downloaderHandlerInterface?.failedHandler;
                if (failedHandler != null) failedHandler();
              }
            }
          },
          failedHandler: () {
            binder._completedKVs[url] = false;

            final progress = binder._progress;

            aldDebugPrint(
                "ALDownloaderBatcher | in failedHandler | download progress = $progress, url = $url",
                isFrequentPrint: true);

            final progressHandler = downloaderHandlerInterface?.progressHandler;
            if (progressHandler != null) progressHandler(progress);

            if (binder._isCompletedHandlerCalled) {
              aldDebugPrint(
                  "ALDownloaderBatcher | in failedHandler | download failed, succeeded urls = ${binder._succeededUrls}, failed urls = ${binder._failedUrls}");

              final failedHandler = downloaderHandlerInterface?.failedHandler;
              if (failedHandler != null) failedHandler();
            }
          },
          pausedHandler: () {
            if (!binder._isDownloading) {
              if (!binder._isIgnoreUnnecessaryPausedHandlerCalled) {
                aldDebugPrint(
                    "ALDownloaderBatcher | download paused, all the targetUrls are not downloading, the targetUrls = ${binder._targetUrls}, the paused urls = ${binder._pausedUrls}, the last paused url = $url");

                binder._isIgnoreUnnecessaryPausedHandlerCalled = true;

                final pausedHandler = downloaderHandlerInterface?.pausedHandler;
                if (pausedHandler != null) pausedHandler();
              }
            } else {
              binder._isIgnoreUnnecessaryPausedHandlerCalled = false;
            }
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
  static void pause(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) ALDownloader.pause(url);
  }

  /// Cancel downloads
  ///
  /// This is a multiple of [ALDownloader.cancel], see [ALDownloader.cancel].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void cancel(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) ALDownloader.cancel(url);
  }

  /// Remove downloads
  ///
  /// This is a multiple of [ALDownloader.remove], see [ALDownloader.remove].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void remove(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) ALDownloader.remove(url);
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
      aList = _completedKVs.entries
          .where((element) => element.value)
          .map((e) => e.key)
          .toList();

      aldDebugPrint(
          "_ALDownloaderBatcherBinder | get _succeededUrls, result = $aList",
          isFrequentPrint: true);
    } catch (error) {
      aList = <String>[];
      aldDebugPrint(
          "_ALDownloaderBatcherBinder | get _succeededUrls, error = $error");
    }

    return aList;
  }

  /// Get failed urls
  // ignore: unused_element
  List<String> get _failedUrls {
    List<String> aList;

    try {
      aList = _completedKVs.entries
          .where((element) => !element.value)
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
  double get _progress {
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

  /// Whether exist downloading url
  bool get _isDownloading {
    for (final element in _targetUrls) {
      final status = ALDownloader.getStatusForUrl(element);
      if (status == ALDownloaderStatus.downloading) return true;
    }

    return false;
  }

  /// The paused urls among [_targetUrls]
  List<String> get _pausedUrls {
    final aList = <String>[];
    for (final element in _targetUrls) {
      final status = ALDownloader.getStatusForUrl(element);
      if (status == ALDownloaderStatus.paused) aList.add(element);
    }

    return aList;
  }

  /// Whether ignore unnecessary paused handler called
  bool _isIgnoreUnnecessaryPausedHandlerCalled = false;

  /// Check whether all the completed handler called
  bool get _isCompletedHandlerCalled =>
      _completedKVs.length == _targetUrls.length;

  /// A set of completed key-value pairs
  final Map<String, bool> _completedKVs = {};

  /// Urls that need to download
  final List<String> _targetUrls;

  /// Privatize constructor
  _ALDownloaderBatcherBinder._(this._targetUrls);
}
