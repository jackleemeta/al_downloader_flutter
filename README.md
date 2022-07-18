# al_downloader

[![pub package](https://img.shields.io/pub/v/al_downloader.svg)](https://pub.dartlang.org/packages/al_downloader)

A URL-based flutter downloader that supports to download any type of file and automatically manages a lot of things.

If you need Chinese Document, click [here](README_CN.md).

## Features

* manage download tasks by url
* simple download status
* I/O infrequently
* provide convenient download handle
* support batch download
* manage automatically files without requiring to be specified a download path
* based on [flutter_downloader](https://pub.dev/packages/flutter_downloader)

## Integration

> Native Config: same as [flutter_downloader](https://pub.dev/packages/flutter_downloader) native config

add the following line to your pubspec.yaml

```
dependencies:
  al_downloader: ^1.5.7
```

run the following line with your command line
```
flutter packages get
```

import the following line, then you can use al_downloader
```
import 'package:al_downloader/al_downloader.dart';
```

## Usage

### ALDownloader

```
/// Download
await ALDownloader.download(url,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          "ALDownloader | download progress = $progress, url = $url\n");
    }, succeededHandler: () {
      debugPrint("ALDownloader | download succeeded, url = $url\n");
    }, failedHandler: () {
      debugPrint("ALDownloader | download failed, url = $url\n");
    }, pausedHandler: () {
      debugPrint("ALDownloader | download paused, url = $url\n");
    }));
```

```
/// Add a downloader handler interface
ALDownloader.addDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          "ALDownloader | download progress = $progress, url = $url\n");
    }, succeededHandler: () {
      debugPrint("ALDownloader | download succeeded, url = $url\n");
    }, failedHandler: () {
      debugPrint("ALDownloader | download failed, url = $url\n");
    }, pausedHandler: () {
      debugPrint("ALDownloader | download paused, url = $url\n");
    }),
    url);
```

```
/// Add a forever downloader handler interface
ALDownloader.addForeverDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          "ALDownloader | download progress = $progress, url = $url\n");
    }, succeededHandler: () {
      debugPrint("ALDownloader | download succeeded, url = $url\n");
    }, failedHandler: () {
      debugPrint("ALDownloader | download failed, url = $url\n");
    }, pausedHandler: () {
      debugPrint("ALDownloader | download paused, url = $url\n");
    }),
    url);
```

```
/// Remove downloader handler interface
ALDownloader.removeDownloaderHandlerInterfaceForUrl(url);
```

```
/// Get download status
final status = ALDownloader.getDownloadStatusForUrl(url);
```

```
/// Get download progress
final progress = ALDownloader.getDownloadProgressForUrl(url);
```

```
/// Pause download
///
/// Stop download, but the incomplete data will not be deleted.
await ALDownloader.pause(url);
```

```
/// Cancel download
///
/// Stop download, and the incomplete data will be deleted.
await ALDownloader.cancel(url);
```

```
/// Remove download
///
/// Remove download, and all the data will be deleted.
await ALDownloader.remove(url);
```

### ALDownloaderBatcher

```
/// Batch download
await ALDownloaderBatcher.downloadUrls(urls,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint("ALDownloader | batch | download progress = $progress\n");
    }, succeededHandler: () {
      debugPrint("ALDownloader | batch | download succeeded\n");
    }, failedHandler: () {
      debugPrint("ALDownloader | batch | download failed\n");
    }, pausedHandler: () {
      debugPrint("ALDownloader | batch | download paused\n");
    }));
```

```
/// Add a downloader handler interface for batch
ALDownloaderBatcher.addDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint("ALDownloader | batch | download progress = $progress\n");
    }, succeededHandler: () {
      debugPrint("ALDownloader | batch | download succeeded\n");
    }, failedHandler: () {
      debugPrint("ALDownloader | batch | download failed\n");
    }, pausedHandler: () {
      debugPrint("ALDownloader | batch | download paused\n");
    }),
    urls);
```

```
/// Get download status for a set of urls
final status = ALDownloaderBatcher.getDownloadStatusForUrls(urls);
```

### ALDownloaderPersistentFileManager - A manager that manages persistent file by url

```
final model = await ALDownloaderPersistentFileManager
    .lazyGetALDownloaderPathModelForUrl(url);
debugPrint(
    "ALDownloader | get 'physical directory path' and 'virtual/physical file name' of the file for [url], url = $url, model = $model\n");

final path2 = await ALDownloaderPersistentFileManager
    .lazyGetAbsolutePathOfDirectoryForUrl(url);
debugPrint(
    "ALDownloader | get 'physical directory path' for [url], url = $url, path = $path2\n");

final path3 = await ALDownloaderPersistentFileManager
    .getAbsoluteVirtualPathOfFileForUrl(url);
debugPrint(
    "ALDownloader | get 'virtual file path' for [url], url = $url, path = $path3\n");

final path4 = await ALDownloaderPersistentFileManager
    .getAbsolutePhysicalPathOfFileForUrl(url);
debugPrint(
    "ALDownloader | get 'physical file path' for [url], url = $url, path = $path4\n");

final isExist = await ALDownloaderPersistentFileManager
    .isExistAbsolutePhysicalPathOfFileForUrl(url);
debugPrint(
    "ALDownloader | check whether [url] exists a 'physical file path', url = $url, is Exist = $isExist\n");

final fileName = ALDownloaderPersistentFileManager.getFileNameForUrl(url);
debugPrint(
    "ALDownloader | get 'virtual/physical file name' for [url], url = $url, file name = $fileName\n");
```

### ALDownloaderPrintConfig

```
/// Enable print
ALDownloaderPrintConfig.enabled = true;

/// Disable frequent print
ALDownloaderPrintConfig.frequentEnabled = false;
```

## *Note*:

*1. Method needs to add qualifier `await` when executing in a coroutine.*

*For example that*
```
Future<void> executeSomeMethodsTogetherSerially() async {
  await ALDownloader.initialize();
  await ALDownloader.remove(url);
  await ALDownloader.download(url);
}
```

*2. If the persistent file was removed by exceptional means, such as the cache folder being deleted by some business code, call [remove] and then call [download] to re-download for fixing the problem.*

## Key File Of Example

### iOS

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AppDelegate.swift](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/AppDelegate.swift)
- [Info.plist](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/Info.plist)

### Android

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AndroidManifest.xml](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/android/app/src/main/AndroidManifest.xml)

> Maintainer: jackleemeta (jackleemeta@outlook.com)