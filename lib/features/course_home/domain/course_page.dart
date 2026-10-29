class CoursePage {
  const CoursePage({
    required this.url,
    required this.title,
    required this.body,
    this.updatedAt,
  });

  factory CoursePage.fromJson(Map<String, dynamic> json) {
    return CoursePage(
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  final String url;
  final String title;
  final String body;
  final DateTime? updatedAt;
}
