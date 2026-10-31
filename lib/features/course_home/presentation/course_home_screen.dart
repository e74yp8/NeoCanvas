import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/content_route.dart';
import '../../../core/providers.dart';
import '../../../core/utils/url_utils.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../courses/domain/course.dart';
import '../../files/presentation/files_pane.dart';
import 'course_home_providers.dart';

class CourseHomePane extends ConsumerStatefulWidget {
  const CourseHomePane({required this.courseId, super.key});

  final int courseId;

  @override
  ConsumerState<CourseHomePane> createState() => _CourseHomePaneState();
}

class _CourseHomePaneState extends ConsumerState<CourseHomePane> {
  String? _selectedTabId;

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final tabsAsync = ref.watch(courseTabsProvider(widget.courseId));

    return AsyncValueView<Course>(
      value: courseAsync,
      loading: const _CourseHomeSkeleton(),
      onRetry: () => ref.invalidate(courseDetailProvider(widget.courseId)),
      data: (course) {
        final tabs = tabsAsync.value ?? const <CourseTab>[];
        final selectedTab = _effectiveTab(tabs);
        CourseTab? tab;
        for (final item in tabs) {
          if (item.id == selectedTab) {
            tab = item;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CourseHeader(
              course: course,
              onRefresh: () {
                ref
                  ..invalidate(courseDetailProvider(widget.courseId))
                  ..invalidate(courseTabsProvider(widget.courseId));
              },
            ),
            if (tabs.isNotEmpty) ...[
              const Divider(),
              _TabBar(
                tabs: tabs,
                selectedId: selectedTab,
                onSelected: (id) => setState(() => _selectedTabId = id),
              ),
            ],
            const Divider(),
            Expanded(child: _buildContent(context, ref, course, tab)),
          ],
        );
      },
    );
  }

  String _effectiveTab(List<CourseTab> tabs) {
    final selected = _selectedTabId;
    if (selected != null && tabs.any((tab) => tab.id == selected)) {
      return selected;
    }
    for (final tab in tabs) {
      if (tab.id == 'home') {
        return tab.id;
      }
    }
    return tabs.isEmpty ? 'home' : tabs.first.id;
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Course course,
    CourseTab? tab,
  ) {
    if (tab == null) {
      return _DefaultView(course: course);
    }

    switch (classifyTab(id: tab.id, type: tab.type)) {
      case TabKind.home:
        return _DefaultView(course: course);
      case TabKind.syllabus:
        return _HtmlBody(
          html: course.syllabusBody,
          emptyMessage: '此課程沒有 syllabus。',
        );
      case TabKind.files:
        return FilesPane(courseId: course.id);
      case TabKind.external:
        return _UnsupportedTab(
          title: tab.label,
          message: '外部工具需要在 Canvas 網頁版登入後使用。',
          url: absoluteUrl(ref.read(baseUrlProvider), tab.htmlUrl),
        );
      case TabKind.modules:
      case TabKind.assignments:
      case TabKind.pages:
      case TabKind.grades:
      case TabKind.discussions:
      case TabKind.announcements:
      case TabKind.quizzes:
        return _UnsupportedTab(
          title: tab.label,
          message: '${tab.label} 尚未在 NeoCanvas 中實作。',
          url: absoluteUrl(ref.read(baseUrlProvider), tab.htmlUrl),
        );
      case TabKind.unsupported:
        return _UnsupportedTab(
          title: tab.label,
          message: '這個頁面類型尚未支援。',
          url: absoluteUrl(ref.read(baseUrlProvider), tab.htmlUrl),
        );
    }
  }
}

class _DefaultView extends ConsumerWidget {
  const _DefaultView({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (course.defaultView) {
      case 'syllabus':
        return _HtmlBody(
          html: course.syllabusBody,
          emptyMessage: '此課程沒有 syllabus。',
        );
      case 'wiki':
        final page = ref.watch(frontPageProvider(course.id));
        return AsyncValueView(
          value: page,
          onRetry: () => ref.invalidate(frontPageProvider(course.id)),
          data: (coursePage) {
            if (coursePage == null || coursePage.body.isEmpty) {
              return const EmptyView(
                title: '此課程沒有首頁內容',
                icon: Icons.article_outlined,
              );
            }
            return _HtmlBody(html: coursePage.body);
          },
        );
      default:
        if (course.syllabusBody != null && course.syllabusBody!.isNotEmpty) {
          return _HtmlBody(html: course.syllabusBody);
        }
        return const EmptyView(
          title: '此課程尚未提供可顯示的首頁內容',
          message: '請使用上方的 tab 瀏覽其他內容。',
          icon: Icons.article_outlined,
        );
    }
  }
}

class _HtmlBody extends StatelessWidget {
  const _HtmlBody({required this.html, this.emptyMessage});

  final String? html;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final content = html?.trim() ?? '';
    if (content.isEmpty) {
      return EmptyView(
        title: emptyMessage ?? '沒有可顯示的內容',
        icon: Icons.article_outlined,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: HtmlWidget(
            content,
            onTapUrl: (url) => _handleLink(context, url),
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Future<bool> _handleLink(BuildContext context, String url) async {
    final fileRef = canvasFileRefFromUrl(url);
    if (fileRef != null) {
      final courseId = fileRef.courseId;
      if (courseId != null) {
        context.push('/courses/$courseId/files/${fileRef.fileId}');
        return true;
      }
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.course, required this.onRefresh});

  final Course course;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      if (course.courseCode.isNotEmpty) course.courseCode,
      if (course.termName.isNotEmpty) course.termName,
      if (course.teacherNames.isNotEmpty) course.teacherNames,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (course.isFavorite)
                      Icon(
                        Icons.star,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      for (final item in meta)
                        Text(
                          item,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: '重新整理',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CourseTab> tabs;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final tab in tabs)
            InkWell(
              onTap: () => onSelected(tab.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Text(
                        tab.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: tab.id == selectedId
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: tab.id == selectedId
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      height: 2,
                      width: 28,
                      color: tab.id == selectedId
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnsupportedTab extends StatelessWidget {
  const _UnsupportedTab({
    required this.title,
    required this.message,
    required this.url,
  });

  final String title;
  final String message;
  final String url;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: title,
      message: message,
      icon: Icons.open_in_new,
      actionLabel: '在瀏覽器開啟',
      onAction: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}

class _CourseHomeSkeleton extends StatelessWidget {
  const _CourseHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 260, height: 20),
          SizedBox(height: 10),
          SkeletonBox(width: 180, height: 12),
          SizedBox(height: 24),
          SkeletonBox(height: 14),
          SizedBox(height: 8),
          SkeletonBox(height: 14),
          SizedBox(height: 8),
          SkeletonBox(width: 320, height: 14),
        ],
      ),
    );
  }
}
