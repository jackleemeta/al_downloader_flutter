import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'ALDownloaderConstant.dart';
import 'ALDownloaderHeader.dart';
import 'ALDownloaderMessage.dart';
import '../implementation/ALDownloaderBatcherIMP.dart';
import '../implementation/ALDownloaderIMP.dart';

final Completer completerForPrintConfig = Completer();

void doWorkOnALIsolate(ALDownloaderMessage message) {
  final content = message.content;
  final rootIsolateToken = content[ALDownloaderConstant.kRootIsolateToken];
  ALDownloaderHeader.portALToRoot = content[ALDownloaderConstant.kPortALToRoot];

  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  final aReceivePort = ReceivePort();
  final aSendPort = aReceivePort.sendPort;

  aReceivePort.listen((message) async {
    // dispatch message on ALDownloader isolate
    if (message is ALDownloaderMessage) {
      final scope = message.scope;

      if (scope == ALDownloaderConstant.kALDownloaderIMP) {
        ALDownloaderIMP.doWorkOnALIsolate(message);
      } else if (scope == ALDownloaderConstant.kALDownloaderBatcherIMP) {
        ALDownloaderBatcherIMP.doWorkOnALIsolate(message);
      }
    }
  });

  final aMessage = ALDownloaderMessage();
  aMessage.scope = ALDownloaderConstant.kGlobalScope;
  aMessage.action = ALDownloaderConstant.kStoragePortRootToAL;
  aMessage.content = aSendPort;
  // dispatch message on root isolate
  ALDownloaderHeader.portALToRoot?.send(aMessage);
}
