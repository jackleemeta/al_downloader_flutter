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
  al_downloader: ^1.1.4
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
          "ALDownloader | downloading, the url = $url, progress = $progress");
    }, successHandler: () {
      debugPrint("ALDownloader | download successfully, the url = $url");
    }, failureHandler: () {
      debugPrint("ALDownloader | download failed, the url = $url");
    }, pausedHandler: () {
      debugPrint("ALDownloader | download paused, the url = $url");
    }));
```

```
/// add a download handle interface
ALDownloader.addALDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
              "ALDownloader | downloading, the url = $url, progress = $progress");
    }, successHandler: () {
      debugPrint("ALDownloader | download successfully, the url = $url");
    }, failureHandler: () {
      debugPrint("ALDownloader | download failed, the url = $url");
    }, pausedHandler: () {
      debugPrint("ALDownloader | download paused, the url = $url");
    }),
    url);
```

```
/// remove a download handle interface
ALDownloader.removeALDownloaderHandlerInterfaceForUrl(url);
ALDownloader.removeALDownloaderHandlerInterfaceForAll;
```

```
/// get the download status of [url]
ALDownloaderStatus status = ALDownloader.getDownloadStatusForUrl(url);
```

```
/// cancel
///
/// for details, see interface description
ALDownloader.cancel(url);
ALDownloader.cancelAll;
```

```
/// pause
///
/// for details, see interface description
ALDownloader.pause(url);
ALDownloader.pauseAll;
```

```
/// remove
///
/// for details, see interface description
ALDownloader.remove(url);
ALDownloader.removeAll;
```

### ALDownloaderBatcher

```
/// batch downlaod
await ALDownloaderBatcher.downloadUrls(kTestVideos,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint("ALDownloader | batch | downloading, progress = $progress");
    }, successHandler: () {
      debugPrint("ALDownloader | batch | download successfully");
    }, failureHandler: () {
      debugPrint("ALDownloader | batch | download failed");
    }, pausedHandler: () {
      debugPrint("ALDownloader | batch | download paused");
    }));
```

```
/// summarize the download status of a set of urls
final status = ALDownloader.getDownloadStatusForUrls(urls);
```

### ALDownloaderPersistentFileManager - disk path management by url

```
final model = await ALDownloaderPersistentFileManager
    .lazyGetALDownloaderPathModelFromUrl(url);
debugPrint(
    "ALDownloader | get the 'physical directory path' and 'vitual/physical file name' of the file by [url], url = $url, path model = $model\n");

final path2 = await ALDownloaderPersistentFileManager
    .getAbsolutePathOfDirectoryWithUrl(url);
debugPrint(
    "ALDownloader | get 'directory path' by [url], url = $url, path = $path2\n");

final path3 = await ALDownloaderPersistentFileManager
    .getAbsoluteVirtualPathOfFileWithUrl(url);
debugPrint(
    "ALDownloader | get 'virtual file path' by [url], url = $url, path = $path3\n");

final path4 = await ALDownloaderPersistentFileManager
    .getAbsolutePhysicalPathOfFileWithUrl(url);
debugPrint(
    "ALDownloader | get 'physical file path' by [url], url = $url, path = $path4\n");

final isExist = await ALDownloaderPersistentFileManager
    .isExistAbsolutePhysicalPathOfFileForUrl(url);
debugPrint(
    "ALDownloader | check whether [url] corresponds to physical path, url = $url, is Exist = $isExist\n");

final fileName = ALDownloaderPersistentFileManager.getFileNameFromUrl(url);
debugPrint(
    "ALDownloader | get virtual/physical 'file name' by [url], url = $url, file name = $fileName\n");
```

## Key File Of Example For iOS

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AppDelegate.swift](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/AppDelegate.swift)
- [Info.plist](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/Info.plist)

## Key File Of Example For Android

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AndroidManifest.xml](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/android/app/src/main/AndroidManifest.xml)

> Maintainer: jackleemeta (jackleemeta@outlook.com)