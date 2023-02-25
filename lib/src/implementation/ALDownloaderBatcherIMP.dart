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
      _idDynamicKVs[id] = downloaderHandlerInterface;
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
      _idDynamicKVs[id] = downloaderHandlerInterface;
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
    _idDynamicKVs[id] = downloaderHandlerInterface;
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

  static void getStatusForUrls(
      List<String> urls, ALDownloaderStatusHandler handler) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kGetStatusForUrls;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    final id = ALDownloaderHeader.uuid.v1();
    _idDynamicKVs[id] = handler;
    message.content[ALDownloaderConstant.kStatusHandlerId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void getProgressForUrls(
      List<String> urls, ALDownloaderProgressHandler handler) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderBatcherIMP;
    message.action = ALDownloaderConstant.kGetProgressForUrls;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrls: urls};

    final id = ALDownloaderHeader.uuid.v1();
    _idDynamicKVs[id] = handler;
    message.content[ALDownloaderConstant.kProgressHandlerId] = id;

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

      final downloaderHandlerInterface = _idDynamicKVs[id];

      ALDownloaderHeader.callDownloaderHandlerInterface(
          downloaderHandlerInterface,
          isNeedCallProgressHandler,
          isNeedCallSucceededHandler,
          isNeedCallFailedHandler,
          isNeedCallPausedHandler,
          progress);

      if (isNeedRemoveInterface) _idDynamicKVs.remove(id);
    } else if (action == ALDownloaderConstant.kCallStatusHandler) {
      final id = content[ALDownloaderConstant.kStatusHandlerId];
      final status = content[ALDownloaderConstant.kStatus];
      final handler = _idDynamicKVs[id];

      if (handler != null) handler(status);

      _idDynamicKVs.remove(id);
    } else if (action == ALDownloaderConstant.kCallProgressHandler) {
      final id = content[ALDownloaderConstant.kProgressHandlerId];
      final progress = content[ALDownloaderConstant.kProgress];
      final handler = _idDynamicKVs[id];

      if (handler != null) handler(progress);

      _idDynamicKVs.remove(id);
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
    } else if (action == ALDownloaderConstant.kGetStatusForUrls) {
      final id = content[ALDownloaderConstant.kStatusHandlerId];
      final urls = content[ALDownloaderConstant.kUrls];
      _getStatusForUrls(id, urls);
    } else if (action == ALDownloaderConstant.kGetProgressForUrls) {
      final id = content[ALDownloaderConstant.kProgressHandlerId];
      final urls = content[ALDownloaderConstant.kUrls];
      _getProgressForUrls(id, urls);
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
        binder.urlStatusKVs[url] = ALDownloaderStatus.downloading;
      }, succeededHandler: () {
        binder.urlStatusKVs[url] = ALDownloaderStatus.succeeded;

        _processDownloaderHandlerInterface(binder, true);
      }, failedHandler: () {
        binder.urlStatusKVs[url] = ALDownloaderStatus.failed;

        _processDownloaderHandlerInterface(binder, true);
      }, pausedHandler: () {
        binder.urlStatusKVs[url] = ALDownloaderStatus.paused;

        binder.pausedCalledCounter.add(url);

        _processDownloaderHandlerInterface(binder, false);
      });

      final id = ALDownloaderIMP.cAddDownloaderHandlerInterface(
          aDownloaderHandlerInterface, url);

      binder._childDownloadHandlerInterfaceIds.add(id);
    }
  }

  static void _processDownloaderHandlerInterface(
      _ALDownloaderBatcherBinder binder, bool isNeedCallProgressHandler) {
    final downloaderHandlerInterfaceId = binder.downloadHandlerInterfaceId;

    final result = binder.extract();

    final downloadingUrlsLength = result[0];
    final succeededUrlsLength = result[1];
    final failedUrlsLength = result[2];
    final pausedUrlsLength = result[3];

    double progress = 0;
    if (isNeedCallProgressHandler)
      progress = binder.calculateProgress(succeededUrlsLength);

    final targetUrls = binder.targetUrls;
    final targetUrlsLength = targetUrls.length;

    bool isNeedCallSucceededHandler = false;
    bool isNeedCallFailedHandler = false;
    bool isNeedCallPausedHandler = false;
    bool isNeedRemoveInterface = false;
    bool isNeedClearPausedCalledCounter = false;

    if (downloadingUrlsLength +
            succeededUrlsLength +
            failedUrlsLength +
            pausedUrlsLength ==
        targetUrlsLength) {
      if (downloadingUrlsLength == 0) {
        if (pausedUrlsLength > 0) {
          if (binder.pausedCalledCounter.length == pausedUrlsLength) {
            aldDebugPrint(
                'ALDownloaderBatcher | download paused, target urls = $targetUrls');

            isNeedCallSucceededHandler = false;
            isNeedCallFailedHandler = false;
            isNeedCallPausedHandler = true;
            isNeedRemoveInterface = false;
            isNeedClearPausedCalledCounter = true;
          }
        } else if (succeededUrlsLength == targetUrlsLength) {
          aldDebugPrint(
              'ALDownloaderBatcher | download succeeded, target urls = $targetUrls');

          isNeedCallSucceededHandler = true;
          isNeedCallFailedHandler = false;
          isNeedCallPausedHandler = false;
          isNeedRemoveInterface = true;
          isNeedClearPausedCalledCounter = false;
        } else if (succeededUrlsLength + failedUrlsLength == targetUrlsLength) {
          aldDebugPrint(
              'ALDownloaderBatcher | download failed, target urls = $targetUrls');

          isNeedCallSucceededHandler = false;
          isNeedCallFailedHandler = true;
          isNeedCallPausedHandler = false;
          isNeedRemoveInterface = true;
          isNeedClearPausedCalledCounter = false;
        }
      }
    }

    ALDownloaderHeader.processDownloaderHandlerInterfaceOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderBatcherIMP,
        downloaderHandlerInterfaceId,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress,
        isNeedRemoveInterface: isNeedRemoveInterface);

    if (isNeedClearPausedCalledCounter) binder.pausedCalledCounter.clear();

    if (isNeedRemoveInterface)
      _idBinderKVs.remove(downloaderHandlerInterfaceId);
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
        binder.downloadHandlerInterfaceId,
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

  static void _getStatusForUrls(String statusHandlerId, List<String> urls) {
    final status = _fGetStatusForUrls(urls);

    ALDownloaderHeader.processStatusHandlerOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderBatcherIMP, statusHandlerId, status);
  }

  static void _getProgressForUrls(String progressHandlerId, List<String> urls) {
    final progress = _fGetProgressForUrls(urls);

    ALDownloaderHeader.processProgressHandlerOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderBatcherIMP,
        progressHandlerId,
        progress);
  }

  static ALDownloaderStatus _fGetStatusForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);

    final aMap = <String, ALDownloaderStatus>{};

    for (final url in aNonDuplicatedUrls) {
      final aStatus = ALDownloaderIMP.cGetStatusForUrl(url);
      if (aStatus == ALDownloaderStatus.unstarted)
        return ALDownloaderStatus.unstarted;

      aMap[url] = aStatus;
    }

    final allStatus = aMap.values.toSet();

    if (allStatus.contains(ALDownloaderStatus.paused)) {
      return ALDownloaderStatus.paused;
    } else if (allStatus.contains(ALDownloaderStatus.failed)) {
      return ALDownloaderStatus.failed;
    }

    return ALDownloaderStatus.succeeded;
  }

  static double _fGetProgressForUrls(List<String> urls) {
    final aNonDuplicatedUrls = _getNonDuplicatedUrlsFromUrls(urls);
    int succeededCount = 0;
    for (final url in aNonDuplicatedUrls) {
      final aStatus = ALDownloaderIMP.cGetStatusForUrl(url);
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

  /// A map that key is id and value may be the fllowing type.
  ///
  /// [ALDownloaderHandlerInterface], [ALDownloaderStatusHandler], [ALDownloaderProgressHandler]
  ///
  /// Key is generated by [ALDownloaderHeader.uuid].
  static final _idDynamicKVs = <String, dynamic>{};

  /// A map that key is url and value is [_ALDownloaderBatcherBinder].
  static final _idBinderKVs = <String, _ALDownloaderBatcherBinder>{};

  /// Privatize constructor
  ALDownloaderBatcherIMP._();
}

/// A batch binder for binding some elements such as [targetUrls], [downloadHandlerInterfaceId], [_childDownloadHandlerInterfaceIds] and more
///
/// It may bind more elements in the future.
class _ALDownloaderBatcherBinder {
  /// Extract urls length as a set by [ALDownloaderStatus]
  List<int> extract() {
    int downloadingUrlsLength = 0;
    int succeededUrlsLength = 0;
    int failedUrlsLength = 0;
    int pausedUrlsLength = 0;

    for (final element in urlStatusKVs.entries) {
      switch (element.value) {
        case ALDownloaderStatus.downloading:
          downloadingUrlsLength++;
          break;
        case ALDownloaderStatus.succeeded:
          succeededUrlsLength++;
          break;
        case ALDownloaderStatus.failed:
          failedUrlsLength++;
          break;
        case ALDownloaderStatus.paused:
          pausedUrlsLength++;
          break;
        default:
          break;
      }
    }

    return [
      downloadingUrlsLength,
      succeededUrlsLength,
      failedUrlsLength,
      pausedUrlsLength
    ];
  }

  /// Get progress
  ///
  /// progress = number of succeeded urls / number of all urls
  double calculateProgress(int succeededCount) {
    double aDouble = 0;

    try {
      if (targetUrls.length == 0) {
        aDouble = 0;
      } else {
        dynamic result = succeededCount / targetUrls.length;
        result = result.toStringAsFixed(2);
        aDouble = double.tryParse(result) ?? 0;
      }
    } catch (error) {
      aDouble = 0;
      aldDebugPrint('_ALDownloaderBatcherBinder | get progress, $error');
    }

    return aDouble;
  }

  /// The purpose is to return a reasonable paused status.
  final pausedCalledCounter = Set<String>();

  /// A map that key is url and value [ALDownloaderStatus]
  final urlStatusKVs = <String, ALDownloaderStatus>{};

  /// Batch download handler interface id
  final ALDownloaderHandlerInterfaceId downloadHandlerInterfaceId;

  /// A list that contains child download handler interface ids
  final _childDownloadHandlerInterfaceIds = <String>[];

  /// A list that contains urls needed to download
  final List<String> targetUrls;

  /// Privatize constructor
  _ALDownloaderBatcherBinder._(
      this.downloadHandlerInterfaceId, this.targetUrls);
}
