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
  al_downloader: ^1.6.9
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

#### Initialize
```
ALDownloader.initialize();
```

#### Configure print
```
ALDownloader.configurePrint(enabled: true, frequentEnabled: false);
```

#### Download
```
ALDownloader.download(url,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          'ALDownloader | download progress = $progress, url = $url\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | download succeeded, url = $url\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | download failed, url = $url\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | download paused, url = $url\n');
    }));
```

#### Add a downloader handler interface
```
ALDownloader.addDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          'ALDownloader | download progress = $progress, url = $url\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | download succeeded, url = $url\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | download failed, url = $url\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | download paused, url = $url\n');
    }),
    url);
```

#### Add a forever downloader handler interface
```
ALDownloader.addForeverDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          'ALDownloader | download progress = $progress, url = $url\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | download succeeded, url = $url\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | download failed, url = $url\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | download paused, url = $url\n');
    }),
    url);
```

#### Remove downloader handler interface
```
ALDownloader.removeDownloaderHandlerInterfaceForUrl(url);
```

#### Get download status
```
final status = ALDownloader.getStatusForUrl(url);
```

#### Get download progress
```
final progress = ALDownloader.getProgressForUrl(url);
```

#### Pause download
```
/// Stop download, but the incomplete data will not be deleted.
ALDownloader.pause(url);
```

#### Cancel download
```
/// Stop download, and the incomplete data will be deleted.
ALDownloader.cancel(url);
```

#### Remove download
```
/// Remove download, and all the data will be deleted.
ALDownloader.remove(url);
```

### ALDownloaderBatcher

#### Batch download
```
ALDownloaderBatcher.download(urls,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint('ALDownloader | batch | download progress = $progress\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | batch | download succeeded\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | batch | download failed\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | batch | download paused\n');
    }));
```

#### Add a downloader handler interface for batch
```
ALDownloaderBatcher.addDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint('ALDownloader | batch | download progress = $progress\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | batch | download succeeded\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | batch | download failed\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | batch | download paused\n');
    }),
    urls);
```

#### Get download status for a set of urls
```
final status = ALDownloaderBatcher.getStatusForUrls(urls);
```

### ALDownloaderFileManager - A manager that manages file by url

```
final virtualFilePath =
    await ALDownloaderFileManager.getVirtualFilePathForUrl(url);
debugPrint(
    "ALDownloader | get 'virtual file path' for [url], url = $url, path = $virtualFilePath\n");

final physicalFilePath =
    await ALDownloaderFileManager.getPhysicalFilePathForUrl(url);
debugPrint(
    "ALDownloader | get 'physical file path' for [url], url = $url, path = $physicalFilePath\n");
```

## *Note*:

*1. If the persistent file was removed by exceptional means, such as the cache folder being deleted by some business code, call [remove] and then call [download] to re-download for fixing the problem.*

## Key File Of Example

### iOS

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AppDelegate.swift](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/AppDelegate.swift)
- [Info.plist](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/Info.plist)

### Android

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AndroidManifest.xml](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/android/app/src/main/AndroidManifest.xml)

> Maintainer: jackleemeta (jackleemeta@outlook.com)