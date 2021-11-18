import 'package:al_downloader/al_downloader.dart';
import 'package:flutter/material.dart';

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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;

      testDownload();
      testBatcherDownload();
      testPath();
      testStatus();
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
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  /// [ALDownloader.download]
  void testDownload() async {
    final url = kTestPNGs.first;

    ALDownloader.download(url,
        downloaderHandlerInterface:
            ALDownloaderHandlerInterface(progressHandler: (progress) {
          debugPrint("ALDownloader | 正在下载， url = $url, progress = $progress");
        }, successHandler: () {
          debugPrint("ALDownloader | 下载成功， url = $url");
        }, failureHandler: () {
          debugPrint("ALDownloader | 下载失败， url = $url");
        }, pausedHandler: () {
          debugPrint("ALDownloader | 已暂停， url = $url");
        }));
  }

  /// 批量下载
  testBatcherDownload() async {
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
  }

  /// 路径
  testPath() async {
    final url = kTestPNGs.first;

    final model = await ALDownloaderPersistentFileManager
        .lazyGetALDownloaderPathModelFromUrl(url);

    final path2 = await ALDownloaderPersistentFileManager
        .getAbsolutePathOfDirectoryWithUrl(url);

    final path3 = await ALDownloaderPersistentFileManager
        .getAbsoluteVirtualPathOfFileWithUrl(url);

    final path4 = await ALDownloaderPersistentFileManager
        .getAbsolutePhysicalPathOfFileWithUrl(url);

    final isExist = await ALDownloaderPersistentFileManager
        .isExistAbsolutePhysicalPathOfFileForUrl(url);

    final fileName = ALDownloaderPersistentFileManager.getFileNameFromUrl(url);

    debugPrint("ALDownloader | 懒创建物理路径模型， url = $url, 路径模型 = $model\n");
    debugPrint("ALDownloader | 获取文件夹绝对物理路径， url = $url, 路径 = $path2\n");
    debugPrint("ALDownloader | 获取文件虚拟路径， url = $url, 路径 = $path3\n");
    debugPrint("ALDownloader | 获取文件物理路径， url = $url, 路径 = $path4\n");
    debugPrint("ALDownloader | 是否存在物理路径， url = $url, 是否存在 = $isExist\n");
    debugPrint("ALDownloader | 获取虚拟/物理文件名， url = $url, 文件名 = $fileName\n");
  }

  testAddInterface() async {
    final url = kTestPNGs.first;

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
  }

  testRemoveInterface() async {
    final url = kTestPNGs.first;
    ALDownloader.removeALDownloaderHandlerInterfaceForUrl(url);
  }

  testStatus() {
    final url = kTestPNGs.first;

    ALDownloaderStatus status = ALDownloader.getDownloadStatusForUrl(url);
    debugPrint("ALDownloader | 获取下载状态， url = $url, status= $status\n");
  }
}
