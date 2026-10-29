import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../courses/domain/course.dart';
import '../data/course_home_repository.dart';
import '../domain/course_page.dart';

final courseDetailProvider = FutureProvider.family<Course, int>(
  (ref, courseId) =>
      ref.watch(courseHomeRepositoryProvider).getCourse(courseId),
);

final courseTabsProvider = FutureProvider.family<List<CourseTab>, int>((
  ref,
  courseId,
) async {
  final course = await ref.watch(courseDetailProvider(courseId).future);
  final visible = course.tabs.where((tab) => !tab.hidden).toList();
  if (visible.isNotEmpty) {
    return visible;
  }
  final fetched = await ref
      .watch(courseHomeRepositoryProvider)
      .getTabs(courseId);
  return fetched.where((tab) => !tab.hidden).toList(growable: false);
});

final frontPageProvider = FutureProvider.family<CoursePage?, int>(
  (ref, courseId) =>
      ref.watch(courseHomeRepositoryProvider).getFrontPage(courseId),
);
