import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/utils/url_utils.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});

  final String? message;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthUnknown();
  }

  Future<void> _restore() async {
    final store = ref.read(tokenStoreProvider);
    final token = await store.load();
    if (token == null || token.isEmpty) {
      state = const AuthUnauthenticated();
      return;
    }

    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthAuthenticated(user);
    } on UnauthorizedException {
      await store.clear();
      state = const AuthUnauthenticated();
    } on AppException catch (error) {
      state = AuthUnauthenticated(message: error.userMessage);
    } catch (_) {
      state = const AuthUnauthenticated(message: '無法驗證登入狀態。');
    }
  }

  Future<void> signIn({required String baseUrl, required String token}) async {
    final normalized = normalizeBaseUrl(baseUrl);
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('請輸入 Personal Access Token。');
    }

    final store = ref.read(tokenStoreProvider);
    store.setMemory(trimmed);

    try {
      await ref.read(baseUrlProvider.notifier).setBaseUrl(normalized);
      final user = await ref.read(authRepositoryProvider).me();
      await store.save(trimmed);
      state = AuthAuthenticated(user);
    } catch (error) {
      store.setMemory(null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AuthUnauthenticated();
  }
}
