import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'network/auth_interceptor.dart';
import 'network/error_interceptor.dart';
import 'network/token_store.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(const FlutterSecureStorage()),
);

final baseUrlProvider = NotifierProvider<BaseUrlController, String>(
  BaseUrlController.new,
);

class BaseUrlController extends Notifier<String> {
  @override
  String build() {
    return ref.read(sharedPreferencesProvider).getString(kBaseUrlPrefsKey) ??
        kDefaultBaseUrl;
  }

  Future<void> setBaseUrl(String value) async {
    if (state == value) {
      return;
    }
    state = value;
    await ref
        .read(sharedPreferencesProvider)
        .setString(kBaseUrlPrefsKey, value);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final value = ref
        .read(sharedPreferencesProvider)
        .getString(kThemeModePrefsKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(kThemeModePrefsKey, mode.name);
  }
}

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      headers: const {'Accept': 'application/json'},
      listFormat: ListFormat.multi,
    ),
  );

  dio.interceptors.add(AuthInterceptor(tokenStore));
  dio.interceptors.add(ErrorInterceptor());

  return dio;
});
