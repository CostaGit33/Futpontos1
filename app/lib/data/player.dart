import '../core/points_calculator.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    this.photo,
    this.points = 0,
    this.wins = 0,
    this.goals = 0,
    this.saves = 0,
    this.draws = 0,
    this.fouls = 0,
  });

  final int id;
  final String name;
  final String? photo;
  final int points, wins, goals, saves, draws, fouls;

  factory Player.fromJson(Map<String, dynamic> json) {
    int n(String key) => int.tryParse('${json[key] ?? 0}') ?? 0;
    final wins = n('vitorias');
    final goals = n('gols');
    final saves = n('defesa');
    final draws = n('empate');
    final fouls = n('infracoes');
    return Player(
      id: n('id'),
      name: (json['nome'] ?? 'Jogador').toString(),
      photo: json['foto']?.toString(),
      points: json['pontos'] == null
          ? PointsCalculator.calculate(
              wins: wins, goals: goals, saves: saves,
              draws: draws, fouls: fouls)
          : n('pontos'),
      wins: wins, goals: goals, saves: saves, draws: draws, fouls: fouls,
    );
  }
}
