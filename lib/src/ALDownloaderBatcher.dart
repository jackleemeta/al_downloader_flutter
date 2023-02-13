import 'ALDownloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderStatus.dart';
import 'chore/ALDownloaderBatcherInputVO.dart';
import 'implementation/ALDownloaderBatcherIMP.dart';

/// ALDownloaderBatcher
///
/// batch download
///
/// progress = number of succeeded urls / number of all urls
class ALDownloaderBatcher {
  /// Download
  ///
  /// [urls] urls
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  static void download(List<String> urls,
          {ALDownloaderHandlerInterface? downloaderHandlerInterface}) =>
      ALDownloaderBatcherIMP.download(urls,
          downloaderHandlerInterface: downloaderHandlerInterface);

  /// Download
  ///
  /// [vos] the input value object
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  static void downloadUrlsWithVOs(List<ALDownloaderBatcherInputVO> vos,
          {ALDownloaderHandlerInterface? downloaderHandlerInterface}) =>
      ALDownloaderBatcherIMP.downloadUrlsWithVOs(vos,
          downloaderHandlerInterface: downloaderHandlerInterface);

  /// Get download status
  ///
  /// Summarize the download status for a set of urls.
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// **return**
  ///
  /// [ALDownloaderStatus] download status
  static ALDownloaderStatus getStatusForUrls(List<String> urls) =>
      ALDownloaderBatcherIMP.getStatusForUrls(urls);

  /// Get download progress
  ///
  /// number of succeeded urls / number of all urls
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// **return**
  ///
  /// [double] download progress
  static double getProgressForUrls(List<String> urls) =>
      ALDownloaderBatcherIMP.getProgressForUrls(urls);

  /// Add a downloader handler interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// [urls] urls
  static void addDownloaderHandlerInterface(
          ALDownloaderHandlerInterface? downloaderHandlerInterface,
          List<String> urls) =>
      ALDownloaderBatcherIMP.addDownloaderHandlerInterface(
          downloaderHandlerInterface, urls);

  /// Remove downloader handler interfaces
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void removeDownloaderHandlerInterfaceForUrls(List<String> urls) =>
      ALDownloaderBatcherIMP.removeDownloaderHandlerInterfaceForUrls(urls);

  /// Pause downloads
  ///
  /// This is a multiple of [ALDownloader.pause], see [ALDownloader.pause].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void pause(List<String> urls) => ALDownloaderBatcherIMP.pause(urls);

  /// Cancel downloads
  ///
  /// This is a multiple of [ALDownloader.cancel], see [ALDownloader.cancel].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void cancel(List<String> urls) => ALDownloaderBatcherIMP.cancel(urls);

  /// Remove downloads
  ///
  /// This is a multiple of [ALDownloader.remove], see [ALDownloader.remove].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void remove(List<String> urls) => ALDownloaderBatcherIMP.remove(urls);
}
