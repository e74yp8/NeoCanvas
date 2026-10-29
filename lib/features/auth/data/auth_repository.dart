import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<User> me() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/users/self',
      );
      final data = response.data;
      if (data == null) {
        throw const UnknownException('無法取得使用者資料。');
      }
      return User.fromJson(data);
    });
  }
}
