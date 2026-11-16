import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazena o token de sessão usando o armazenamento seguro da plataforma.
/// Android: Android Keystore. Web: WebCrypto em contexto seguro (HTTPS).
class TokenStorage {
  const TokenStorage();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'futpontos_auth_token';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
