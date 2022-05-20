import 'package:flutter/material.dart';
import 'package:al_downloader/al_downloader.dart';

void main() {
  runApp(const MyApp());
}

/* ----------------------------------------------UI---------------------------------------------- */

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'al_downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'al_downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    // initialize downloader and get initial download status/progress
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "You are testing batch download",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              Expanded(child: theListview)
            ]),
        Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 3,
                ),
                Expanded(
                    child: MaterialButton(
                  padding: const EdgeInsets.all(2),
                  minWidth: 20,
                  height: 50,
                  child: const Text(
                    'download',
                    style: TextStyle(fontSize: 10),
                  ),
                  color: Colors.blue,
                  textTheme: ButtonTextTheme.primary,
                  onPressed: _downloadAction,
                )),
                const SizedBox(
                  width: 3,
                ),
                Expanded(
                    child: MaterialButton(
                  padding: const EdgeInsets.all(2),
                  minWidth: 20,
                  height: 50,
                  child: const Text(
                    'pause',
                    style: TextStyle(fontSize: 10),
                  ),
                  color: Colors.blue,
                  textTheme: ButtonTextTheme.primary,
                  onPressed: _pauseAllAction,
                )),
                const SizedBox(
                  width: 3,
                ),
                Expanded(
                    child: MaterialButton(
                  padding: const EdgeInsets.all(2),
                  minWidth: 20,
                  height: 50,
                  child: const Text(
                    'cancel',
                    style: TextStyle(fontSize: 10),
                  ),
                  color: Colors.blue,
                  textTheme: ButtonTextTheme.primary,
                  onPressed: _cancelAllAction,
                )),
                const SizedBox(
                  width: 3,
                ),
                Expanded(
                    child: MaterialButton(
                  padding: const EdgeInsets.all(2),
                  minWidth: 20,
                  height: 50,
                  child: const Text(
                    'remove',
                    style: TextStyle(fontSize: 10),
                  ),
                  color: Colors.blue,
                  textTheme: ButtonTextTheme.primary,
                  onPressed: _removeAllAction,
                )),
                const SizedBox(
                  width: 3,
                ),
              ],
            ))
      ]),
    );
  }

  /// core data in listView
  get theListview => ListView.separated(
        padding: EdgeInsets.only(
            top: 20, bottom: MediaQuery.of(context).padding.bottom + 75),
        shrinkWrap: true,
        itemCount: models.length,
        itemBuilder: (BuildContext context, int index) {
          final model = models[index];
          final order = index + 1;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "$order",
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    )),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      model.url,
                      style: const TextStyle(fontSize: 11, color: Colors.black),
                    )),
                SizedBox(
                    height: 30,
                    child: Stack(fit: StackFit.expand, children: [
                      LinearProgressIndicator(
                        value: model.progress,
                        backgroundColor: Colors.grey,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "progress = ${model.progressForPercent}",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          model.statusDescription,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white),
                        ),
                      )
                    ]))
              ]);
        },
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 10, color: Colors.transparent),
      );

  /* ----------------------------------------------method for test---------------------------------------------- */

  /// initialize
  Future<void> initialize() async {
    // some tasks may download automatically after initialization,
    // so it need to add downloader handler interface before initialization to ensure the handler call back in time.
    testForeverDownloaderHandlerInterface();

    await ALDownloader.initialize();

    for (var model in models) {
      final url = model.url;
      model.status = ALDownloader.getDownloadStatusForUrl(url);
      model.progress = ALDownloader.getDownloadProgressForUrl(url);
    }

    setState(() {});
  }

  /// action
  // ignore: unused_element
  _downloadAction() {
    test();
  }

  /// action
  // ignore: unused_element
  _pauseAction() async {
    final url = models.first.url;
    await ALDownloader.pause(url);
  }

  /// action
  // ignore: unused_element
  _pauseAllAction() async {
    await ALDownloader.pauseAll();
  }

  /// action
  // ignore: unused_element
  _cancelAction() async {
    final url = models.first.url;
    await ALDownloader.cancel(url);
  }

  /// action
  _cancelAllAction() async {
    await ALDownloader.cancelAll();
  }

  /// action
  // ignore: unused_element
  _removeAction() async {
    final url = models[3].url;
    await ALDownloader.remove(url);
  }

  /// action
  // ignore: unused_element
  _removeAllAction() async {
    await ALDownloader.removeAll();
  }

  /// when executing the following methods together, try to keep them serial
  Future<void> test() async {
    await testBatchDownload();
    // await testPath();
    // await testDownload();
    // testStatus();
  }

  /// add a forever download handle interface
  void testForeverDownloaderHandlerInterface() {
    for (final model in models) {
      final url = model.url;
      ALDownloader.addForeverDownloaderHandlerInterface(
          ALDownloaderHandlerInterface(progressHandler: (progress) {
            model.status = ALDownloaderStatus.downloading;
            model.progress = progress;

            setState(() {});

            debugPrint(
                "ALDownloader | download progress = $progress, url = $url");
          }, succeededHandler: () {
            model.status = ALDownloaderStatus.succeeded;

            setState(() {});

            debugPrint("ALDownloader | download succeeded, url = $url");
          }, failedHandler: () {
            model.status = ALDownloaderStatus.failed;

            setState(() {});

            debugPrint("ALDownloader | download failed, url = $url");
          }, pausedHandler: () {
            model.status = ALDownloaderStatus.paused;

            setState(() {});

            debugPrint("ALDownloader | download paused, url = $url");
          }),
          url);
    }
  }

  /// batch download
  Future<void> testBatchDownload() async {
    final urls = models.map((e) => e.url).toList();
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
  }

  /// download
  Future<void> testDownload() async {
    final urls = models.map((e) => e.url).toList();
    final url = urls.first;

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
  }

  /// path
  Future<void> testPath() async {
    final urls = models.map((e) => e.url).toList();
    final url = urls.first;

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
  }

  void testRemoveInterface() {
    final urls = models.map((e) => e.url).toList();
    final url = urls.first;
    ALDownloader.removeDownloaderHandlerInterfaceForUrl(url);
  }

  void testStatus() {
    final urls = models.map((e) => e.url).toList();
    final url = urls.first;

    ALDownloaderStatus status = ALDownloader.getDownloadStatusForUrl(url);
    debugPrint(
        "ALDownloader | get download status for [url], url = $url, status= $status\n");
  }
}

