import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const baseUrl = 'https://api.semdominio.online';

  Future<dynamic> get(String path) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: const {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const FormatException('A API retornou uma resposta inválida.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['error'] ?? data['message'] ?? 'Falha na API').toString()
          : 'Falha na API';
      throw Exception(message);
    }
    return data;
  }

  Future<Map<String, dynamic>> health() async {
    final data = await get('/health');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Resposta inválida no diagnóstico da API.');
  }

  Future<List<Map<String, dynamic>>> list(String path) async {
    final data = await get(path);
    if (data is! List) throw const FormatException('Formato inesperado da API.');
    return data.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
