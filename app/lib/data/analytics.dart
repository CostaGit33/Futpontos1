import '../data/player.dart';

class TeamStats {
  TeamStats(List<Player> players) : players = List.unmodifiable(players) {
    totalPoints = players.fold(0, (sum, p) => sum + p.points);
    totalWins = players.fold(0, (sum, p) => sum + p.wins);
    totalGoals = players.fold(0, (sum, p) => sum + p.goals);
    totalSaves = players.fold(0, (sum, p) => sum + p.saves);
    totalDraws = players.fold(0, (sum, p) => sum + p.draws);
    totalFouls = players.fold(0, (sum, p) => sum + p.fouls);
    activePlayers = players.where((p) => p.points != 0 || p.wins + p.goals + p.saves + p.draws + p.fouls > 0).length;
    topScorer = _best(players, (p) => p.goals);
    topWinner = _best(players, (p) => p.wins);
    topDefender = _best(players, (p) => p.saves);
    mostDisciplined = players.isEmpty ? null : (players.toList()..sort((a,b) => a.fouls.compareTo(b.fouls))).first;
    averagePoints = players.isEmpty ? 0 : totalPoints / players.length;
  }

  final List<Player> players;
  late final int totalPoints, totalWins, totalGoals, totalSaves, totalDraws, totalFouls, activePlayers;
  late final double averagePoints;
  late final Player? topScorer, topWinner, topDefender, mostDisciplined;

  static Player? _best(List<Player> players, int Function(Player) value) {
    if (players.isEmpty) return null;
    final sorted = players.toList()..sort((a,b) => value(b).compareTo(value(a)));
    return value(sorted.first) == 0 ? null : sorted.first;
  }
}

class Achievement {
  const Achievement({required this.title, required this.description, required this.icon, required this.progress, required this.target});
  final String title, description;
  final String icon;
  final int progress, target;
  bool get unlocked => progress >= target;
  double get fraction => (progress / target).clamp(0, 1).toDouble();
}

List<Achievement> achievementsFor(Player p) => [
  Achievement(title: 'Primeiro gol', description: 'Marque seu primeiro gol', icon: '⚽', progress: p.goals, target: 1),
  Achievement(title: 'Artilheiro', description: 'Alcance 10 gols', icon: '🎯', progress: p.goals, target: 10),
  Achievement(title: 'Muralha', description: 'Registre 10 defesas', icon: '🧤', progress: p.saves, target: 10),
  Achievement(title: 'Vencedor', description: 'Conquiste 5 vitórias', icon: '🏆', progress: p.wins, target: 5),
  Achievement(title: 'Regularidade', description: 'Some 20 pontos', icon: '🔥', progress: p.points, target: 20),
  Achievement(title: 'Jogo limpo', description: 'Complete 10 participações sem infrações registradas', icon: '🤝', progress: p.fouls == 0 ? p.wins + p.goals + p.saves + p.draws : 0, target: 10),
];

int levelFor(Player p) {
  if (p.points >= 100) return 5;
  if (p.points >= 60) return 4;
  if (p.points >= 30) return 3;
  if (p.points >= 10) return 2;
  return 1;
}

String levelName(int level) => const ['','Iniciante','Amador','Destaque','Craque','Lenda'][level.clamp(1,5)];
