import 'ALDownloaderInnerStatus.dart';
import 'ALDownloaderTaskWaitingPhase.dart';

/// A class of custom download task
class ALDownloaderInnerTask {
  final String url;

  String? savedDir;

  String? fileName;

  String taskId = '';

  int get progress => _progress;

  set progress(int value) {
    _progress = value;

    double_progress =
        double.tryParse(((progress / 100).toStringAsFixed(2))) ?? 0;
  }

  ALDownloaderInnerStatus innerStatus = ALDownloaderInnerStatus.undefined;

  ALDownloaderTaskWaitingPhase waitingPhase =
      ALDownloaderTaskWaitingPhase.unwaiting;

  // ignore: non_constant_identifier_names
  double double_progress = 0;

  Map<String, String>? headers;

  bool isMayRedownloadAboutPause = false;

  bool redownloadIfNeeded = false;

  int pIndex = 0;

  String? get filePath {
    final aSavedDir = savedDir;
    final aFileName = fileName;

    if (aSavedDir != null && aFileName != null) return aSavedDir + aFileName;

    return null;
  }

  /// Backup parameters for this task's download turn from waiting tasks
  ///
  /// For example that
  ///
  /// ```
  /// task.willParameters = {
  ///   'headers': {'Cache-Control': 'no-cache'},
  ///   'directoryPath': 'xxxxx',
  ///   'fileName': 'xxxxx',
  ///   'redownloadIfNeeded': true
  /// };
  /// ```
  Map<String, dynamic>? willParameters;

  int _progress = 0;

  ALDownloaderInnerTask(this.url);
}
