import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  String get userMessage => message;

  @override
  String toString() => '$runtimeType: $message';

  static AppException fromDio(DioException error) {
    final response = error.response;
    final status = response?.statusCode;
    final message = _extractMessage(response?.data) ?? _fallbackMessage(status);

    if (status == 401) {
      return UnauthorizedException(message);
    }
    if (status == 403) {
      final lower = message.toLowerCase();
      if (lower.contains('rate limit') || lower.contains('throttl')) {
        return RateLimitedException(message);
      }
      return ForbiddenException(message);
    }
    if (status == 404) {
      return NotFoundException(message);
    }
    if (status == 429) {
      return RateLimitedException(
        message,
        _parseRetryAfter(response?.headers.value('retry-after')),
      );
    }
    if (status != null && status >= 500) {
      return ServerException(message, status);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException('連線逾時，請稍後再試。');
      case DioExceptionType.connectionError:
        return const NetworkException('無法連線到 Canvas，請檢查網路。');
      case DioExceptionType.badCertificate:
        return const NetworkException('Canvas 憑證驗證失敗。');
      case DioExceptionType.cancel:
        return const UnknownException('請求已取消。');
      case DioExceptionType.badResponse:
        return ServerException(message, status);
      case DioExceptionType.unknown:
        return UnknownException(message);
    }
  }

  static String? _extractMessage(Object? data) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final messages = errors
            .whereType<Map>()
            .map((item) => item['message'])
            .whereType<String>()
            .where((item) => item.isNotEmpty)
            .toList();
        if (messages.isNotEmpty) {
          return messages.join('；');
        }
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is String && data.isNotEmpty && data.length < 300) {
      return data;
    }
    return null;
  }

  static String _fallbackMessage(int? status) {
    if (status == null) {
      return '發生未知錯誤，請稍後再試。';
    }
    return 'Canvas 回應錯誤（HTTP $status）。';
  }

  static Duration? _parseRetryAfter(String? value) {
    if (value == null) {
      return null;
    }
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }
    try {
      final date = DateTime.parse(value);
      final diff = date.difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    } on FormatException {
      return null;
    }
  }
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = '登入已失效，請重新登入。']);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = '沒有權限存取此資源。']);
}

class RateLimitedException extends AppException {
  const RateLimitedException([
    super.message = '請求過於頻繁，請稍後再試。',
    this.retryAfter,
  ]);

  final Duration? retryAfter;
}

class NetworkException extends AppException {
  const NetworkException([super.message = '網路連線失敗。']);
}

class ServerException extends AppException {
  const ServerException([super.message = '伺服器發生錯誤。', this.statusCode]);

  final int? statusCode;
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = '找不到資源。']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = '發生未知錯誤。']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class DownloadException extends AppException {
  const DownloadException(super.message);
}

Future<T> guardApi<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    final mapped = error.error;
    if (mapped is AppException) {
      throw mapped;
    }
    throw AppException.fromDio(error);
  }
}
