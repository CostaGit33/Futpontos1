import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final Map<String, Future<dynamic>> _pendingGets = {};
  String? _bearerToken;
  static const baseUrl = 'https://api.semdominio.online';
  void setBearerToken(String? token) => _bearerToken = token;
  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
  };
  Future<dynamic> get(String path) async {
    final pending = _pendingGets[path];
    if (pending != null) return pending;
    final request = _fetch(path);
    _pendingGets[path] = request;
    try { return await request; }
    finally { if (identical(_pendingGets[path], request)) _pendingGets.remove(path); }
  }
  Future<dynamic> _fetch(String path) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(const Duration(seconds: 15));
    return _decode(response);
  }
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(Uri.parse('$baseUrl$path'), headers: {..._headers, 'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
    return _decode(response);
  }
  dynamic _decode(http.Response response) {
    dynamic data;
    try { data = jsonDecode(utf8.decode(response.bodyBytes)); }
    on FormatException { throw const FormatException('A API retornou uma resposta inválida.'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? (data['error'] ?? data['message'] ?? 'Falha na API').toString() : 'Falha na API';
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
    return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
}