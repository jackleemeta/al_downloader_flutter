import 'dart:isolate';
import 'package:flutter/services.dart';
import 'ALDownloaderConstant.dart';
import 'ALDownloaderHeader.dart';
import 'ALDownloaderIsolate.dart';
import 'ALDownloaderMessage.dart';
import 'ALDownloaderWorkCenter.dart';

abstract class ALDownloaderIsolateLauncher {
  static void configForIsolatesChores() {
    final aReveivePort = ReceivePort();
    final portALToRoot = aReveivePort.sendPort;

    final rootIsolateToken = RootIsolateToken.instance!;

    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kGlobalScope;
    message.content = {
      ALDownloaderConstant.kRootIsolateToken: rootIsolateToken,
      ALDownloaderConstant.kPortALToRoot: portALToRoot
    };

    Isolate.spawn(ALDownloaderIsolate.doWorkOnALIsolate, message);

    aReveivePort.listen((message) async {
      if (message is ALDownloaderMessage) {
        final scope = message.scope;
        final action = message.action;
        final content = message.content;

        if (scope == ALDownloaderConstant.kGlobalScope) {
          if (action == ALDownloaderConstant.kStoragePortRootToAL) {
            ALDownloaderHeader.portRootToAL = content;

            final aMessage1 = ALDownloaderMessage();
            aMessage1.scope = ALDownloaderConstant.kALDownloaderIMP;
            aMessage1.action = ALDownloaderConstant.kInitiallize;
            ALDownloaderHeader.sendMessageFromRootToALReliably(aMessage1);

            ALDownloaderHeader.completerForGotPortRootToAL.complete();
          }
        } else if (scope == ALDownloaderConstant.kALDownloaderIMP) {
          ALDownloaderWorkCenter.doWorkOnRootIsolateForALDownloader(message);
        } else if (scope == ALDownloaderConstant.kALDownloaderBatcherIMP) {
          ALDownloaderWorkCenter.doWorkOnRootIsolateForALDownloaderBatcher(
              message);
        }
      }
    });
  }
}
