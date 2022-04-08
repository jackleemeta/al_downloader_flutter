import 'package:flutter/material.dart';
import 'package:al_downloader/al_downloader.dart';

void main() {
  runApp(const MyApp());
}

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
        body: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 10),
          const Text(
            "You are testing batch download",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Expanded(child: theListview)
        ]),
        floatingActionButton: MaterialButton(
          child: const Text('download'),
          color: Colors.blue,
          textTheme: ButtonTextTheme.primary,
          onPressed: _downloadAction,
        ));
  }

  /// core data in listView
  get theListview => ListView.separated(
        padding: EdgeInsets.only(
            top: 30, bottom: MediaQuery.of(context).padding.bottom + 10),
        shrinkWrap: true,
        itemCount: models.length,
        itemBuilder: (BuildContext context, int index) {
          final model = models[index];
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "url = ${model.url!}",
                      style: const TextStyle(fontSize: 11, color: Colors.black),
                    )),
                SizedBox(
                    height: 50,
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
                    ]))
              ]);
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(
          height: 20.0,
        ),
      );

  void initialize() {
    ALDownloader.initialize().then((value) {
      for (final model in models) {
        final status = ALDownloader.getDownloadStatusForUrl(model.url!);
        final progress = ALDownloader.getDownloadProgressForUrl(model.url!);
        model.isSuccess = status == ALDownloaderStatus.downloadSuccced;
        model.progress = progress;
      }

      setState(() {});
    });
  }

  void _downloadAction() {
    test();
  }

  /// when executing the following methods together, try to keep them serial
  test() async {
    await testAddInterface();
    await testBatchDownload();
    // await testPath();
    // await testDownload();
    // await testStatus();
  }

  /// add download handle interface
  testAddInterface() async {
    for (final model in models) {
      final url = model.url;
      ALDownloader.addALDownloaderHandlerInterface(
          ALDownloaderHandlerInterface(progressHandler: (progress) {
            model.progress = progress;
            setState(() {});

            debugPrint(
                "ALDownloader | downloading, the url = $url, progress = $progress");
          }, successHandler: () {
            debugPrint("ALDownloader | download successfully, the url = $url");

            model.isSuccess = true;
            setState(() {});
          }, failureHandler: () {
            debugPrint("ALDownloader | download failed, the url = $url");

            model.isSuccess = false;
            setState(() {});
          }, pausedHandler: () {
            debugPrint("ALDownloader | download paused, the url = $url");

            model.isSuccess = false;
            setState(() {});
          }),
          url);
    }
  }

  /// batch download
  testBatchDownload() async {
    final urls = models.map((e) => e.url!).toList();
    await ALDownloaderBatcher.downloadUrls(urls,
        downloaderHandlerInterface:
            ALDownloaderHandlerInterface(progressHandler: (progress) {
          debugPrint("ALDownloader | batch |downloading, progress = $progress");
        }, successHandler: () {
          debugPrint("ALDownloader | batch | download successfully");
        }, failureHandler: () {
          debugPrint("ALDownloader | batch | download failed");
        }, pausedHandler: () {
          debugPrint("ALDownloader | batch | download paused");
        }));
  }

  /// download
  testDownload() async {
    final urls = models.map((e) => e.url!).toList();
    final url = urls.first;

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
  }

  /// path
  testPath() async {
    final urls = models.map((e) => e.url!).toList();
    final url = urls.first;

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
  }

  testRemoveInterface() async {
    final urls = models.map((e) => e.url!).toList();
    final url = urls.first;
    ALDownloader.removeALDownloaderHandlerInterfaceForUrl(url);
  }

  testStatus() {
    final urls = models.map((e) => e.url!).toList();
    final url = urls.first;

    ALDownloaderStatus status = ALDownloader.getDownloadStatusForUrl(url);
    debugPrint(
        "ALDownloader | get the download status, url = $url, status= $status\n");
  }
}

/// model class for test
class DownloadModel {
  final String? url;

  double progress = 0;

  bool isSuccess = false;

  String get progressForPercent {
    int aProgress = (progress * 100).toInt();
    return "$aProgress%";
  }

  DownloadModel(this.url);
}

///  ----------------------data for test----------------------

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
  "http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4"
];

final kTestOthers = ["https://www.orimi.com/pdf-test.pdf"];
