import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;
  String? _token;

  String? get token => _token;

  Future<String?> load() async {
    _token = await _storage.read(key: kTokenStorageKey);
    return _token;
  }

  void setMemory(String? value) {
    final trimmed = value?.trim();
    _token = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<void> save(String value) async {
    setMemory(value);
    await _storage.write(key: kTokenStorageKey, value: _token);
  }

  Future<void> clear() async {
    _token = null;
    await _storage.delete(key: kTokenStorageKey);
  }
}
