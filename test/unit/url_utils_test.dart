import 'package:flutter_test/flutter_test.dart';
import 'package:neocanvas/core/content/content_route.dart';
import 'package:neocanvas/core/network/api_exception.dart';
import 'package:neocanvas/core/utils/url_utils.dart';

void main() {
  group('normalizeBaseUrl', () {
    test('adds https and removes trailing slash', () {
      expect(
        normalizeBaseUrl('canvas.cityu.edu.hk/'),
        'https://canvas.cityu.edu.hk',
      );
    });

    test('rejects http', () {
      expect(
        () => normalizeBaseUrl('http://canvas.cityu.edu.hk'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty hosts', () {
      expect(
        () => normalizeBaseUrl('https://'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('absoluteUrl', () {
    const base = 'https://canvas.cityu.edu.hk';

    test('keeps absolute URLs', () {
      expect(
        absoluteUrl(base, 'https://example.com/a'),
        'https://example.com/a',
      );
    });

    test('resolves root-relative URLs', () {
      expect(
        absoluteUrl(base, '/courses/1'),
        'https://canvas.cityu.edu.hk/courses/1',
      );
    });
  });

  group('canvasFileRefFromUrl', () {
    test('parses course file URLs', () {
      final ref = canvasFileRefFromUrl(
        'https://canvas.example/courses/12/files/34/preview',
      );
      expect(ref?.courseId, 12);
      expect(ref?.fileId, 34);
    });

    test('parses file-only URLs', () {
      final ref = canvasFileRefFromUrl('/files/34/download');
      expect(ref?.courseId, isNull);
      expect(ref?.fileId, 34);
    });

    test('returns null for unrelated URLs', () {
      expect(
        canvasFileRefFromUrl('https://canvas.example/courses/12/pages/home'),
        isNull,
      );
    });
  });

  group('looksLikePdf', () {
    test('detects by mime class, content type, and extension', () {
      expect(looksLikePdf('a.pdf', null, null), isTrue);
      expect(looksLikePdf('a', 'application/pdf', null), isTrue);
      expect(looksLikePdf('a', null, 'pdf'), isTrue);
      expect(looksLikePdf('a.png', 'image/png', 'image'), isFalse);
    });
  });
}
