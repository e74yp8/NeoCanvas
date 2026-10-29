import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/pagination.dart';
import '../../../core/providers.dart';
import '../domain/course.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>(
  (ref) => CoursesRepository(ref.watch(dioProvider)),
);

class CoursesRepository {
  CoursesRepository(this._dio);

  final Dio _dio;

  Future<List<Course>> listCourses() {
    return guardApi(
      () => fetchAllPages<Course>(
        _dio,
        '/api/v1/courses',
        query: {
          'enrollment_state': 'active',
          'per_page': 100,
          'include[]': [
            'term',
            'teachers',
            'favorites',
            'total_scores',
            'course_image',
          ],
        },
        parse: (json) =>
            Course.fromJson(Map<String, dynamic>.from(json! as Map)),
      ),
    );
  }
}
