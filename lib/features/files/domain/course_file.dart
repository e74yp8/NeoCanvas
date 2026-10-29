import '../../../core/utils/url_utils.dart';

class CourseFile {
  const CourseFile({
    required this.id,
    required this.displayName,
    required this.filename,
    required this.contentType,
    required this.mimeClass,
    required this.size,
    this.courseId,
    this.updatedAt,
    this.lockedForUser = false,
    this.url,
  });

  factory CourseFile.fromJson(Map<String, dynamic> json, {int? courseId}) {
    return CourseFile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      courseId: courseId,
      displayName: json['display_name'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      contentType: json['content-type'] as String? ?? '',
      mimeClass: json['mime_class'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      lockedForUser: json['locked_for_user'] == true,
      url: json['url'] as String?,
    );
  }

  final int id;
  final int? courseId;
  final String displayName;
  final String filename;
  final String contentType;
  final String mimeClass;
  final int size;
  final DateTime? updatedAt;
  final bool lockedForUser;
  final String? url;

  bool get isPdf => looksLikePdf(displayName, contentType, mimeClass);

  String get prettySize {
    if (size <= 0) {
      return '';
    }
    if (size < 1024) {
      return '$size B';
    }
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(0)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
