import 'package:flutter/material.dart';
import 'package:al_downloader/al_downloader.dart';

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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _incrementCounter() {
    setState(() {
      test();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text(
              'tap the floating action button to test al_downloader',
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  /// when executing the following methods together, try to keep them serial
  test() async {
    await testPath();
    await testDownload();
    await testBatchDownload();
    await testStatus();
  }

  /// download
  testDownload() async {
    final url = kTestPNGs.first;

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

  /// batch download
  testBatchDownload() async {
    await ALDownloaderBatcher.downloadUrls(kTestVideos,
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

  /// path
  testPath() async {
    final url = kTestPNGs.first;

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

  testAddInterface() async {
    final url = kTestPNGs.first;

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
  }

  testRemoveInterface() async {
    final url = kTestPNGs.first;
    ALDownloader.removeALDownloaderHandlerInterfaceForUrl(url);
  }

  testStatus() {
    final url = kTestPNGs.first;

    ALDownloaderStatus status = ALDownloader.getDownloadStatusForUrl(url);
    debugPrint(
        "ALDownloader | get the download status, url = $url, status= $status\n");
  }
}
