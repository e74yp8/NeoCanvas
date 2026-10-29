import 'package:dio/dio.dart';

Future<List<T>> fetchAllPages<T>(
  Dio dio,
  String path, {
  required T Function(Object? json) parse,
  Map<String, dynamic>? query,
}) async {
  final results = <T>[];
  String? next = path;
  Map<String, dynamic>? nextQuery = query;
  var pageCount = 0;

  while (next != null && pageCount < 50) {
    final response = await dio.get<Object?>(next, queryParameters: nextQuery);
    final data = response.data;
    if (data is List) {
      results.addAll(data.map(parse));
    }
    next = nextLink(response.headers.value('link'));
    nextQuery = null;
    pageCount++;
  }

  return results;
}

String? nextLink(String? linkHeader) {
  if (linkHeader == null || linkHeader.isEmpty) {
    return null;
  }
  final matches = RegExp(r'<([^>]+)>\s*;\s*rel="([^"]+)"')
      .allMatches(linkHeader);
  for (final match in matches) {
    if (match.group(2) == 'next') {
      return match.group(1);
    }
  }
  return null;
}
