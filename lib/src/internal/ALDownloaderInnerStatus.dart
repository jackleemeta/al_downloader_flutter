/// An enumeration of inner status
///
/// It is used to supplement some statuses for [DownloadTaskStatus].
///
/// **discussion**
///
/// It has supplemented the fllowing statuses at present.
///
/// [prepared], [deprecated], [pretendedPaused]
///
/// It may supplement more statuses in the future.
enum ALDownloaderInnerStatus {
  prepared,
  undefined,
  enqueued,
  running,
  complete,
  failed,
  canceled,
  paused,
  pretendedPaused,
  deprecated
}

/// An enumeration extension of inner status
extension ALDownloaderInnerStatusExtension on ALDownloaderInnerStatus {
  String get alDescription => const [
        'prepared',
        'undefined',
        'enqueued',
        'running',
        'complete',
        'failed',
        'canceled',
        'paused',
        'pretendedPaused',
        'deprecated'
      ][index];
}
