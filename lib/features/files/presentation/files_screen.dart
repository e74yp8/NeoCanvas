import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../course_home/presentation/course_home_providers.dart';
import 'files_pane.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({required this.courseId, super.key});

  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseDetailProvider(courseId)).value;
    final title = course == null
        ? 'PDF 檔案'
        : '${course.courseCode.isEmpty ? course.name : course.courseCode} · PDF';

    return AppScaffold(
      currentIndex: 0,
      appBar: AppBar(title: Text(title)),
      body: FilesPane(courseId: courseId),
    );
  }
}
