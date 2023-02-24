import 'ALDownloaderIMP.dart';
import '../ALDownloaderHandlerInterface.dart';
import '../ALDownloaderStatus.dart';
import '../ALDownloaderTypeDefine.dart';
import '../chore/ALDownloaderBatcherInputVO.dart';
import '../internal/ALDownloaderConstant.dart';
import '../internal/ALDownloaderHeader.dart';
import '../internal/ALDownloaderMessage.dart';
import '../internal/ALDownloaderPrint.dart';

abstract class ALDownloaderBatcherIMP {
  static ALDownloaderHandlerInterfaceId? download(List<String> urls,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kDownload;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    ALDownloaderHandlerInterfaceId? id;
    if (downloaderHandlerInterface != null) {
      id = ALDownloaderHeader.uuid.v1();
      _idInterfaceKVs[id] = downloaderHandlerInterface;
      message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;
    }

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static ALDownloaderHandlerInterfaceId? downloadUrlsWithVOs(
      List<ALDownloaderBatcherInputVO> vos,
      {ALDownloaderHandlerInterface? downloaderHandlerInterface}) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kDownloadUrlsWithVOs;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kALDownloaderBatcherInputVOs: vos
    };

    ALDownloaderHandlerInterfaceId? id;
    if (downloaderHandlerInterface != null) {
      id = ALDownloaderHeader.uuid.v1();
      _idInterfaceKVs[id] = downloaderHandlerInterface;
      message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;
    }

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static ALDownloaderHandlerInterfaceId addDownloaderHandlerInterface(
      ALDownloaderHandlerInterface downloaderHandlerInterface,
      List<String> urls) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kAddDownloaderHandlerInterface;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    final id = ALDownloaderHeader.uuid.v1();
    _idInterfaceKVs[id] = downloaderHandlerInterface;
    message.content[ALDownloaderConstant.kDownloaderHandlerInterfaceId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static void removeDownloaderHandlerInterfaceForId(
      ALDownloaderHandlerInterfaceId id) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action =
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForId;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kDownloaderHandlerInterfaceId: id
    };

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeDownloaderHandlerInterfaceForAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action =
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForAll;

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
      final isNeedRemoveInterface =
          content[ALDownloaderConstant.kIsNeedRemoveInterface];

      final downloaderHandlerInterface = _idInterfaceKVs[id];

      ALDownloaderHeader.callDownloaderHandlerInterface(
          downloaderHandlerInterface,
          isNeedCallProgressHandler,
          isNeedCallSucceededHandler,
          isNeedCallFailedHandler,
          isNeedCallPausedHandler,
          progress);

