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

/// Downloader progress handler
typedef ALDownloaderProgressHandler = void Function(double progress);

/// Downloader succeeded handler
typedef ALDownloaderSucceededHandler = void Function();

/// Downloader failed handler
typedef ALDownloaderFailedHandler = void Function();

/// Downloader paused handler
typedef ALDownloaderPasusedHandler = void Function();
