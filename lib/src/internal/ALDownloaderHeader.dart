import 'dart:async';
import 'dart:isolate';
import 'package:uuid/uuid.dart';
import 'ALDownloaderConstant.dart';
import 'ALDownloaderMessage.dart';
import '../ALDownloaderHandlerInterface.dart';

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

  /// A reliable way that sends message from root isolate to ALDownloader isolate
  ///
  /// This ensures that messages send and arrive in order.
  /// Specially, this could ensures that some messages which are sent before ALDownloader initilized arrive reliably after ALDownloader initilized.
  static void sendMessageFromRootToALReliably(ALDownloaderMessage message) {
    if (completerForGotPortRootToAL.isCompleted) {
      portRootToAL?.send(message);
    } else {
      completerForGotPortRootToAL.future.then((value) {
        portRootToAL?.send(message);
      });
    }
  }

  /// A convenient function that supports to send the downloader handler interface from ALDownloader isolate to root isolate
  static void callInterfaceFromALToRoot(
      String scope,
      String downloaderHandlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress,
      {bool isNeedRemoveInterfaceAfterCallForRoot = false}) {
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
      ALDownloaderConstant.kIsNeedRemoveInterfaceAfterCallForRoot:
          isNeedRemoveInterfaceAfterCallForRoot
    };

    portALToRoot?.send(message);
  }

  /// A convenient function that supports to call the downloader handler interface by id
  static void callInterfaceById(
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
