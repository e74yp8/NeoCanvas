import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/theme/course_palette.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../course_home/presentation/course_home_screen.dart';
import '../domain/course.dart';
import 'course_row.dart';
import 'courses_providers.dart';

const double kCoursesWideBreakpoint = 1200;
const double _kCollapsedRailWidth = 72;

class CoursesShell extends ConsumerStatefulWidget {
  const CoursesShell({required this.state, required this.child, super.key});

  final GoRouterState state;
  final Widget child;

  @override
  ConsumerState<CoursesShell> createState() => _CoursesShellState();
}

class _CoursesShellState extends ConsumerState<CoursesShell> {
  bool _listCollapsed = false;

  @override
  void initState() {
    super.initState();
    _listCollapsed =
        ref
            .read(sharedPreferencesProvider)
            .getBool(kCourseListCollapsedPrefsKey) ??
        false;
  }

  void _toggleList() {
    setState(() => _listCollapsed = !_listCollapsed);
    ref
        .read(sharedPreferencesProvider)
        .setBool(kCourseListCollapsedPrefsKey, _listCollapsed);
  }

  void _selectCourse(int courseId, {required bool isWide}) {
    ref.read(selectedCourseIdProvider.notifier).select(courseId);
    if (isWide) {
      context.go('/courses/$courseId');
    } else {
      context.push('/courses/$courseId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= kCoursesWideBreakpoint;
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    final canCollapse = isWide && isDesktop;
    final routeCourseId = int.tryParse(
      widget.state.pathParameters['courseId'] ?? '',
    );
    final isDetail = routeCourseId != null;
    final lastSelectedCourseId = ref.watch(selectedCourseIdProvider);
    final selectedCourseId = routeCourseId ?? lastSelectedCourseId;
    final collapsed = canCollapse && _listCollapsed;
    final showList = isWide || !isDetail;
    final listPane = showList && !collapsed
        ? _CourseListPane(
            selectedCourseId: isWide ? selectedCourseId : null,
            onSelect: (courseId) => _selectCourse(courseId, isWide: isWide),
            onCollapse: canCollapse ? _toggleList : null,
          )
        : null;

    final detailPane = isDetail
        ? widget.child
        : (selectedCourseId == null
              ? const EmptyView(
                  title: '選擇一門課程',
                  message: '從左側選擇課程開始。',
                  icon: Icons.school_outlined,
                )
              : CourseHomePane(courseId: selectedCourseId));

    return AppScaffold(
      currentIndex: 0,
      appBar: AppBar(
        title: const Text('課程'),
        automaticallyImplyLeading: false,
        leading: (!isWide && isDetail)
            ? BackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/courses');
                  }
                },
              )
            : null,
      ),
      body: isWide
          ? Row(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: collapsed
                      ? SizedBox(
                          width: _kCollapsedRailWidth,
                          child: _CollapsedCourseRail(
                            onSelect: (courseId) =>
                                _selectCourse(courseId, isWide: isWide),
                            onExpand: _toggleList,
                          ),
                        )
                      : SizedBox(width: 340, child: listPane!),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: detailPane),
              ],
            )
          : (isDetail ? widget.child : listPane!),
    );
  }
}

class _CourseListPane extends ConsumerWidget {
  const _CourseListPane({
    required this.onSelect,
    this.selectedCourseId,
    this.onCollapse,
  });

  final ValueChanged<int> onSelect;
  final int? selectedCourseId;
  final VoidCallback? onCollapse;

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
                child: TextFormField(
                  initialValue: query,
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
              if (onCollapse != null)
                IconButton(
                  tooltip: '收起課程列表',
                  onPressed: onCollapse,
                  icon: const Icon(Icons.chevron_left),
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

class _CollapsedCourseRail extends ConsumerWidget {
  const _CollapsedCourseRail({required this.onSelect, required this.onExpand});

  final ValueChanged<int> onSelect;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(courseSearchProvider);
    final courses = ref.watch(coursesProvider);

    return Column(
      children: [
        IconButton(
          tooltip: '展開課程列表',
          onPressed: onExpand,
          icon: const Icon(Icons.chevron_right),
        ),
        const Divider(height: 1),
        Expanded(
          child: courses.when(
            data: (allCourses) {
              final filtered = filterCourses(allCourses, query);
              if (filtered.isEmpty) {
                return const Center(
                  child: Tooltip(
                    message: '沒有課程',
                    child: Icon(Icons.school_outlined),
                  ),
                );
              }

              final groups = groupCourses(filtered);
              final flattened = [for (final group in groups) ...group.courses];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: flattened.length,
                itemBuilder: (context, index) {
                  final course = flattened[index];
                  return _CollapsedCourseTile(
                    course: course,
                    onTap: () => onSelect(course.id),
                  );
                },
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => Center(
              child: IconButton(
                tooltip: '載入失敗，點擊重試',
                onPressed: () => ref.invalidate(coursesProvider),
                icon: const Icon(Icons.error_outline),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsedCourseTile extends StatefulWidget {
  const _CollapsedCourseTile({required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  State<_CollapsedCourseTile> createState() => _CollapsedCourseTileState();
}

class _CollapsedCourseTileState extends State<_CollapsedCourseTile> {
  final LayerLink _labelLink = LayerLink();
  OverlayEntry? _labelEntry;

  @override
  void dispose() {
    _hideLabel();
    super.dispose();
  }

  void _showLabel() {
    if (_labelEntry != null || !mounted) {
      return;
    }
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    _labelEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _labelLink,
          targetAnchor: Alignment.centerRight,
          followerAnchor: Alignment.centerLeft,
          offset: const Offset(8, 0),
          showWhenUnlinked: false,
          child: IgnorePointer(
            child: Material(
              type: MaterialType.card,
              elevation: 2,
              color: theme.colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    widget.course.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_labelEntry!);
  }

  void _hideLabel() {
    _labelEntry?.remove();
    _labelEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = courseAccent(widget.course.id);

    return SizedBox(
      height: 56,
      child: Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _showLabel(),
            onExit: (_) => _hideLabel(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              onLongPressStart: (_) => _showLabel(),
              onLongPressEnd: (_) => _hideLabel(),
              child: Semantics(
                label: widget.course.name,
                button: true,
                child: Center(
                  child: CompositedTransformTarget(
                    link: _labelLink,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              widget.course.initials,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.course.isFavorite)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Icon(
                                Icons.star,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
