import 'package:flutter/foundation.dart';
import '../ALDownloaderConfig.dart';

/// ALDownloader debug print
///
/// **parameters**
///
/// [message] message
///
/// [isFrequentPrint] a tag for frequent print
void aldDebugPrint(String? message, {bool isFrequentPrint = false}) {
  if (!ALDownloaderPrintConfig.enable) return;

  if (isFrequentPrint && !ALDownloaderPrintConfig.frequentEnable) return;

  final aMessage = "$message\n";

  debugPrint(aMessage);
}
