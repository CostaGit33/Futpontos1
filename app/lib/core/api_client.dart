import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Future<dynamic>> _pendingGets = {};
  String? _bearerToken;

  void setBearerToken(String? token) => _bearerToken = token;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
  };

  static const baseUrl = 'https://api.semdominio.online';

  /// Reaproveita uma consulta GET enquanto a mesma rota já está em andamento.
  /// Evita que telas montadas simultaneamente disparem a mesma requisição.
  Future<dynamic> get(String path) async {
    final pending = _pendingGets[path];
    if (pending != null) return pending;

    final request = _fetch(path);
    _pendingGets[path] = request;

    try {
      return await request;
    } finally {
      if (identical(_pendingGets[path], request)) {
        _pendingGets.remove(path);
      }
    }
  }

  Future<dynamic> _fetch(String path) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
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



  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(data));
    }
    return data;
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl$path'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(data));
    }
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'senha': password}),
    ).timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(data));
    }
    if (data is! Map) throw const FormatException('Resposta inválida no login.');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> authMe(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    final data = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(data));
    }
    if (data is! Map) throw const FormatException('Resposta inválida da sessão.');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> uploadPlayerPhoto({
    required int playerId,
    required List<int> bytes,
    required String filename,
    required String token,
  }) async {
    final request = http.MultipartRequest(
      'POST', Uri.parse('$baseUrl/jogadores/$playerId/foto'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(http.MultipartFile.fromBytes('foto', bytes, filename: filename));
    final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final data = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(data));
    }
    if (data is! Map) throw const FormatException('Resposta inválida no envio da foto.');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> uploadGoalkeeperPhoto({
    required int goalkeeperId,
    required List<int> bytes,
    required String filename,
    required String token,
  }) async {
    final request = http.MultipartRequest(
      'POST', Uri.parse('$baseUrl/goleiros/$goalkeeperId/foto'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(http.MultipartFile.fromBytes('foto', bytes, filename: filename));
    final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final data = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(data));
    }
    if (data is! Map) throw const FormatException('Resposta inválida no envio da foto.');
    return Map<String, dynamic>.from(data);
  }

  dynamic _decodeResponse(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const FormatException('A API retornou uma resposta inválida.');
    }
  }

  String _errorMessage(dynamic data) => data is Map
      ? (data['error'] ?? data['message'] ?? 'Falha na API').toString()
      : 'Falha na API';

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
