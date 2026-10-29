enum TabKind {
  home,
  syllabus,
  modules,
  assignments,
  pages,
  files,
  grades,
  discussions,
  announcements,
  quizzes,
  external,
  unsupported,
}

TabKind classifyTab({required String id, required String type}) {
  if (type == 'external' ||
      id.startsWith('context_external_tool_') ||
      id.startsWith('nav_menu_link_')) {
    return TabKind.external;
  }
  return switch (id) {
    'home' => TabKind.home,
    'syllabus' => TabKind.syllabus,
    'modules' => TabKind.modules,
    'assignments' => TabKind.assignments,
    'pages' => TabKind.pages,
    'files' => TabKind.files,
    'grades' => TabKind.grades,
    'discussions' => TabKind.discussions,
    'announcements' => TabKind.announcements,
    'quizzes' => TabKind.quizzes,
    _ => TabKind.unsupported,
  };
}

class CanvasFileRef {
  const CanvasFileRef({required this.fileId, this.courseId});

  final int fileId;
  final int? courseId;
}

CanvasFileRef? canvasFileRefFromUrl(String url) {
  final match = RegExp(r'/(?:courses/(\d+)/)?files/(\d+)').firstMatch(url);
  if (match == null) {
    return null;
  }
  final fileId = int.tryParse(match.group(2) ?? '');
  if (fileId == null) {
    return null;
  }
  return CanvasFileRef(
    fileId: fileId,
    courseId: int.tryParse(match.group(1) ?? ''),
  );
}
