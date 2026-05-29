import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage(this._storage);

  static const _kimaiTokenKey = 'kimai_api_token';

  final FlutterSecureStorage _storage;

  Future<String?> readKimaiToken() {
    return _storage.read(key: _kimaiTokenKey);
  }

  Future<void> saveKimaiToken(String token) {
    return _storage.write(key: _kimaiTokenKey, value: token);
  }

  Future<void> deleteKimaiToken() {
    return _storage.delete(key: _kimaiTokenKey);
  }
}
