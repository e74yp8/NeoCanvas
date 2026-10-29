import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/pagination.dart';
import '../../../core/providers.dart';
import '../domain/course_file.dart';

final filesRepositoryProvider = Provider<FilesRepository>(
  (ref) => FilesRepository(ref.watch(dioProvider)),
);

class FilesRepository {
  FilesRepository(this._dio);

  final Dio _dio;

  Future<List<CourseFile>> listPdfFiles(int courseId) async {
    final files = await guardApi(
      () => fetchAllPages<CourseFile>(
        _dio,
        '/api/v1/courses/$courseId/files',
        query: {'per_page': 100},
        parse: (json) => CourseFile.fromJson(
          Map<String, dynamic>.from(json! as Map),
          courseId: courseId,
        ),
      ),
    );
    return files.where((file) => file.isPdf).toList(growable: false);
  }

  Future<CourseFile> getFile(int fileId, {int? courseId}) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/files/$fileId',
      );
      final data = response.data;
      if (data == null) {
        throw const NotFoundException('找不到檔案。');
      }
      return CourseFile.fromJson(data, courseId: courseId);
    });
  }
}
