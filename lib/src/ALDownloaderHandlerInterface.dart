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
  final ALDownloaderPasusedHandler? pausedHandler;
}

/// downloader progress handler
typedef ALDownloaderProgressHandler = void Function(double progress);

/// downloader succeeded handler
typedef ALDownloaderSucceededHandler = void Function();

/// downloader failed handler
typedef ALDownloaderFailedHandler = void Function();

/// downloader paused handler
typedef ALDownloaderPasusedHandler = void Function();
