import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthService {
  AuthService(this.api);

  final ApiClient api;
  static const _tokenKey = 'futpontos_auth_token';

  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null || token.isEmpty) return false;
      api.setBearerToken(token);
      await api.authMe(token);
      return true;
    } catch (_) {
      api.setBearerToken(null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email: email, password: password);
    final token = result['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException('Resposta de login inválida.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      api.setBearerToken(null);
    }
  }
}
