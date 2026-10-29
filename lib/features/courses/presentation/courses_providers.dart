import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';

final coursesProvider = FutureProvider<List<Course>>(
  (ref) => ref.watch(coursesRepositoryProvider).listCourses(),
);

final courseSearchProvider = NotifierProvider<CourseSearchController, String>(
  CourseSearchController.new,
);

class CourseSearchController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final selectedCourseIdProvider =
    NotifierProvider<SelectedCourseController, int?>(
      SelectedCourseController.new,
    );

class SelectedCourseController extends Notifier<int?> {
  @override
  int? build() {
    return ref.read(sharedPreferencesProvider).getInt(kSelectedCoursePrefsKey);
  }

  Future<void> select(int? courseId) async {
    state = courseId;
    final prefs = ref.read(sharedPreferencesProvider);
    if (courseId == null) {
      await prefs.remove(kSelectedCoursePrefsKey);
    } else {
      await prefs.setInt(kSelectedCoursePrefsKey, courseId);
    }
  }
}

class CourseGroup {
  const CourseGroup({required this.title, required this.courses});

  final String title;
  final List<Course> courses;
}

List<Course> filterCourses(List<Course> courses, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return courses;
  }
  return courses
      .where((course) {
        return course.name.toLowerCase().contains(normalized) ||
            course.courseCode.toLowerCase().contains(normalized) ||
            course.teacherNames.toLowerCase().contains(normalized);
      })
      .toList(growable: false);
}

List<CourseGroup> groupCourses(List<Course> courses) {
  final favorites = courses.where((course) => course.isFavorite).toList()
    ..sort(_byName);

  final groups = <String, List<Course>>{};
  final termStarts = <String, DateTime?>{};

  for (final course in courses.where((course) => !course.isFavorite)) {
    final title = course.termName.isEmpty ? '其他課程' : course.termName;
    groups.putIfAbsent(title, () => <Course>[]).add(course);
    termStarts.putIfAbsent(title, () => course.term?.startAt);
  }

  final titles = groups.keys.toList()
    ..sort((a, b) {
      if (a == '其他課程') {
        return 1;
      }
      if (b == '其他課程') {
        return -1;
      }
      final startA = termStarts[a];
      final startB = termStarts[b];
      if (startA != null && startB != null) {
        return startB.compareTo(startA);
      }
      return a.compareTo(b);
    });

  final result = <CourseGroup>[];
  if (favorites.isNotEmpty) {
    result.add(CourseGroup(title: '最愛', courses: favorites));
  }
  for (final title in titles) {
    final list = groups[title]!..sort(_byName);
    result.add(CourseGroup(title: title, courses: list));
  }
  return result;
}

int _byName(Course a, Course b) => a.name.compareTo(b.name);
