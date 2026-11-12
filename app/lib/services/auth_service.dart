import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

class AuthService {
  AuthService(this.api);

  final ApiClient api;
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'futpontos_access_token';

  Future<bool> restoreSession() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null || token.isEmpty) return false;
      api.setBearerToken(token);
      await api.get('/auth/me');
      return true;
    } catch (_) {
      api.setBearerToken(null);
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    final result = await api.post('/auth/login', {
      'email': email.trim(),
      'senha': password,
    });
    if (result is! Map || result['token'] is! String) {
      throw const FormatException('Resposta de login inválida.');
    }
    final token = result['token'] as String;
    await _storage.write(key: _tokenKey, value: token);
    api.setBearerToken(token);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? profileType,
    int? profileId,
  }) async {
    final result = await api.post('/auth/register', {
      'nome': name.trim(),
      'email': email.trim(),
      'senha': password,
      if (profileType != null && profileId != null) ...{
        'tipo_perfil': profileType,
        'perfil_id': profileId,
      },
    });
    if (result is! Map) throw const FormatException('Resposta de cadastro inválida.');
    return Map<String, dynamic>.from(result);
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout', {});
    } finally {
      await _storage.delete(key: _tokenKey);
      api.setBearerToken(null);
    }
  }
}
