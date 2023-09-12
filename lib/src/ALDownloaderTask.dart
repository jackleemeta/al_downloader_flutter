import 'chore/ALDownloaderFile.dart';
import 'ALDownloaderStatus.dart';

/// ALDownloaderTask
class ALDownloaderTask {
  final String url;

  final double progress;

  final ALDownloaderStatus status;

  /// The physical path to [file] may not exist. If to check the physical path, use [ALDownloaderFileManager].
  final ALDownloaderFile file;

  ALDownloaderTask(this.url, this.progress, this.status, this.file);
}
