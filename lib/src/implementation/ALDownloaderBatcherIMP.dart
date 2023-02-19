import 'ALDownloaderIMP.dart';
import '../ALDownloaderHandlerInterface.dart';
import '../ALDownloaderStatus.dart';
import '../chore/ALDownloaderBatcherInputVO.dart';
import '../internal/ALDownloaderConstant.dart';
import '../internal/ALDownloaderHeader.dart';
import '../internal/ALDownloaderMessage.dart';
import '../internal/ALDownloaderPrint.dart';

abstract class ALDownloaderBatcherIMP {
  static void download(List<String> urls,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kDownload;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    if (downloaderHandlerInterface != null) {
      final id = ALDownloaderHeader.uuid.v1();
      _interfaceKVs[id] = downloaderHandlerInterface;
      message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;
    }

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void downloadUrlsWithVOs(List<ALDownloaderBatcherInputVO> vos,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kDownloadUrlsWithVOs;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kALDownloaderBatcherInputVOs: vos
    };

    if (downloaderHandlerInterface != null) {
      final id = ALDownloaderHeader.uuid.v1();
      _interfaceKVs[id] = downloaderHandlerInterface;
      message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;
    }

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void addDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface,
      List<String> urls) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kAddDownloaderHandlerInterface;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    final id = ALDownloaderHeader.uuid.v1();
    _interfaceKVs[id] = downloaderHandlerInterface;
    message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeDownloaderHandlerInterfaceForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    aNonDuplicatedUrls.forEach((element) =>
        ALDownloaderIMP.removeDownloaderHandlerInterfaceForUrl(element));

    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action =
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForUrls;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static ALDownloaderStatus getStatusForUrls(List<String> urls) {
    final aMap = <String, ALDownloaderStatus>{};
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) {
      final aStatus = ALDownloaderIMP.getStatusForUrl(url);

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

  static double getProgressForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);
    int succeededCount = 0;
    for (final url in aNonDuplicatedUrls) {
      final aStatus = ALDownloaderIMP.getStatusForUrl(url);
      if (aStatus == ALDownloaderStatus.succeeded) succeededCount++;
    }

    double aDouble;

    try {
      if (aNonDuplicatedUrls.length == 0) {
        aDouble = 0;
      } else {
        dynamic result = succeededCount / aNonDuplicatedUrls.length;
        result = result.toStringAsFixed(2);
        aDouble = double.tryParse(result) ?? 0;
      }
    } catch (error) {
      aDouble = 0;
      aldDebugPrint('ALDownloaderBatcher | get progress for urls, $error');
    }

