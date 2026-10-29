class Course {
  const Course({
    required this.id,
    required this.name,
    required this.courseCode,
    required this.workflowState,
    required this.isFavorite,
    this.defaultView,
    this.term,
    this.teachers = const [],
    this.selfEnrollment,
    this.courseImageUrl,
    this.syllabusBody,
    this.tabs = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final termJson = json['term'];
    final teachersJson = json['teachers'];
    final enrollmentsJson = json['enrollments'];
    final tabsJson = json['tabs'];

    final teachers = teachersJson is List
        ? teachersJson
              .whereType<Map>()
              .map((item) => Teacher.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
        : const <Teacher>[];

    Enrollment? enrollment;
    if (enrollmentsJson is List) {
      final enrollments = enrollmentsJson
          .whereType<Map>()
          .map((item) => Enrollment.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      for (final item in enrollments) {
        if (item.type == 'student' ||
            item.role.toLowerCase().contains('student')) {
          enrollment = item;
          break;
        }
      }
      enrollment ??= enrollments.isEmpty ? null : enrollments.first;
    }

    final tabs = tabsJson is List
        ? tabsJson
              .whereType<Map>()
              .map(
                (item) => CourseTab.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <CourseTab>[];

    return Course(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      courseCode: json['course_code'] as String? ?? '',
      workflowState: json['workflow_state'] as String? ?? '',
      defaultView: json['default_view'] as String?,
      isFavorite: json['favorite'] == true,
      term: termJson is Map
          ? Term.fromJson(Map<String, dynamic>.from(termJson))
          : null,
      teachers: teachers,
      selfEnrollment: enrollment,
      courseImageUrl: json['course_image'] as String?,
      syllabusBody: json['syllabus_body'] as String?,
      tabs: tabs,
    );
  }

  final int id;
  final String name;
  final String courseCode;
  final String workflowState;
  final String? defaultView;
  final bool isFavorite;
  final Term? term;
  final List<Teacher> teachers;
  final Enrollment? selfEnrollment;
  final String? courseImageUrl;
  final String? syllabusBody;
  final List<CourseTab> tabs;

  String get termName => term?.name ?? '';

  String get teacherNames =>
      teachers.map((teacher) => teacher.displayName).join(', ');

  double? get currentScore => selfEnrollment?.currentScore;

  String get initials {
    final code = courseCode.trim();
    if (code.isNotEmpty) {
      final letters = code.replaceAll(RegExp('[^A-Za-z]'), '');
      if (letters.length >= 2) {
        return letters.substring(0, 2).toUpperCase();
      }
      return code.substring(0, code.length >= 2 ? 2 : 1).toUpperCase();
    }
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      return '?';
    }
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return (words[0].substring(0, 1) + words[1].substring(0, 1))
          .toUpperCase();
    }
    return cleaned.substring(0, cleaned.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class Term {
  const Term({required this.id, required this.name, this.startAt, this.endAt});

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      startAt: DateTime.tryParse(json['start_at'] as String? ?? ''),
      endAt: DateTime.tryParse(json['end_at'] as String? ?? ''),
    );
  }

  final int id;
  final String name;
  final DateTime? startAt;
  final DateTime? endAt;
}

class Teacher {
  const Teacher({required this.id, required this.displayName, this.avatarUrl});

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: (json['id'] as num?)?.toInt() ?? 0,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_image_url'] as String?,
    );
  }

  final int id;
  final String displayName;
  final String? avatarUrl;
}

class Enrollment {
  const Enrollment({
    required this.type,
    required this.role,
    this.currentScore,
    this.finalScore,
    this.currentGrade,
    this.finalGrade,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      type: json['type'] as String? ?? '',
      role: json['role'] as String? ?? '',
      currentScore: (json['computed_current_score'] as num?)?.toDouble(),
      finalScore: (json['computed_final_score'] as num?)?.toDouble(),
      currentGrade: json['computed_current_grade'] as String?,
      finalGrade: json['computed_final_grade'] as String?,
    );
  }

  final String type;
  final String role;
  final double? currentScore;
  final double? finalScore;
  final String? currentGrade;
  final String? finalGrade;
}

class CourseTab {
  const CourseTab({
    required this.id,
    required this.label,
    required this.htmlUrl,
    required this.type,
    this.hidden = false,
    this.visibility = '',
    this.position = 0,
  });

  factory CourseTab.fromJson(Map<String, dynamic> json) {
    return CourseTab(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      type: json['type'] as String? ?? 'internal',
      hidden: json['hidden'] == true,
      visibility: json['visibility'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String label;
  final String htmlUrl;
  final String type;
  final bool hidden;
  final String visibility;
  final int position;
}
