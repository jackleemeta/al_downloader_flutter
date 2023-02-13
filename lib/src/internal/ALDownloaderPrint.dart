import 'package:flutter/foundation.dart';
import '../chore/ALDownloaderPrintConfig.dart';

/// ALDownloader debug print
///
/// **parameters**
///
/// [message] message
///
/// [isFrequentPrint] a tag for frequent print
void aldDebugPrint(String? message, {bool isFrequentPrint = false}) {
  if (!ALDownloaderPrintConfig.enabled) return;

  if (isFrequentPrint && !ALDownloaderPrintConfig.frequentEnabled) return;

  final aMessage = "$message\n";

  debugPrint(aMessage);
}
