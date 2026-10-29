import 'package:flutter/material.dart';

import '../../../core/theme/course_palette.dart';
import '../domain/course.dart';

class CourseRow extends StatelessWidget {
  const CourseRow({
    required this.course,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Course course;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = courseAccent(course.id);
    final subtitle = <String>[
      if (course.teacherNames.isNotEmpty) course.teacherNames,
      if (course.termName.isNotEmpty) course.termName,
    ].join(' · ');

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              if (selected)
                Container(
                  width: 3,
                  height: 40,
                  margin: const EdgeInsets.only(right: 10),
                  color: theme.colorScheme.primary,
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  course.initials,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (course.isFavorite)
                          Icon(
                            Icons.star,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.courseCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (course.currentScore != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    course.currentScore!.toStringAsFixed(1),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
