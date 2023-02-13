import 'package:flutter/material.dart';
import 'package:al_downloader/al_downloader.dart';

void main() {
  runApp(const MyApp());
}

/* ----------------------------------------------UI for test---------------------------------------------- */

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

    // Initialize downloader and get initial download status/progress.
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
                children: theActionLists
                    .map((e) => Expanded(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                          child: MaterialButton(
                            padding: const EdgeInsets.all(0),
                            minWidth: 20,
                            height: 50,
                            color: Colors.blue,
                            textTheme: ButtonTextTheme.primary,
                            onPressed: e[1],
                            child: Text(
                              e[0],
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        )))
                    .toList()))
      ]),
    );
  }

  /// Core data in listView
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

  /// The action lists
  late final theActionLists = <List>[
    ["download", _downloadAllAction],
    ["pause", _pauseAllAction],
    ["cancel", _cancelAllAction],
    ["remove", _removeAllAction]
  ];

  /* ----------------------------------------------Action for test---------------------------------------------- */

  /// Action
  // ignore: unused_element
  void _downloadAction() {
    download();
  }

  /// Action
  // ignore: unused_element
  void _downloadAllAction() {
    downloadAll();
  }

  /// Action
  // ignore: unused_element
  void _pauseAction() {
    final url = models.first.url;
    ALDownloader.pause(url);
  }

  /// Action
  // ignore: unused_element
  void _pauseAllAction() {
    ALDownloader.pauseAll();
  }

  /// Action
  // ignore: unused_element
  void _cancelAction() {
    final url = models.first.url;
    ALDownloader.cancel(url);
  }

  /// Action
  // ignore: unused_element
  void _cancelAllAction() {
    ALDownloader.cancelAll();
  }

  /// Action
  // ignore: unused_element
  void _removeAction() {
    final url = models.first.url;
    ALDownloader.remove(url);
  }

  /// Action
  // ignore: unused_element
  void _removeAllAction() {
    ALDownloader.removeAll();
  }

  /* ----------------------------------------------Method for test---------------------------------------------- */

  /// Initialize
  void initialize() {
    // about print
    aboutPrint();

    // Why [downloader handler interface] and [downloader handler interface for batch] are added before ALDownloader initialization?
    //
    // Because some information may call back synchronously when initializing, [interface] being added before initialization can
    // ensure receiving the information in the [interface] first time.

    // It is for download. It is a forever interface.
    addForeverDownloaderHandlerInterface();
    // It is for batch download. It is an one-off interface.
    addBatchDownloaderHandlerInterface();

    ALDownloader.initialize();
  }

  /// About print
  void aboutPrint() {
    ALDownloaderPrintConfig.enabled = true;
    ALDownloaderPrintConfig.frequentEnabled = false;
  }

  /// Add a forever downloader handler interface
  void addForeverDownloaderHandlerInterface() {
    for (final model in models) {
      final url = model.url;
      ALDownloader.addForeverDownloaderHandlerInterface(
          ALDownloaderHandlerInterface(progressHandler: (progress) {
            debugPrint(
                "ALDownloader | download progress = $progress, url = $url\n");

            model.status = ALDownloaderStatus.downloading;
            model.progress = progress;

            setState(() {});
          }, succeededHandler: () {
            debugPrint("ALDownloader | download succeeded, url = $url\n");

            model.status = ALDownloaderStatus.succeeded;

            setState(() {});
          }, failedHandler: () {
            debugPrint("ALDownloader | download failed, url = $url\n");

            model.status = ALDownloader.getStatusForUrl(url);

            setState(() {});
          }, pausedHandler: () {
            debugPrint("ALDownloader | download paused, url = $url\n");

            model.status = ALDownloaderStatus.paused;

            setState(() {});
          }),
          url);
    }
  }

  /// Add a downloader handler interface for batch
  void addBatchDownloaderHandlerInterface() {
    final urls = models.map((e) => e.url).toList();
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
  }

  /// Download
  void download() {
    final urls = models.map((e) => e.url).toList();
    final url = urls.first;

    ALDownloader.download(url,
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
  }

  /// Download all
  void downloadAll() {
    final urls = models.map((e) => e.url).toList();
    ALDownloaderBatcher.download(urls,
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
  }

  /// Path
  Future<void> path() async {
    final urls = models.map((e) => e.url).toList();
    final url = urls.first;

    final model = await ALDownloaderFileManager.lazyGetPathModelForUrl(url);
    debugPrint(
        "ALDownloader | get 'physical directory path' and 'virtual/physical file name' of the file for [url], url = $url, model = $model\n");

    final path2 =
        await ALDownloaderFileManager.lazyGetPhysicalDirectoryPathForUrl(url);
    debugPrint(
        "ALDownloader | get 'physical directory path' for [url], url = $url, path = $path2\n");

    final path3 = await ALDownloaderFileManager.getVirtualFilePathForUrl(url);
    debugPrint(
        "ALDownloader | get 'virtual file path' for [url], url = $url, path = $path3\n");

    final path4 = await ALDownloaderFileManager.getPhysicalFilePathForUrl(url);
    debugPrint(
        "ALDownloader | get 'physical file path' for [url], url = $url, path = $path4\n");

    final isExist =
        await ALDownloaderFileManager.isExistPhysicalFilePathForUrl(url);
    debugPrint(
        "ALDownloader | check whether [url] exists a 'physical file path', url = $url, is Exist = $isExist\n");

    final fileName = ALDownloaderFileManager.getFileNameForUrl(url);
    debugPrint(
        "ALDownloader | get 'virtual/physical file name' for [url], url = $url, file name = $fileName\n");
  }

  /// Remove downloader handler interface
  void removeDownloaderHandlerInterface(String url) {
    final urls = models.map((e) => e.url).toList();
    final url = urls.first;
    ALDownloader.removeDownloaderHandlerInterfaceForUrl(url);
  }

  /// Remove all downloader handler interfaces
  void removeDownloaderHandlerInterfaceForAll() {
    ALDownloader.removeDownloaderHandlerInterfaceForAll();
  }

  /// Status
  void status() {
    final urls = models.map((e) => e.url).toList();
    final url = urls.first;

    final status = ALDownloader.getStatusForUrl(url);
    debugPrint(
        "ALDownloader | get download status for [url], url = $url, status= $status\n");
  }
}

/* ----------------------------------------------Model class for test---------------------------------------------- */

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

/* ----------------------------------------------Data for test---------------------------------------------- */

final models = kTestVideos.map((e) => DownloadModel(e)).toList();

final kTestPNGs = [
  "https://upload-images.jianshu.io/upload_images/9955565-51a4b4f35bd7973f.png",
  "https://upload-images.jianshu.io/upload_images/9955565-e99b6bd33b388feb.png",
  "https://upload-images.jianshu.io/upload_images/9955565-3aafbc20dd329e58.png"
];

final kTestVideos = [
  "http://vfx.mtime.cn/Video/2019/03/19/mp4/190319222227698228.mp4",
  "http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4",
  "http://vfx.mtime.cn/Video/2019/03/21/mp4/190321153853126488.mp4",
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
