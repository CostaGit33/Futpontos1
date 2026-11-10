import '../core/api_client.dart';
import 'player.dart';

class Competition {
  const Competition({
    required this.id,
    required this.key,
    required this.name,
    required this.status,
    required this.playersCount,
    this.openedAt,
    this.closedAt,
  });

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
  const HistoryCollection({
    required this.seasons,
    required this.failedCompetitions,
  });

  final List<SeasonData> seasons;
  final List<Competition> failedCompetitions;

  List<Player> get careerPlayers {
    final totals = <int, _PlayerTotals>{};
    for (final season in seasons.reversed) {
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
        if (player.id == playerId) {
          result.add(player);
          break;
        }
      }
    }
    return result;
  }

  static Future<HistoryCollection> load(ApiClient api) async {
    final rawCompetitions = await api.list('/competencias');
    final competitions = rawCompetitions
        .map(Competition.fromJson)
        .where((c) => c.id > 0)
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    final results = await Future.wait(competitions.map((competition) async {
      try {
        final raw = await api.list('/competencias/' + competition.id.toString() + '/jogadores');
        final players = raw.map(Player.fromJson).toList();
        return SeasonData(competition: competition, ranking: players);
      } catch (_) {
        return null;
      }
    }));

    final seasons = results.whereType<SeasonData>().toList()
      ..sort((a, b) => b.competition.key.compareTo(a.competition.key));
    final loadedIds = seasons.map((s) => s.competition.id).toSet();
    final failures = competitions.where((c) => !loadedIds.contains(c.id)).toList();
    return HistoryCollection(seasons: seasons, failedCompetitions: failures);
  }
}

class _PlayerTotals {
  _PlayerTotals(this.name, this.photo, this.points, this.wins, this.goals,
      this.saves, this.draws, this.fouls);

  factory _PlayerTotals.fromPlayer(Player p) => _PlayerTotals(
        p.name, p.photo, 0, 0, 0, 0, 0, 0);

  String name;
  String? photo;
  int points, wins, goals, saves, draws, fouls;

  void add(Player p) {
    points += p.points;
    wins += p.wins;
    goals += p.goals;
    saves += p.saves;
    draws += p.draws;
    fouls += p.fouls;
  }

  Player toPlayer(int id) => Player(
        id: id,
        name: name,
        photo: photo,
        points: points,
        wins: wins,
        goals: goals,
        saves: saves,
        draws: draws,
        fouls: fouls,
      );
}
