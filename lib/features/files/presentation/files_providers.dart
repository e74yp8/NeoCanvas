import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/files_repository.dart';
import '../domain/course_file.dart';

final filesProvider = FutureProvider.family<List<CourseFile>, int>(
  (ref, courseId) => ref.watch(filesRepositoryProvider).listPdfFiles(courseId),
);

typedef FileRequest = ({int fileId, int? courseId});

final fileDetailProvider = FutureProvider.family<CourseFile, FileRequest>(
  (ref, request) => ref
      .watch(filesRepositoryProvider)
      .getFile(request.fileId, courseId: request.courseId),
);
