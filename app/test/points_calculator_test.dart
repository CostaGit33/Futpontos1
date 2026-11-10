import 'package:flutter_test/flutter_test.dart';
import 'package:futpontos1/core/points_calculator.dart';

void main() {
  group('Pontuação oficial FutPontos', () {
    test('aplica os pesos de vitória, gol, empate, defesa e infração', () {
      expect(
        PointsCalculator.calculate(
          wins: 2,
          goals: 3,
          saves: 4,
          draws: 1,
          fouls: 2,
        ),
        12,
      );
    });

    test('retorna zero sem eventos', () {
      expect(PointsCalculator.calculate(), 0);
    });

    test('infrações subtraem dois pontos cada', () {
      expect(PointsCalculator.calculate(fouls: 3), -6);
    });
  });
}
