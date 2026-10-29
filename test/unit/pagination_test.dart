import 'package:flutter_test/flutter_test.dart';
import 'package:neocanvas/core/network/pagination.dart';

void main() {
  group('nextLink', () {
    test('returns the next URL from a Link header', () {
      const header =
          '<https://canvas.example/api/v1/courses?page=2&per_page=100>; rel="next", '
          '<https://canvas.example/api/v1/courses?page=1&per_page=100>; rel="first"';
      expect(
        nextLink(header),
        'https://canvas.example/api/v1/courses?page=2&per_page=100',
      );
    });

    test('returns null when there is no next link', () {
      const header =
          '<https://canvas.example/api/v1/courses?page=1>; rel="current"';
      expect(nextLink(header), isNull);
    });

    test('returns null for null or empty headers', () {
      expect(nextLink(null), isNull);
      expect(nextLink(''), isNull);
    });
  });
}