/* ----------------------------------------------model class for test---------------------------------------------- */

class DownloadModel {
  final String url;

  double progress = 0;

  bool get isSuccess => status == ALDownloaderStatus.succeeded;

  String get progressForPercent {
    int aProgress = (progress * 100).toInt();
    return "$aProgress%";
  }

  ALDownloaderStatus status = ALDownloaderStatus.unstarted;

  String get statusDescription {
    switch (status) {
      case ALDownloaderStatus.downloading:
        return "downloading";
      case ALDownloaderStatus.paused:
        return "paused";
      case ALDownloaderStatus.failed:
        return "failed";
      case ALDownloaderStatus.succeeded:
        return "succeeded";
      default:
        return "unstarted";
    }
  }

  DownloadModel(this.url);
}

/* ----------------------------------------------data for test---------------------------------------------- */

final models = kTestVideos.map((e) => DownloadModel(e)).toList();

final kTestPNGs = [
  "https://upload-images.jianshu.io/upload_images/9955565-51a4b4f35bd7973f.png",
  "https://upload-images.jianshu.io/upload_images/9955565-e99b6bd33b388feb.png",
  "https://upload-images.jianshu.io/upload_images/9955565-3aafbc20dd329e58.png"
];

final kTestVideos = [
  "http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4",
  "http://vfx.mtime.cn/Video/2019/03/21/mp4/190321153853126488.mp4",
  "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319222227698228.mp4",
  "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319212559089721.mp4",
  "http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4",
  "http://vfx.mtime.cn/Video/2019/03/09/mp4/190309153658147087.mp4",
  "http://vfx.mtime.cn/Video/2019/03/12/mp4/190312083533415853.mp4",
  "http://vfx.mtime.cn/Video/2019/03/12/mp4/190312143927981075.mp4",
  "http://vfx.mtime.cn/Video/2019/03/13/mp4/190313094901111138.mp4",
  "http://vfx.mtime.cn/Video/2019/03/14/mp4/190314102306987969.mp4",
  "http://vfx.mtime.cn/Video/2019/03/14/mp4/190314223540373995.mp4",
  "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319125415785691.mp4"
];

final kTestOthers = ["https://www.orimi.com/pdf-test.pdf"];
