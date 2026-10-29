class User {
  const User({
    required this.id,
    required this.name,
    this.shortName,
    this.avatarUrl,
    this.primaryEmail,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      shortName: json['short_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      primaryEmail: json['primary_email'] as String?,
    );
  }

  final int id;
  final String name;
  final String? shortName;
  final String? avatarUrl;
  final String? primaryEmail;

  String get displayName {
    final short = shortName?.trim();
    if (short != null && short.isNotEmpty) {
      return short;
    }
    return name;
  }
}
