import 'package:flutter/foundation.dart';
import 'player.dart';

class Goalkeeper {
  const Goalkeeper({
    required this.id,
    required this.name,
    this.photo,
    this.points = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.saves = 0,
    this.goalsConceded = 0,
    this.matches = 0,
    this.fouls = 0,
    this.goals = 0,
    this.competition,
  });

  final int id;
  final String name;
  final String? photo;
  final int points, wins, draws, losses, saves, goalsConceded, matches, fouls, goals;
  final String? competition;

  double get concededAverage => matches == 0 ? 0 : goalsConceded / matches;
  double get winRate => matches == 0 ? 0 : wins * 100 / matches;

  factory Goalkeeper.fromJson(Map<String, dynamic> json) {
    int n(String key) => int.tryParse('${json[key] ?? 0}') ?? 0;
    return Goalkeeper(
      id: n('id'),
      name: (json['nome'] ?? 'Goleiro').toString(),
      photo: resolvePlayerPhoto(json['foto']) ?? resolvePlayerPhoto(json['foto_url']),
      points: n('pontos'),
      wins: n('vitorias'),
      draws: n('empates') == 0 ? n('empate') : n('empates'),
      losses: n('derrotas'),
      saves: n('defesas') == 0 ? n('defesa') : n('defesas'),
      goalsConceded: n('gols_sofridos'),
      matches: n('jogos_disputados'),
      fouls: n('infracoes'),
      goals: n('gols'),
      competition: json['competencia']?.toString(),
    );
  }

  Goalkeeper merge(Map<String, dynamic> detail) {
    final next = Goalkeeper.fromJson({...toJson(), ...detail});
    return next.id == 0 ? this : next;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'nome': name, 'foto': photo, 'pontos': points,
    'vitorias': wins, 'empates': draws, 'derrotas': losses,
    'defesas': saves, 'gols_sofridos': goalsConceded,
    'jogos_disputados': matches, 'infracoes': fouls, 'gols': goals,
    'competencia': competition,
  };
}

@immutable
class GoalkeeperMatch {
  const GoalkeeperMatch({
    required this.operationId,
    required this.result,
    required this.saves,
    required this.goalsConceded,
    required this.points,
    this.date,
    this.competition,
  });

  final String operationId, result;
  final int saves, goalsConceded, points;
  final DateTime? date;
  final String? competition;

  factory GoalkeeperMatch.fromJson(Map<String, dynamic> json) => GoalkeeperMatch(
    operationId: (json['operacao_id'] ?? '').toString(),
    result: (json['resultado'] ?? '—').toString(),
    saves: int.tryParse('${json['defesas'] ?? 0}') ?? 0,
    goalsConceded: int.tryParse('${json['gols_sofridos'] ?? 0}') ?? 0,
    points: int.tryParse('${json['pontos'] ?? 0}') ?? 0,
    date: DateTime.tryParse('${json['registrada_em'] ?? ''}'),
    competition: json['competencia']?.toString(),
  );
}
