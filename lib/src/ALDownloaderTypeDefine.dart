import 'ALDownloaderStatus.dart';

typedef ALDownloaderHandlerInterfaceId = String;

/// Downloader status handler
typedef ALDownloaderStatusHandler = void Function(ALDownloaderStatus status);

/// Downloader progress handler
typedef ALDownloaderProgressHandler = void Function(double progress);

/// Downloader succeeded handler
typedef ALDownloaderSucceededHandler = void Function();

/// Downloader failed handler
typedef ALDownloaderFailedHandler = void Function();

/// Downloader paused handler
typedef ALDownloaderPausedHandler = void Function();
