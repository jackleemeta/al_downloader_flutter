/// 句柄池子类
class ALDownloaderHandlerInterface {
  ALDownloaderHandlerInterface(
      {this.progressHandler,
      this.successHandler,
      this.failureHandler,
      this.pausedHandler});
  final ALDownloaderProgressHandler progressHandler;
  final ALDownloaderSuccessHandler successHandler;
  final ALDownloaderFailureHandler failureHandler;
  final ALDownloaderPasusedHandler pausedHandler;
}

/// 下载进度
typedef ALDownloaderProgressHandler = void Function(double progress);

/// 下载成功
typedef ALDownloaderSuccessHandler = void Function();

/// 下载失败
typedef ALDownloaderFailureHandler = void Function();

/// 下载暂停
typedef ALDownloaderPasusedHandler = void Function();
