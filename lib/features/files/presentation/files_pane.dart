import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../domain/course_file.dart';
import 'files_providers.dart';

class FilesPane extends ConsumerWidget {
  const FilesPane({required this.courseId, super.key});

  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesProvider(courseId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('PDF 檔案', style: theme.textTheme.titleSmall),
              ),
              IconButton(
                tooltip: '重新整理',
                onPressed: () => ref.invalidate(filesProvider(courseId)),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: AsyncValueView<List<CourseFile>>(
            value: files,
            loading: const CourseListSkeleton(rows: 5),
            onRetry: () => ref.invalidate(filesProvider(courseId)),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyView(
                  title: '此課程沒有 PDF',
                  message: '目前只顯示 PDF 檔案。',
                  icon: Icons.picture_as_pdf_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(filesProvider(courseId));
                  await ref.read(filesProvider(courseId).future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final file = items[index];
                    return _FileRow(
                      file: file,
                      onTap: () => context.push(
                        '/courses/$courseId/files/${file.id}',
                        extra: file,
                      ),
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

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onTap});

  final CourseFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (file.prettySize.isNotEmpty) file.prettySize,
      if (file.updatedAt != null)
        DateFormat.yMMMd().format(file.updatedAt!.toLocal()),
    ];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (parts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      parts.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
