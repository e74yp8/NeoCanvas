import '../config/app_config.dart';
import '../network/api_exception.dart';

String normalizeBaseUrl(String input) {
  var value = input.trim();
  if (value.isEmpty) {
    value = kDefaultBaseUrl;
  }
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'https://$value';
  }
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) {
    throw const ValidationException('請輸入有效的 Canvas 網域。');
  }
  if (uri.scheme != 'https') {
    throw const ValidationException('僅支援 HTTPS 網域。');
  }
  var normalized = uri.toString();
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

String absoluteUrl(String baseUrl, String url) {
  final uri = Uri.tryParse(url);
  if (uri != null && uri.hasScheme) {
    return url;
  }
  if (url.isEmpty) {
    return baseUrl;
  }
  return Uri.parse(baseUrl).resolve(url).toString();
}

bool looksLikePdf(String name, String? contentType, String? mimeClass) {
  if (mimeClass == 'pdf') {
    return true;
  }
  if (contentType == 'application/pdf') {
    return true;
  }
  return name.toLowerCase().endsWith('.pdf');
}