    return aDouble;
  }

  static void pause(List<String> urls) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kPause;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void cancel(List<String> urls) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kCancel;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void remove(List<String> urls) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kRemove;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  /// Do work on root isolate
  static void doWorkOnRootIsolate(ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;
    if (action == ALDownloaderConstant.kCallInterface) {
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      final isNeedCallProgressHandler =
          content[ALDownloaderConstant.kIsNeedCallProgressHandler];
      final isNeedCallSucceededHandler =
          content[ALDownloaderConstant.kIsNeedCallSucceededHandler];
      final isNeedCallFailedHandler =
          content[ALDownloaderConstant.kIsNeedCallFailedHandler];
      final isNeedCallPausedHandler =
          content[ALDownloaderConstant.kIsNeedCallPausedHandler];
      final progress = content[ALDownloaderConstant.kProgress];
      final isNeedRemoveInterfaceAfterCallForRoot =
          content[ALDownloaderConstant.kIsNeedRemoveInterfaceAfterCallForRoot];

      final downloaderHandlerInterface = _interfaceKVs[id];

      ALDownloaderHeader.callInterfaceById(
          downloaderHandlerInterface,
          isNeedCallProgressHandler,
          isNeedCallSucceededHandler,
          isNeedCallFailedHandler,
          isNeedCallPausedHandler,
          progress);

      if (isNeedRemoveInterfaceAfterCallForRoot) _interfaceKVs.remove(id);
    }
  }

  /// Do work on ALDownloader isolate
  static void doWorkOnALIsolate(ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;

    if (action == ALDownloaderConstant.kAddDownloaderHandlerInterface) {
      final urls = content[ALDownloaderConstant.kUrls];
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _addDownloaderHandlerInterface(id, urls);
    } else if (action ==
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForUrls) {
      final urls = content[ALDownloaderConstant.kUrls];
      _removeDownloaderHandlerInterfaceForUrls(urls);
    } else {
      if (ALDownloaderHeader.initializedCompleter.isCompleted) {
        _doWorkWhichMustBeAfterInitializedOnALIsolate(message);
      } else {
        ALDownloaderHeader.initializedCompleter.future.then(
            (_) => _doWorkWhichMustBeAfterInitializedOnALIsolate(message));
      }
    }
  }

  static void _doWorkWhichMustBeAfterInitializedOnALIsolate(
      ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;

    if (action == ALDownloaderConstant.kDownload) {
      final urls = content[ALDownloaderConstant.kUrls];
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _download(urls, downloaderHandlerInterfaceId: id);
    } else if (action == ALDownloaderConstant.kDownloadUrlsWithVOs) {
      final vos = content[ALDownloaderConstant.kALDownloaderBatcherInputVOs];
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _downloadUrlsWithVOs(vos, downloaderHandlerInterfaceId: id);
    } else if (action == ALDownloaderConstant.kPause) {
      final urls = content[ALDownloaderConstant.kUrls];
      _pause(urls);
    } else if (action == ALDownloaderConstant.kCancel) {
      final urls = content[ALDownloaderConstant.kUrls];
      _cancel(urls);
    } else if (action == ALDownloaderConstant.kRemove) {
      final urls = content[ALDownloaderConstant.kUrls];
      _remove(urls);
    }
  }

  static void _download(List<String> urls,
      {String? downloaderHandlerInterfaceId}) {
    if (downloaderHandlerInterfaceId != null)
      _addDownloaderHandlerInterface(downloaderHandlerInterfaceId, urls);

    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) ALDownloaderIMP.cDownload(url);
  }

  static void _downloadUrlsWithVOs(List<ALDownloaderBatcherInputVO> vos,
      {String? downloaderHandlerInterfaceId}) {
    final urls = vos.map((e) => e.url).toList();
    if (downloaderHandlerInterfaceId != null)
      _addDownloaderHandlerInterface(downloaderHandlerInterfaceId, urls);

    final aNonDuplicatedVOs = _getNonDuplicatedVOsFromVOs(vos);

    for (final vo in aNonDuplicatedVOs)
      ALDownloaderIMP.cDownload(vo.url, headers: vo.headers);
  }

  static void _addDownloaderHandlerInterface(
      String downloaderHandlerInterfaceId, List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    final binder = _ALDownloaderBatcherBinder._(aNonDuplicatedUrls);

    for (final url in aNonDuplicatedUrls) {
      final aDownloaderHandlerInterface = ALDownloaderHandlerInterface(
          progressHandler: (progress) {},
          succeededHandler: () {
            binder._completedKVs[url] = true;

            final progress = binder._progress;

            aldDebugPrint(
                'ALDownloaderBatcher | in succeededHandler | download progress = $progress, url = $url',
                isFrequentPrint: true);

            ALDownloaderHeader.callInterfaceFromALToRoot(
                ALDownloaderConstant.kALDownloaderBatcherIMP,
                downloaderHandlerInterfaceId,
                true,
                false,
                false,
                false,
                progress);

            if (binder._isCompletedHandlerCalled) {
              if (binder._isSucceeded) {
                aldDebugPrint(
                    'ALDownloaderBatcher | in succeededHandler | download succeeded, urls = $urls');

                ALDownloaderHeader.callInterfaceFromALToRoot(
                    ALDownloaderConstant.kALDownloaderBatcherIMP,
                    downloaderHandlerInterfaceId,
                    false,
                    true,
                    false,
                    false,
                    progress,
                    isNeedRemoveInterfaceAfterCallForRoot: true);
              } else {
                aldDebugPrint(
                    'ALDownloaderBatcher | in succeededHandler | download failed, succeeded urls = ${binder._succeededUrls}, failed urls = ${binder._failedUrls}');

                ALDownloaderHeader.callInterfaceFromALToRoot(
                    ALDownloaderConstant.kALDownloaderBatcherIMP,
                    downloaderHandlerInterfaceId,
                    false,
                    false,
                    true,
                    false,
                    progress,
                    isNeedRemoveInterfaceAfterCallForRoot: true);
              }
            }
          },
          failedHandler: () {
            binder._completedKVs[url] = false;

            final progress = binder._progress;

            aldDebugPrint(
                'ALDownloaderBatcher | in failedHandler | download progress = $progress, url = $url',
                isFrequentPrint: true);

            ALDownloaderHeader.callInterfaceFromALToRoot(
                ALDownloaderConstant.kALDownloaderBatcherIMP,
                downloaderHandlerInterfaceId,
                true,
                false,
                false,
                false,
                progress);

            if (binder._isCompletedHandlerCalled) {
              aldDebugPrint(
                  'ALDownloaderBatcher | in failedHandler | download failed, succeeded urls = ${binder._succeededUrls}, failed urls = ${binder._failedUrls}');

              ALDownloaderHeader.callInterfaceFromALToRoot(
                  ALDownloaderConstant.kALDownloaderBatcherIMP,
                  downloaderHandlerInterfaceId,
                  false,
                  false,
                  true,
                  false,
                  progress,
                  isNeedRemoveInterfaceAfterCallForRoot: true);
            }
          },
          pausedHandler: () {
            if (!binder._isDownloading) {
              if (!binder._isIgnoreUnnecessaryPausedHandlerCalled) {
                aldDebugPrint(
                    'ALDownloaderBatcher | download paused, all the targetUrls are not downloading, the targetUrls = ${binder._targetUrls}, the paused urls = ${binder._pausedUrls}, the last paused url = $url');

                binder._isIgnoreUnnecessaryPausedHandlerCalled = true;

                ALDownloaderHeader.callInterfaceFromALToRoot(
                    ALDownloaderConstant.kALDownloaderBatcherIMP,
                    downloaderHandlerInterfaceId,
                    false,
                    false,
                    false,
                    true,
                    0);
              }
            } else {
              binder._isIgnoreUnnecessaryPausedHandlerCalled = false;
            }
          });

      ALDownloaderIMP.cAddDownloaderHandlerInterface(
          aDownloaderHandlerInterface, url);
    }
  }

  static void _removeDownloaderHandlerInterfaceForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    aNonDuplicatedUrls.forEach((element) =>
        ALDownloaderIMP.cRemoveDownloaderHandlerInterfaceForUrl(element));
  }

  static void _pause(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) ALDownloaderIMP.cPause(url);
  }

  static void _cancel(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) ALDownloaderIMP.cCancel(url);
  }

  static void _remove(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    for (final url in aNonDuplicatedUrls) ALDownloaderIMP.cRemove(url);
  }

  /// Remove duplicated vos
  ///
  /// If the following url is the same as the previous one, the following url will not be added.
  static List<ALDownloaderBatcherInputVO> _getNonDuplicatedVOsFromVOs(
      List<ALDownloaderBatcherInputVO> vos) {
    final aNonDuplicatedVOs = <ALDownloaderBatcherInputVO>[];
    final aNonDuplicatedUrls = <String>[];
    for (final element in vos) {
      final url = element.url;

      if (!aNonDuplicatedUrls.contains(url)) {
        aNonDuplicatedVOs.add(element);

        aNonDuplicatedUrls.add(url);
      }
    }

    return aNonDuplicatedVOs;
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

  /// A map for storaging interfaces of root isolate
  ///
  /// Key is generated by [ALDownloaderHeader.uuid].
  static final _interfaceKVs = <String, ALDownloaderHandlerInterface>{};

  /// Privatize constructor
  ALDownloaderBatcherIMP._();
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
          '_ALDownloaderBatcherBinder | get _succeededUrls, result = $aList',
          isFrequentPrint: true);
    } catch (error) {
      aList = <String>[];
      aldDebugPrint(
          '_ALDownloaderBatcherBinder | get _succeededUrls, error = $error');
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
          '_ALDownloaderBatcherBinder | get _failedUrls, result = $aList',
          isFrequentPrint: true);
    } catch (error) {
      aList = <String>[];
      aldDebugPrint(
          '_ALDownloaderBatcherBinder | get _failedUrls, error = $error');
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
      aldDebugPrint('_ALDownloaderBatcherBinder | get progress, $error');
    }

    return aDouble;
  }

  /// Whether exist downloading url
  bool get _isDownloading {
    for (final element in _targetUrls) {
      final status = ALDownloaderIMP.getStatusForUrl(element);
      if (status == ALDownloaderStatus.downloading) return true;
    }

    return false;
  }

  /// The paused urls among [_targetUrls]
  List<String> get _pausedUrls {
    final aList = <String>[];
    for (final element in _targetUrls) {
      final status = ALDownloaderIMP.getStatusForUrl(element);
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
  final _completedKVs = <String, bool>{};

  /// Urls that need to download
  final List<String> _targetUrls;

  /// Privatize constructor
  _ALDownloaderBatcherBinder._(this._targetUrls);
}
