import 'ALDownloaderTypeDefine.dart';

/// ALDownloader handler interface
class ALDownloaderHandlerInterface {
  ALDownloaderHandlerInterface(
      {this.progressHandler,
      this.succeededHandler,
      this.failedHandler,
      this.pausedHandler});
  final ALDownloaderProgressHandler? progressHandler;

  final ALDownloaderSucceededHandler? succeededHandler;

  final ALDownloaderFailedHandler? failedHandler;

  final ALDownloaderPausedHandler? pausedHandler;
}
