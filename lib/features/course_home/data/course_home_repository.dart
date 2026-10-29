import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../courses/domain/course.dart';
import '../domain/course_page.dart';

final courseHomeRepositoryProvider = Provider<CourseHomeRepository>(
  (ref) => CourseHomeRepository(ref.watch(dioProvider)),
);

class CourseHomeRepository {
  CourseHomeRepository(this._dio);

  final Dio _dio;

  Future<Course> getCourse(int courseId) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/courses/$courseId',
        queryParameters: {
          'include[]': [
            'syllabus_body',
            'teachers',
            'term',
            'tabs',
            'course_image',
          ],
        },
      );
      final data = response.data;
      if (data == null) {
        throw const UnknownException('無法取得課程資料。');
      }
      return Course.fromJson(data);
    });
  }

  Future<CoursePage?> getFrontPage(int courseId) async {
    try {
      return await guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/v1/courses/$courseId/front_page',
        );
        final data = response.data;
        if (data == null) {
          return null;
        }
        return CoursePage.fromJson(data);
      });
    } on NotFoundException {
      return null;
    }
  }

  Future<List<CourseTab>> getTabs(int courseId) {
    return guardApi(() async {
      final response = await _dio.get<List<dynamic>>(
        '/api/v1/courses/$courseId/tabs',
      );
      final data = response.data ?? const <dynamic>[];
      return data
          .whereType<Map>()
          .map((item) => CourseTab.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    });
  }
}
