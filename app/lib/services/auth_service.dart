import '../core/api_client.dart';
import 'token_storage.dart';

class AuthService {
  AuthService(this.api);

  final ApiClient api;
  final TokenStorage _tokenStorage = const TokenStorage();

  Future<bool> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      api.setBearerToken(null);
      return false;
    }
    api.setBearerToken(token);
    try {
      await api.authMe(token);
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _tokenStorage.deleteToken();
        api.setBearerToken(null);
        return false;
      }
      api.setBearerToken(null);
      rethrow;
    } catch (_) {
      api.setBearerToken(null);
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email: email, password: password);
    final token = result['token']?.toString();
    if (token == null || token.isEmpty) throw const FormatException('Resposta de login inválida.');
    await _tokenStorage.writeToken(token);
    api.setBearerToken(token);
  }

  Future<Map<String, dynamic>> register({
    required String name, required String email, required String password,
    String? profileType, int? profileId,
  }) async {
    final result = await api.post('/auth/register', {
      'nome': name.trim(), 'email': email.trim(), 'senha': password,
      if (profileType != null && profileId != null) ...{
        'tipo_perfil': profileType, 'perfil_id': profileId,
      },
    });
    if (result is! Map) throw const FormatException('Resposta de cadastro inválida.');
    return Map<String, dynamic>.from(result);
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout', {});
    } finally {
      try { await _tokenStorage.deleteToken(); }
      finally { api.setBearerToken(null); }
    }
  }
}