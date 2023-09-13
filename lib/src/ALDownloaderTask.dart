import 'chore/ALDownloaderFile.dart';
import 'ALDownloaderStatus.dart';

/// ALDownloaderTask
class ALDownloaderTask {
  final String url;

  final ALDownloaderStatus status;

  final double progress;

  /// The physical path to [file] may not exist. If to check the physical path, use [ALDownloaderFileManager].
  final ALDownloaderFile file;

  ALDownloaderTask(this.url, this.status, this.progress, this.file);
}
