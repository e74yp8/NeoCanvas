import 'package:dio/dio.dart';

import 'api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = err.error;
    if (mapped is AppException) {
      handler.next(err);
      return;
    }
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppException.fromDio(err),
        stackTrace: err.stackTrace,
        message: err.message,
      ),
    );
  }
}
