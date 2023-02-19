import 'dart:isolate';
import 'package:flutter/services.dart';
import 'ALDownloaderConstant.dart';
import 'ALDownloaderHeader.dart';
import 'ALDownloaderIsolate.dart';
import 'ALDownloaderMessage.dart';
import '../implementation/ALDownloaderBatcherIMP.dart';
import '../implementation/ALDownloaderIMP.dart';

void configForIsolatesChores() {
  final aReveivePort = ReceivePort();
  final portALToRoot = aReveivePort.sendPort;

  final rootIsolateToken = RootIsolateToken.instance!;

  final message = ALDownloaderMessage();
  message.scope = ALDownloaderConstant.kGlobalScope;
  message.content = {
    ALDownloaderConstant.kRootIsolateToken: rootIsolateToken,
    ALDownloaderConstant.kPortALToRoot: portALToRoot
  };

  Isolate.spawn(doWorkOnALIsolate, message);

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
        ALDownloaderIMP.doWorkOnRootIsolate(message);
      } else if (scope == ALDownloaderConstant.kALDownloaderBatcherIMP) {
        ALDownloaderBatcherIMP.doWorkOnRootIsolate(message);
      }
    }
  });
}
