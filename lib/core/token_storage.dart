import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Contrato para guardar los tokens de sesión
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
}

// Guardar el token en el keychain(ios) o en keystore(android)
class TokenSeguro implements TokenStorage {
  static const _key = 'auth_token';
  final FlutterSecureStorage _storage;

  TokenSeguro([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readToken() => _storage.read(key: _key);

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _key);

  // Métodos de conveniencia adicionales
  Future<String?> read() => readToken();
  Future<void> save(String token) => saveToken(token);
  Future<void> delete() => deleteToken();
}
