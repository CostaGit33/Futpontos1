import 'package:flutter/material.dart';
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
      photo: resolvePlayerPhoto(json['foto']) ??
          resolvePlayerPhoto(json['foto_url']) ??
          resolvePlayerPhoto(json['imagem']) ??
          resolvePlayerPhoto(json['avatar']),
      points: json['pontos'] == null
          ? PointsCalculator.calculate(
              wins: wins, goals: goals, saves: saves,
              draws: draws, fouls: fouls)
          : n('pontos'),
      wins: wins, goals: goals, saves: saves, draws: draws, fouls: fouls,
    );
  }
}

/// O PWA resolve caminhos relativos a partir do domínio do site.
/// O Flutter precisa transformar esses caminhos em URLs absolutas.
String? resolvePlayerPhoto(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty || raw.toLowerCase() == 'null' || raw.toLowerCase() == 'undefined') return null;
  final parsed = Uri.tryParse(raw);
  if (parsed == null) return null;
  if (parsed.hasScheme) {
    if (parsed.scheme != 'http' && parsed.scheme != 'https') return null;
    return parsed.toString();
  }
  if (raw.startsWith('//')) return 'https:$raw';
  return Uri.parse('https://www.semdominio.online/').resolveUri(parsed).toString();
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.photo, required this.radius, required this.fallback});
  final String? photo;
  final double radius;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final url = resolvePlayerPhoto(photo);
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF252B38),
      child: url == null
          ? fallback
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : SizedBox(
                        width: radius * 2,
                        height: radius * 2,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes == null
                                  ? null
                                  : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
    );
  }
}
