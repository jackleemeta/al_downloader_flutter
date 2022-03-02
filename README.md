# al_downloader

## Summary

开箱即用的下载器，基于[flutter_downloader](https://pub.dev/packages/flutter_downloader)

* 通过url管理下载任务，而不是taskId
* 精简下载状态
* I/O减少
* 提供便利的下载句柄
* 支持批量下载
* 自动管理文件

## Import

```
al_downloader:
  git:
    url: https://github.com/jackleemeta/al_downloader_flutter
    ref: master
    path: al_downloader
```

## Usage

### ALDownloader - 下载

```
/// 下载
ALDownloader.download(url,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint("ALDownloader | 正在下载， url = $url, progress $progress");
    }, successHandler: () {
      debugPrint("ALDownloader | 下载成功， url = $url");
    }, failureHandler: () {
      debugPrint("ALDownloader | 下载失败， url = $url");
    }, pausedHandler: () {
      debugPrint("ALDownloader | 已暂停， url = $url");
    }));
```

```
/// 注册句柄池
ALDownloader.addALDownloaderHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint("ALDownloader | 正在下载， url = $url, progress = $progress");
    }, successHandler: () {
      debugPrint("ALDownloader | 下载成功， url = $url");
    }, failureHandler: () {
      debugPrint("ALDownloader | 下载失败， url = $url");
    }, pausedHandler: () {
      debugPrint("ALDownloader | 已暂停， url = $url");
    }),
    url);
```

```
/// 反注册句柄池
ALDownloader.removeALDownloaderHandlerInterfaceForUrl(url);
ALDownloader.removeALDownloaderHandlerInterfaceForAll;
```

```
/// 获取下载状态
ALDownloaderStatus status = ALDownloader.getDownloadStatusForUrl(url);
debugPrint("ALDownloader | 获取下载状态， url = $url, status= $status\n";
```

```
/// 取消
///
/// 详细含义见接口说明
ALDownloader.cancel(url);
ALDownloader.cancelAll;
```

```
/// 暂停
///
/// 详细含义见接口说明
ALDownloader.pause(url);
ALDownloader.pauseAll;
```

```
/// 移除
///
/// 详细含义见接口说明
ALDownloader.remove(url);
ALDownloader.removeAll;
```

### ALDownloaderBatcher - 批量下载

```
/// 批量下载
ALDownloaderBatcher.downloadUrls(kTestVideos,
    downloaderHandlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
     debugPrint("ALDownloader | 正在下载, progress = $progress");
   }, successHandler: () {
     debugPrint("ALDownloader | 下载成功");
   }, failureHandler: () {
     debugPrint("ALDownloader | 下载失败");
   }, pausedHandler: () {
     debugPrint("ALDownloader | 已暂停");
   }));
```

```
/// 总结一组url的下载状态
final status = ALDownloader.getDownloadStatusForUrls(urls);
```

### ALDownloaderPersistentFileManager - 磁盘路径管理

```
/// 懒创建物理路径模型
final model = await ALDownloaderPersistentFileManager.lazyGetALDownloaderPathModelFromUrl(url);

/// 获取文件夹绝对物理路径
final path2 = await ALDownloaderPersistentFileManager.getAbsolutePathOfDirectoryWithUrl(url);

/// 获取文件虚拟路径
final path3 = await ALDownloaderPersistentFileManager.getAbsoluteVirtualPathOfFileWithUrl(url);

/// 获取文件物理路径
final path4 = await ALDownloaderPersistentFileManager.getAbsolutePhysicalPathOfFileWithUrl(url);

/// 是否存在物理路径
final isExist = await ALDownloaderPersistentFileManager.isExistAbsolutePhysicalPathOfFileForUrl(url);

/// 获取虚拟/物理文件名
final fileName = await ALDownloaderPersistentFileManager.getFileNameFromUrl(url);
```