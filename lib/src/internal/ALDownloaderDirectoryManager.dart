import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'ALDownloaderPrint.dart';

abstract class ALDownloaderDirectoryManager {
  /// Try to create a directory
  static Future<Directory?> tryToCreateCustomDirectory(String path,
      {bool recursive = false}) async {
    Directory? dir = Directory(path);
    try {
      bool exists = await dir.exists();
      if (!exists) dir = await dir.create(recursive: recursive);
    } catch (error) {
      aldDebugPrint(
          'ALDownloaderDirectoryManager | tryToCreateCustomDirectory, error: $error');
    }

    return dir;
  }

  /// Get `document directory`
  // ignore: unused_element
  static Future<String> get localDocumentDirectory async {
    String? aPath;
    try {
      final aDir = await getApplicationDocumentsDirectory();
      aPath = aDir.path;

      aldDebugPrint(
          'ALDownloaderDirectoryManager | get localDocumentDirectory, directoryPath = $aPath');
    } catch (error) {
      aldDebugPrint(
          'ALDownloaderDirectoryManager | get localDocumentDirectory, error: $error');
    }

    return aPath!;
  }

  /// Get `temporary directory`
  // ignore: unused_element
  static Future<String> get localTemporaryDirectory async {
    String? aPath;
    try {
      final aDir = await getTemporaryDirectory();
      aPath = aDir.path;

      aldDebugPrint(
          'ALDownloaderDirectoryManager | get localTemporaryDirectory, directoryPath = $aPath');
    } catch (error) {
      aldDebugPrint(
          'ALDownloaderDirectoryManager | get localTemporaryDirectory, error: $error');
    }

    return aPath!;
  }

  /// Get `external storage directory`
  ///
  /// **note**
  ///
  /// No iOS
  // ignore: unused_element
  static Future<String?> get localExternalStorageDirectory async {
    String? aPath;
    try {
      final aDir = await getExternalStorageDirectory();
      if (aDir != null) {
        aPath = aDir.path;

        aldDebugPrint(
            'ALDownloaderDirectoryManager | get localExternalStorageDirectory, directoryPath = $aPath');
      } else {
        aldDebugPrint(
            'ALDownloaderDirectoryManager | get localExternalStorageDirectory, directoryPath = none');
      }
    } catch (error) {
      aldDebugPrint(
          'ALDownloaderDirectoryManager | get localExternalStorageDirectory, error: $error');
    }

    return aPath;
  }
}