      if (isNeedRemoveInterface) _idInterfaceKVs.remove(id);
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
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForId) {
      final id = content[ALDownloaderConstant.kDownloaderHandlerInterfaceId];
      _removeDownloaderHandlerInterfaceForId(id);
    } else if (action ==
        ALDownloaderConstant.kRemoveDownloaderHandlerInterfaceForAll) {
      _removeDownloaderHandlerInterfaceForAll();
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

    for (final element in aNonDuplicatedUrls)
      ALDownloaderIMP.cDownload(element);
  }

  static void _downloadUrlsWithVOs(List<ALDownloaderBatcherInputVO> vos,
      {String? downloaderHandlerInterfaceId}) {
    final urls = vos.map((e) => e.url).toList();
    if (downloaderHandlerInterfaceId != null)
      _addDownloaderHandlerInterface(downloaderHandlerInterfaceId, urls);

    final aNonDuplicatedVOs = _getNonDuplicatedVOsFromVOs(vos);

    for (final element in aNonDuplicatedVOs)
      ALDownloaderIMP.cDownload(element.url, headers: element.headers);
  }

  static void _addDownloaderHandlerInterface(
      ALDownloaderHandlerInterfaceId downloaderHandlerInterfaceId,
      List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    final binder = _ALDownloaderBatcherBinder._(
        downloaderHandlerInterfaceId, aNonDuplicatedUrls);
    _idBinderKVs[downloaderHandlerInterfaceId] = binder;

    for (final url in aNonDuplicatedUrls) {
      final aDownloaderHandlerInterface =
          ALDownloaderHandlerInterface(progressHandler: (progress) {
        binder._downloadingKVs[url] = true;
      }, succeededHandler: () {
        binder._completedKVs[url] = true;

        binder._downloadingKVs[url] = false;

        final progress = binder._progress;

        aldDebugPrint(
            'ALDownloaderBatcher | in succeededHandler | download progress = $progress, url = $url',
            isFrequentPrint: true);

        ALDownloaderHeader.processDownloaderHandlerInterfaceOnComingRootIsolate(
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
                'ALDownloaderBatcher | in succeededHandler | download succeeded, urls = ${binder._targetUrls}');

            ALDownloaderHeader
                .processDownloaderHandlerInterfaceOnComingRootIsolate(
                    ALDownloaderConstant.kALDownloaderBatcherIMP,
                    downloaderHandlerInterfaceId,
                    false,
                    true,
                    false,
                    false,
                    progress,
                    isNeedRemoveInterface: true);

            _idBinderKVs.remove(downloaderHandlerInterfaceId);
          } else {
            aldDebugPrint(
                'ALDownloaderBatcher | in succeededHandler | download failed, succeeded urls = ${binder._succeededUrls}, failed urls = ${binder._failedUrls}');

            ALDownloaderHeader
                .processDownloaderHandlerInterfaceOnComingRootIsolate(
                    ALDownloaderConstant.kALDownloaderBatcherIMP,
                    downloaderHandlerInterfaceId,
                    false,
                    false,
                    true,
                    false,
                    progress,
                    isNeedRemoveInterface: true);

            _idBinderKVs.remove(downloaderHandlerInterfaceId);
          }
        }
      }, failedHandler: () {
        binder._completedKVs[url] = false;

        binder._downloadingKVs[url] = false;

        final progress = binder._progress;

        aldDebugPrint(
            'ALDownloaderBatcher | in failedHandler | download progress = $progress, url = $url',
            isFrequentPrint: true);

        ALDownloaderHeader.processDownloaderHandlerInterfaceOnComingRootIsolate(
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

          ALDownloaderHeader
              .processDownloaderHandlerInterfaceOnComingRootIsolate(
                  ALDownloaderConstant.kALDownloaderBatcherIMP,
                  downloaderHandlerInterfaceId,
                  false,
                  false,
                  true,
                  false,
                  progress,
                  isNeedRemoveInterface: true);

          _idBinderKVs.remove(downloaderHandlerInterfaceId);
        }
      }, pausedHandler: () {
        binder._downloadingKVs[url] = false;

        if (!binder._isDownloading) {
          if (!binder._isIgnoreUnnecessaryPausedHandlerCalled) {
            aldDebugPrint(
                'ALDownloaderBatcher | download paused, all the targetUrls are not downloading, the targetUrls = ${binder._targetUrls}, the last paused url = $url');

            binder._isIgnoreUnnecessaryPausedHandlerCalled = true;

            ALDownloaderHeader
                .processDownloaderHandlerInterfaceOnComingRootIsolate(
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

      final id = ALDownloaderIMP.cAddDownloaderHandlerInterface(
          aDownloaderHandlerInterface, url);

      binder._childDownloadHandlerInterfaceIds.add(id);
    }
  }

  static void _removeDownloaderHandlerInterfaceForId(
      ALDownloaderHandlerInterfaceId id) {
    final binder = _idBinderKVs[id];
    if (binder == null) return;

    _removeDownloaderHandlerInterfaceBinder(id, binder);
  }

  static void _removeDownloaderHandlerInterfaceForAll() {
    final aMap = <String, _ALDownloaderBatcherBinder>{};
    aMap.addAll(_idBinderKVs);

    for (final element in aMap.entries)
      _removeDownloaderHandlerInterfaceBinder(element.key, element.value);
  }

  static void _removeDownloaderHandlerInterfaceBinder(
      String key, _ALDownloaderBatcherBinder binder) {
    for (final element in binder._childDownloadHandlerInterfaceIds)
      ALDownloaderIMP.cRemoveDownloaderHandlerInterfaceForId(element);

    ALDownloaderHeader.processDownloaderHandlerInterfaceOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderBatcherIMP,
        binder._downloadHandlerInterfaceId,
        false,
        false,
        false,
        false,
        0,
        isNeedRemoveInterface: true);

    _idBinderKVs.remove(key);
  }

  static void _pause(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    ALDownloaderIMP.cPauseUrls(aNonDuplicatedUrls);
  }

  static void _cancel(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    ALDownloaderIMP.cCancelUrls(aNonDuplicatedUrls);
  }

  static void _remove(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    ALDownloaderIMP.cRemoveUrls(aNonDuplicatedUrls);
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

  /// A map that key is id and value is [ALDownloaderHandlerInterface]
  ///
  /// Key is generated by [ALDownloaderHeader.uuid].
  static final _idInterfaceKVs = <String, ALDownloaderHandlerInterface>{};

  /// A map that key is url and value is [_ALDownloaderBatcherBinder].
  static final _idBinderKVs = <String, _ALDownloaderBatcherBinder>{};

  /// Privatize constructor
  ALDownloaderBatcherIMP._();
}

/// A batch binder for binding some elements such as [_targetUrls], [_downloadHandlerInterfaceId], [_childDownloadHandlerInterfaceIds] and more
///
/// It may bind more elements in the future.
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
  bool get _isDownloading => _downloadingKVs.values.contains(true);

  /// The paused urls among [_targetUrls]
  // ignore: unused_element
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

  /// Purpose is that check whether all the completed handler called
  bool get _isCompletedHandlerCalled =>
      _completedKVs.length == _targetUrls.length;

  /// A map that key is url and value is whether url is completed
  final _completedKVs = <String, bool>{};

  /// A map that key is url and value is whether url is downloading
  final _downloadingKVs = <String, bool>{};

  /// Batch download handler interface id
  final ALDownloaderHandlerInterfaceId _downloadHandlerInterfaceId;

  /// A list that contains child download handler interface ids
  final _childDownloadHandlerInterfaceIds = <String>[];

  /// A list that contains urls needed to download
  final List<String> _targetUrls;

  /// Privatize constructor
  _ALDownloaderBatcherBinder._(
      this._downloadHandlerInterfaceId, this._targetUrls);
}
