import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:futpontos1/core/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
}
