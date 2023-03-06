/// ALDownloader batcher input value object
class ALDownloaderBatcherInputVO {
  final String url;

  String? directoryPath;

  String? fileName;

  Map<String, String>? headers;

  /// See [redownloadIfNeeded] in [ALDownloader.download]
  bool redownloadIfNeeded = false;

  ALDownloaderBatcherInputVO(this.url);
}
