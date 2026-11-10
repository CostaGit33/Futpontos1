import '../core/api_client.dart';
import 'player.dart';

class Competition {
  const Competition({required this.id, required this.key, required this.name, required this.status, required this.playersCount, this.openedAt, this.closedAt});
  final int id;
  final String key;
  final String name;
  final String status;
  final int playersCount;
  final String? openedAt;
  final String? closedAt;
  bool get isOpen => status == 'aberta';

  factory Competition.fromJson(Map<String, dynamic> json) {
    int number(dynamic value) => int.tryParse('$value') ?? 0;
    return Competition(
      id: number(json['id']),
      key: (json['chave'] ?? '').toString(),
      name: (json['nome'] ?? json['chave'] ?? 'Competência').toString(),
      status: (json['status'] ?? 'fechada').toString(),
      playersCount: number(json['jogadores']),
      openedAt: json['aberta_em']?.toString(),
      closedAt: json['fechada_em']?.toString(),
    );
  }
}

class SeasonData {
  const SeasonData({required this.competition, required this.ranking});
  final Competition competition;
  final List<Player> ranking;
}

class HistoryCollection {
  const HistoryCollection({required this.seasons, required this.failedCompetitions});
  final List<SeasonData> seasons;
  final List<Competition> failedCompetitions;

  SeasonData? get currentSeason {
    for (final season in seasons) {
      if (season.competition.isOpen) return season;
    }
    return null;
  }

  Player? currentPlayer(int playerId) {
    for (final player in currentSeason?.ranking ?? const <Player>[]) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  List<Player> get careerPlayers {
    final totals = <int, _PlayerTotals>{};
    for (final season in seasons) {
      for (final player in season.ranking) {
        final total = totals.putIfAbsent(player.id, () => _PlayerTotals.fromPlayer(player));
        total.add(player);
        total.name = player.name;
        total.photo ??= player.photo;
      }
    }
    final result = totals.entries.map((entry) => entry.value.toPlayer(entry.key)).toList();
    result.sort((a, b) => b.points.compareTo(a.points));
    return result;
  }

  List<Player> historyFor(int playerId) {
    final result = <Player>[];
    for (final season in seasons.reversed) {
      for (final player in season.ranking) {
        if (player.id == playerId) { result.add(player); break; }
      }
    }
    return result;
  }

  static Future<HistoryCollection> load(ApiClient api) async {
    final raw = await api.list('/competencias');
    final competitions = raw.map(Competition.fromJson).where((c) => c.id > 0).toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final results = await Future.wait(competitions.map((competition) async {
      try {
        final ranking = await api.list('/competencias/' + competition.id.toString() + '/jogadores');
        return SeasonData(competition: competition, ranking: ranking.map(Player.fromJson).toList());
      } catch (_) {
        return null;
      }
    }));
    final seasons = results.whereType<SeasonData>().toList()
      ..sort((a, b) => b.competition.key.compareTo(a.competition.key));
    final loaded = seasons.map((s) => s.competition.id).toSet();
    return HistoryCollection(
      seasons: seasons,
      failedCompetitions: competitions.where((c) => !loaded.contains(c.id)).toList(),
    );
  }
}

class _PlayerTotals {
  _PlayerTotals(this.name, this.photo) : points = 0, wins = 0, goals = 0, saves = 0, draws = 0, fouls = 0;
  factory _PlayerTotals.fromPlayer(Player player) => _PlayerTotals(player.name, player.photo);
  String name;
  String? photo;
  int points, wins, goals, saves, draws, fouls;
  void add(Player player) {
    points += player.points;
    wins += player.wins;
    goals += player.goals;
    saves += player.saves;
    draws += player.draws;
    fouls += player.fouls;
  }
  Player toPlayer(int id) => Player(id: id, name: name, photo: photo, points: points, wins: wins, goals: goals, saves: saves, draws: draws, fouls: fouls);
}