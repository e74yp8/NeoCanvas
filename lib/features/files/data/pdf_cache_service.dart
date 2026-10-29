import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../domain/course_file.dart';

typedef DownloadProgressCallback = void Function(int received, int total);

final pdfCacheServiceProvider = Provider<PdfCacheService>(
  (ref) => PdfCacheService(ref.watch(dioProvider)),
);

class PdfCacheService {
  PdfCacheService(this._dio);

  final Dio _dio;
  static const int _maxCacheBytes = 1024 * 1024 * 1024;

  Future<Directory> _cacheDirectory() async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory(
      '${base.path}${Platform.pathSeparator}pdf_cache',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _cacheKey(CourseFile file) {
    final version = file.updatedAt?.millisecondsSinceEpoch ?? 0;
    return '${file.id}_$version';
  }

  Future<File> ensureDownloaded(
    CourseFile file, {
    DownloadProgressCallback? onProgress,
  }) async {
    final directory = await _cacheDirectory();
    final key = _cacheKey(file);
    final target = File('${directory.path}${Platform.pathSeparator}$key.pdf');
    if (await target.exists() && await target.length() > 4) {
      if (await _isPdf(target)) {
        return target;
      }
      await target.delete();
    }

    final temp = File('${target.path}.part');
    if (await temp.exists()) {
      await temp.delete();
    }

    try {
      await _download(file, temp.path, onProgress);
      if (!await _isPdf(temp)) {
        throw const DownloadException('下載的內容不是有效的 PDF 檔案。');
      }
      await temp.rename(target.path);
      await _enforceLimit(directory, keepPath: target.path);
      return target;
    } catch (error) {
      if (await temp.exists()) {
        await temp.delete();
      }
      if (error is AppException) {
        rethrow;
      }
      throw DownloadException('PDF 下載失敗：$error');
    }
  }

  Future<void> _download(
    CourseFile file,
    String savePath,
    DownloadProgressCallback? onProgress,
  ) async {
    Uri? publicUri;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/files/${file.id}/public_url',
      );
      final value = response.data?['public_url'];
      if (value is String && value.isNotEmpty) {
        publicUri = Uri.tryParse(value);
      }
    } catch (_) {
      publicUri = null;
    }

    if (publicUri != null) {
      await Dio().downloadUri(
        publicUri,
        savePath,
        onReceiveProgress: onProgress,
      );
      return;
    }

    final coursePrefix = file.courseId == null
        ? ''
        : 'courses/${file.courseId}/';
    await _dio.download(
      '/${coursePrefix}files/${file.id}/download?download_frd=1',
      savePath,
      onReceiveProgress: onProgress,
    );
  }

  Future<bool> _isPdf(File file) async {
    final handle = await file.open();
    try {
      final header = await handle.read(5);
      return header.length == 5 &&
          header[0] == 0x25 &&
          header[1] == 0x50 &&
          header[2] == 0x44 &&
          header[3] == 0x46 &&
          header[4] == 0x2D;
    } finally {
      await handle.close();
    }
  }

  Future<void> _enforceLimit(
    Directory directory, {
    required String keepPath,
  }) async {
    final files = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.pdf'))
        .cast<File>()
        .toList();

    var total = 0;
    final stats = <({File file, DateTime modified, int size})>[];
    for (final file in files) {
      final stat = await file.stat();
      total += stat.size;
      stats.add((file: file, modified: stat.modified, size: stat.size));
    }
    if (total <= _maxCacheBytes) {
      return;
    }

    stats.sort((a, b) => a.modified.compareTo(b.modified));
    for (final entry in stats) {
      if (entry.file.path == keepPath) {
        continue;
      }
      await entry.file.delete();
      total -= entry.size;
      if (total <= _maxCacheBytes) {
        break;
      }
    }
  }

  Future<void> clear() async {
    final directory = await _cacheDirectory();
    await for (final entity in directory.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }

  Future<int> totalBytes() async {
    final directory = await _cacheDirectory();
    var total = 0;
    await for (final entity in directory.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
