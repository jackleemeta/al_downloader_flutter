import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderStatus.dart';
import 'implementation/ALDownloaderIMP.dart';

/// ALDownloader
class ALDownloader {
  /// Initialize
  ///
  /// It can be called actively or called lazily when [download] is called.
  static void initialize() => ALDownloaderIMP.initialize();

  /// Download
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  static void download(String? url,
          {ALDownloaderHandlerInterface? downloaderHandlerInterface}) =>
      ALDownloaderIMP.download(url,
          downloaderHandlerInterface: downloaderHandlerInterface);

  /// Add a downloader handler interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// [url] url
  static void addDownloaderHandlerInterface(
          ALDownloaderHandlerInterface? downloaderHandlerInterface,
          String? url) =>
      ALDownloaderIMP.addDownloaderHandlerInterface(
          downloaderHandlerInterface, url);

  /// Add a forever downloader handler interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is a forever interface which never is destroyed unless [removeDownloaderHandlerInterfaceForUrl] or [removeDownloaderHandlerInterfaceForAll] is called.
  ///
  /// [url] url
  static void addForeverDownloaderHandlerInterface(
          ALDownloaderHandlerInterface? downloaderHandlerInterface,
          String? url) =>
      ALDownloaderIMP.addForeverDownloaderHandlerInterface(
          downloaderHandlerInterface, url);

  /// Remove downloader handler interface
  ///
  /// **parameters**
  ///
  /// [url] url
  static void removeDownloaderHandlerInterfaceForUrl(String url) =>
      ALDownloaderIMP.removeDownloaderHandlerInterfaceForUrl(url);

  /// Remove all downloader handler interfaces
  static void removeDownloaderHandlerInterfaceForAll() =>
      ALDownloaderIMP.removeDownloaderHandlerInterfaceForAll();

  /// Get download status
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [ALDownloaderStatus] download status
  static ALDownloaderStatus getStatusForUrl(String url) =>
      ALDownloaderIMP.getStatusForUrl(url);

  /// Get download progress
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [double] download progress
  static double getProgressForUrl(String url) =>
      ALDownloaderIMP.getProgressForUrl(url);

  /// Pause download
  ///
  /// Stop download, but the incomplete data will not be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static void pause(String url) => ALDownloaderIMP.pause(url);

  /// Pause all downloads
  ///
  /// This is a multiple of [pause], see [pause].
  static void pauseAll() => ALDownloaderIMP.pauseAll();

  /// Cancel download
  ///
  /// Stop download, and the incomplete data will be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static void cancel(String url) => ALDownloaderIMP.cancel(url);

  /// Cancel all downloads
  ///
  /// This is a multiple of [cancel], see [cancel].
  static void cancelAll() => ALDownloaderIMP.cancelAll();

  /// Remove download
  ///
  /// Remove download, and all the data will be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static void remove(String url) => ALDownloaderIMP.remove(url);

  /// Remove all downloads
  ///
  /// This is a multiple of [remove], see [remove].
  static void removeAll() => ALDownloaderIMP.removeAll();
}
