import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Armazena o token de sessão usando o armazenamento seguro da plataforma.
/// Android: Android Keystore. Web: WebCrypto em contexto seguro (HTTPS).
class TokenStorage {
  const TokenStorage();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'futpontos_auth_token';

  Future<String?> readToken() async {
    final secureToken = await _storage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    // Migração única: preserva sessões da versão anterior e remove a cópia
    // em SharedPreferences assim que o token seguro é gravado.
    final preferences = await SharedPreferences.getInstance();
    final legacyToken = preferences.getString(_tokenKey);
    if (legacyToken == null || legacyToken.isEmpty) return null;

    await _storage.write(key: _tokenKey, value: legacyToken);
    await preferences.remove(_tokenKey);
    return legacyToken;
  }

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }
}
