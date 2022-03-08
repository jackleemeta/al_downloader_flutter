/// ALDownloader handler interface
class ALDownloaderHandlerInterface {
  ALDownloaderHandlerInterface(
      {this.progressHandler,
      this.successHandler,
      this.failureHandler,
      this.pausedHandler});
  final ALDownloaderProgressHandler? progressHandler;
  final ALDownloaderSuccessHandler? successHandler;
  final ALDownloaderFailureHandler? failureHandler;
  final ALDownloaderPasusedHandler? pausedHandler;
}

/// download progress handle
typedef ALDownloaderProgressHandler = void Function(double progress);

/// download successfully handle
typedef ALDownloaderSuccessHandler = void Function();

/// download failed handle
typedef ALDownloaderFailureHandler = void Function();

/// download paused handle
typedef ALDownloaderPasusedHandler = void Function();
