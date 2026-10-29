import 'package:flutter_test/flutter_test.dart';
import 'package:neocanvas/features/courses/domain/course.dart';
import 'package:neocanvas/features/courses/presentation/courses_providers.dart';

Course course({
  required int id,
  required String name,
  String code = '',
  bool favorite = false,
  String? termName,
  DateTime? termStart,
  List<Teacher> teachers = const [],
}) {
  return Course(
    id: id,
    name: name,
    courseCode: code,
    workflowState: 'available',
    isFavorite: favorite,
    term: termName == null
        ? null
        : Term(id: 1, name: termName, startAt: termStart),
    teachers: teachers,
  );
}

void main() {
  group('filterCourses', () {
    final courses = [
      course(
        id: 1,
        name: 'Computer Programming',
        code: 'CS1234',
        teachers: const [Teacher(id: 1, displayName: 'Prof. Chan')],
      ),
      course(id: 2, name: 'Calculus', code: 'MA1234'),
    ];

    test('matches name, code, and teacher', () {
      expect(filterCourses(courses, 'computer'), hasLength(1));
      expect(filterCourses(courses, 'MA1234'), hasLength(1));
      expect(filterCourses(courses, 'chan'), hasLength(1));
    });

    test('returns all courses for an empty query', () {
      expect(filterCourses(courses, '  '), hasLength(2));
    });
  });

  group('groupCourses', () {
    test('puts favorites first and groups by term', () {
      final courses = [
        course(
          id: 1,
          name: 'B',
          favorite: true,
          termName: '2026/27 Sem A',
          termStart: DateTime(2026, 9),
        ),
        course(
          id: 2,
          name: 'A',
          termName: '2026/27 Sem A',
          termStart: DateTime(2026, 9),
        ),
        course(
          id: 3,
          name: 'C',
          termName: '2025/26 Sem B',
          termStart: DateTime(2026, 1),
        ),
        course(id: 4, name: 'D'),
      ];

      final groups = groupCourses(courses);

      expect(groups.first.title, '最愛');
      expect(groups.first.courses.single.id, 1);
      expect(groups[1].title, '2026/27 Sem A');
      expect(groups[2].title, '2025/26 Sem B');
      expect(groups[3].title, '其他課程');
    });
  });
}
