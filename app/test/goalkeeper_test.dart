import 'package:flutter_test/flutter_test.dart';
import 'package:futpontos1/data/goalkeeper.dart';

void main() {
  group('Modelo de goleiro', () {
    test('lê estatísticas e avaliação técnica manual', () {
      final goalkeeper = Goalkeeper.fromJson({
        'id': 12,
        'nome': 'Goleiro Teste',
        'pontos': 24,
        'vitorias': 4,
        'empates': 1,
        'derrotas': 2,
        'defesas': 18,
        'gols_sofridos': 7,
        'jogos_disputados': 7,
        'infracoes': 1,
        'gols': 0,
        'avaliacao': {
          'defesa': 18,
          'ataque': 4,
          'velocidade': 12,
          'habilidade': 10,
          'passe': 15,
        },
      });

      expect(goalkeeper.id, 12);
      expect(goalkeeper.saves, 18);
      expect(goalkeeper.concededAverage, 1);
      expect(goalkeeper.assessment, [18, 4, 12, 10, 15]);
    });

    test('não cria avaliação quando a API não retorna os cinco eixos', () {
      final goalkeeper = Goalkeeper.fromJson({
        'id': 13,
        'nome': 'Sem avaliação',
        'avaliacao': {'defesa': 15, 'ataque': 7},
      });

      expect(goalkeeper.assessment, isNull);
    });
  });
}
