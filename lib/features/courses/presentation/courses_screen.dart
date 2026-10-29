import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../course_home/presentation/course_home_screen.dart';
import '../domain/course.dart';
import 'course_row.dart';
import 'courses_providers.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  static const double _wideBreakpoint = 1200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final selectedCourseId = ref.watch(selectedCourseIdProvider);

    final listPane = _CourseListPane(
      selectedCourseId: isWide ? selectedCourseId : null,
      onSelect: (courseId) {
        if (isWide) {
          ref.read(selectedCourseIdProvider.notifier).select(courseId);
        } else {
          context.push('/courses/$courseId');
        }
      },
    );

    if (!isWide) {
      return AppScaffold(
        currentIndex: 0,
        appBar: AppBar(title: const Text('課程')),
        body: listPane,
      );
    }

    return AppScaffold(
      currentIndex: 0,
      appBar: AppBar(title: const Text('課程')),
      body: Row(
        children: [
          SizedBox(width: 340, child: listPane),
          const VerticalDivider(width: 1),
          Expanded(
            child: selectedCourseId == null
                ? const EmptyView(
                    title: '選擇一門課程',
                    message: '從左側選擇課程開始。',
                    icon: Icons.school_outlined,
                  )
                : CourseHomePane(courseId: selectedCourseId),
          ),
        ],
      ),
    );
  }
}

class _CourseListPane extends ConsumerWidget {
  const _CourseListPane({required this.onSelect, this.selectedCourseId});

  final ValueChanged<int> onSelect;
  final int? selectedCourseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(courseSearchProvider);
    final courses = ref.watch(coursesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) =>
                      ref.read(courseSearchProvider.notifier).setQuery(value),
                  decoration: const InputDecoration(
                    hintText: '搜尋課程、代碼或老師',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              IconButton(
                tooltip: '重新整理',
                onPressed: () => ref.invalidate(coursesProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueView<List<Course>>(
            value: courses,
            loading: const CourseListSkeleton(),
            onRetry: () => ref.invalidate(coursesProvider),
            data: (allCourses) {
              final filtered = filterCourses(allCourses, query);
              if (filtered.isEmpty) {
                return EmptyView(
                  title: query.trim().isEmpty ? '沒有課程' : '找不到符合的課程',
                  message: query.trim().isEmpty
                      ? '確認 token 權限，或學期是否已經開始。'
                      : '試試其他關鍵字。',
                  icon: Icons.school_outlined,
                );
              }

              final groups = groupCourses(filtered);
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(coursesProvider);
                  await ref.read(coursesProvider.future);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.title,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Text(
                                '${group.courses.length}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        for (final course in group.courses) ...[
                          CourseRow(
                            course: course,
                            selected: course.id == selectedCourseId,
                            onTap: () => onSelect(course.id),
                          ),
                          const Divider(height: 1),
                        ],
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
