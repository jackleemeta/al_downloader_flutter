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
  al_downloader: ^1.3.3
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
/// download
await ALDownloader.download(url,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          "ALDownloader | download progress = $progress, url = $url");
    }, succeededHandler: () {
      debugPrint("ALDownloader | download succeeded, url = $url");
    }, failedHandler: () {
      debugPrint("ALDownloader | download failed, url = $url");
    }, pausedHandler: () {
      debugPrint("ALDownloader | download paused, url = $url");
    }));
```

```
/// add a downloader handler interface
ALDownloader.addDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          "ALDownloader | download progress = $progress, url = $url");
    }, succeededHandler: () {
      debugPrint("ALDownloader | download succeeded, url = $url");
    }, failedHandler: () {
      debugPrint("ALDownloader | download failed, url = $url");
    }, pausedHandler: () {
      debugPrint("ALDownloader | download paused, url = $url");
    }),
    url);
```

```
/// add a forever downloader handler interface
ALDownloader.addForeverDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          "ALDownloader | download progress = $progress, url = $url");
    }, succeededHandler: () {
      debugPrint("ALDownloader | download succeeded, url = $url");
    }, failedHandler: () {
      debugPrint("ALDownloader | download failed, url = $url");
    }, pausedHandler: () {
      debugPrint("ALDownloader | download paused, url = $url");
    }),
    url);
```

```
/// remove downloader handler interface
ALDownloader.removeDownloaderHandlerInterfaceForUrl(url);
ALDownloader.removeDownloaderHandlerInterfaceForAll;
```

```
/// get download status for [url]
ALDownloaderStatus status = ALDownloader.getDownloadStatusForUrl(url);
```

```
/// get download progress for [url]
final progress = ALDownloader.getDownloadProgressForUrl(url);
```

```
/// cancel
///
/// for details, see interface description
await ALDownloader.cancel(url);
await ALDownloader.cancelAll;
```

```
/// pause
///
/// for details, see interface description
await ALDownloader.pause(url);
await ALDownloader.pauseAll;
```

```
/// remove
///
/// for details, see interface description
await ALDownloader.remove(url);
await ALDownloader.removeAll;
```

### ALDownloaderBatcher

```
/// batch download
await ALDownloaderBatcher.downloadUrls(urls,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint("ALDownloader | batch | download progress = $progress");
    }, succeededHandler: () {
      debugPrint("ALDownloader | batch | download succeeded");
    }, failedHandler: () {
      debugPrint("ALDownloader | batch | download failed");
    }, pausedHandler: () {
      debugPrint("ALDownloader | batch | download paused");
    }));
```

```
/// summarize the download status for a set of urls
final status = ALDownloaderBatcher.getDownloadStatusForUrls(urls);
```

### ALDownloaderPersistentFileManager - persistent file management by url

```
final model = await ALDownloaderPersistentFileManager
    .lazyGetALDownloaderPathModelForUrl(url);
debugPrint(
    "ALDownloader | get the 'physical directory path' and 'virtual/physical file name' of the file for [url], url = $url, model = $model\n");

final path2 = await ALDownloaderPersistentFileManager
    .getAbsolutePathOfDirectoryForUrl(url);
debugPrint(
    "ALDownloader | get 'directory path' for [url], url = $url, path = $path2\n");

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
    "ALDownloader | check whether [url] has a physical path, url = $url, is Exist = $isExist\n");

final fileName = ALDownloaderPersistentFileManager.getFileNameForUrl(url);
debugPrint(
    "ALDownloader | get 'virtual/physical file name' for [url], url = $url, file name = $fileName\n");
```

## Key File Of Example For iOS

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AppDelegate.swift](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/AppDelegate.swift)
- [Info.plist](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/Info.plist)

## Key File Of Example For Android

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AndroidManifest.xml](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/android/app/src/main/AndroidManifest.xml)

> Maintainer: jackleemeta (jackleemeta@outlook.com)