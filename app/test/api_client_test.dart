import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:futpontos1/core/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Keeps dependency resolution and request deduplication covered in CI.
void main() {
  test('consulta o endpoint real de saúde e interpreta o estado do banco', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/health');
      return http.Response(
        jsonEncode({'status': 'ok', 'api': 'online', 'database': 'online'}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final api = ApiClient(client: client);
    final health = await api.health();

    expect(health['status'], 'ok');
    expect(health['api'], 'online');
    expect(health['database'], 'online');
  });

  test('compartilha GETs simultâneos da mesma rota sem manter cache antigo', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return http.Response(
        jsonEncode([{'id': 1, 'nome': 'Jogador teste'}]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final api = ApiClient(client: client);
    final results = await Future.wait([
      api.list('/jogadores'),
      api.list('/jogadores'),
      api.list('/jogadores'),
    ]);

    expect(requestCount, 1);
    expect(results, hasLength(3));
    expect(results.every((items) => items.single['id'] == 1), isTrue);

    await api.list('/jogadores');
    expect(requestCount, 2);
  });
}
