import 'dart:async';
import 'dart:isolate';
import 'package:uuid/uuid.dart';
import '../ALDownloaderHandlerInterface.dart';
import '../ALDownloaderStatus.dart';
import 'ALDownloaderConstant.dart';
import 'ALDownloaderMessage.dart';
import 'ALDownloaderInnerTask.dart';

/// ALDownloaderHeader
abstract class ALDownloaderHeader {
  /// A port that sends message from root isolate to ALDownloader isolate
  static SendPort? portRootToAL;

  /// A port that sends message from ALDownloader isolate to root isolate
  static SendPort? portALToRoot;

  /// A completer that [portRootToAL] is got
  static final Completer completerForGotPortRootToAL = Completer();

  /// A completer that ALDownloader is initialized
  static final Completer initializedCompleter = Completer();

  /// Simple, fast generation of RFC4122 UUIDs
  ///
  /// AlDownloader creates uuid by [Uuid.v1].
  static final uuid = Uuid();

  /// Custom download tasks
  static final tasks = <ALDownloaderInnerTask>[];

  /// A reliable way that sends message from root isolate to ALDownloader isolate
  ///
  /// This ensures that messages sends and arrives in order. Specially, this could
  /// ensures that messages which sent before ALDownloader initilized arrive reliably
  /// after ALDownloader initilized.
  static void sendMessageFromRootToALReliably(ALDownloaderMessage message) {
    if (completerForGotPortRootToAL.isCompleted) {
      portRootToAL?.send(message);
    } else {
      completerForGotPortRootToAL.future.then((value) {
        portRootToAL?.send(message);
      });
    }
  }

  /// A convenient function that supports to process the downloader handler interface on coming root isolate
  static void processDownloaderHandlerInterfaceOnComingRootIsolate(
      String scope,
      String downloaderHandlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress,
      {bool isNeedRemoveInterface = false}) {
    if (!isNeedCallProgressHandler &&
        !isNeedCallSucceededHandler &&
        !isNeedCallFailedHandler &&
        !isNeedCallPausedHandler &&
        !isNeedRemoveInterface) return;

    final message = ALDownloaderMessage();
    message.scope = scope;
    message.action = ALDownloaderConstant.kCallInterface;
    message.content = {
      ALDownloaderConstant.kDownloaderHandlerInterfaceId:
          downloaderHandlerInterfaceId,
      ALDownloaderConstant.kIsNeedCallProgressHandler:
          isNeedCallProgressHandler,
      ALDownloaderConstant.kIsNeedCallSucceededHandler:
          isNeedCallSucceededHandler,
      ALDownloaderConstant.kIsNeedCallFailedHandler: isNeedCallFailedHandler,
      ALDownloaderConstant.kIsNeedCallPausedHandler: isNeedCallPausedHandler,
      ALDownloaderConstant.kProgress: progress,
      ALDownloaderConstant.kIsNeedRemoveInterface: isNeedRemoveInterface
    };

    portALToRoot?.send(message);
  }

  /// A convenient function that supports to process the status handler on coming root isolate
  static void processStatusHandlerOnComingRootIsolate(
      String scope, String statusHandlerId, ALDownloaderStatus status) {
    final message = ALDownloaderMessage();
    message.scope = scope;
    message.action = ALDownloaderConstant.kCallStatusHandler;
    message.content = {
      ALDownloaderConstant.kStatusHandlerId: statusHandlerId,
      ALDownloaderConstant.kStatus: status
    };

    portALToRoot?.send(message);
  }

  /// A convenient function that supports to process the progress handler on coming root isolate
  static void processProgressHandlerOnComingRootIsolate(
      String scope, String progressHandlerId, double progress) {
    final message = ALDownloaderMessage();
    message.scope = scope;
    message.action = ALDownloaderConstant.kCallProgressHandler;
    message.content = {
      ALDownloaderConstant.kProgressHandlerId: progressHandlerId,
      ALDownloaderConstant.kProgress: progress
    };

    portALToRoot?.send(message);
  }

  /// A convenient function that supports to process the file manager handler on coming root isolate
  static void processFileManagerHandlerOnComingRootIsolate(
      String handlerId, dynamic data) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderFileManagerIMP;
    message.action = ALDownloaderConstant.kCallFileManagerHandler;
    message.content = {
      ALDownloaderConstant.kHandlerId: handlerId,
      ALDownloaderConstant.kData: data
    };

    portALToRoot?.send(message);
  }

  /// A convenient function that supports to call the downloader handler interface
  static void callDownloaderHandlerInterface(
      ALDownloaderHandlerInterface? downloaderHandlerInterface,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress) {
    if (downloaderHandlerInterface == null) return;

    if (isNeedCallProgressHandler) {
      final f = downloaderHandlerInterface.progressHandler;
      if (f != null) f(progress);
    }

    if (isNeedCallSucceededHandler) {
      final f = downloaderHandlerInterface.succeededHandler;
      if (f != null) f();
    }

    if (isNeedCallFailedHandler) {
      final f = downloaderHandlerInterface.failedHandler;
      if (f != null) f();
    }

    if (isNeedCallPausedHandler) {
      final f = downloaderHandlerInterface.pausedHandler;
      if (f != null) f();
    }
  }
}
