import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({this.width, this.height = 12, this.radius = 6, super.key});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class CourseListSkeleton extends StatelessWidget {
  const CourseListSkeleton({this.rows = 7, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rows,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SkeletonBox(width: 40, height: 40, radius: 8),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 180, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
