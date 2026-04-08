import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_study_v2/features/bible/data/sources/bible_database_service.dart';
import 'package:jw_study_v2/features/bible/presentation/providers/bible_providers.dart';

final videoDownloadServiceProvider = Provider((ref) {
  return VideoDownloadService(ref.read(bibleDatabaseProvider));
});

class VideoDownloadService {
  final BibleDatabaseService _databaseService;
  final Dio _dio = Dio();

  VideoDownloadService(this._databaseService);

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'videos');
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<bool> isDownloaded(String bookId) async {
    final video = await _databaseService.getBookIntroVideo(bookId);
    if (video == null || video.localPath == null) return false;
    return await File(video.localPath!).exists();
  }

  Future<void> downloadVideo(String bookId, String url, Function(double progress) onProgress) async {
    try {
      final localFolder = await _localPath;
      final fileName = '$bookId.mp4';
      final savePath = p.join(localFolder, fileName);

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      await _databaseService.updateBookIntroLocalPath(bookId, savePath);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDownloadedVideo(String bookId) async {
    final video = await _databaseService.getBookIntroVideo(bookId);
    if (video != null && video.localPath != null) {
      final file = File(video.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
      await _databaseService.updateBookIntroLocalPath(bookId, null);
    }
  }
}
