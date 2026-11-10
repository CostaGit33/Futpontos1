import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../data/goalkeeper.dart';
import '../data/player.dart';

class GoalkeepersPage extends StatefulWidget {
  const GoalkeepersPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<GoalkeepersPage> createState() => _GoalkeepersPageState();
}

class _GoalkeepersPageState extends State<GoalkeepersPage> {
  late Future<List<Goalkeeper>> _future;
  String _query = '';
  String _sort = 'Pontos';

  @override
  void initState() { super.initState(); _future = _load(); }

  Future<List<Goalkeeper>> _load() async {
    final data = await widget.api.list('/goleiros');
    final items = data.map(Goalkeeper.fromJson).toList();
    items.sort((a, b) => b.points != a.points ? b.points.compareTo(a.points) : b.saves.compareTo(a.saves));
    return items;
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _future = next);
    try { await next; } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Goalkeeper>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) return _Error(message: snapshot.error.toString(), onRetry: _reload);
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final keepers = snapshot.data!.where((g) => g.name.toLowerCase().contains(_query.trim().toLowerCase())).toList();
      int value(Goalkeeper g) => switch (_sort) {
        'Gols' => g.goals,
        'Defesas' => g.saves,
        'Vitórias' => g.wins,
        'Gols sofridos' => -g.goalsConceded,
        'Infrações' => -g.fouls,
        _ => g.points,
      };
      keepers.sort((a,b) {
        final primary = value(b).compareTo(value(a));
        if (primary != 0) return primary;
        final saves = b.saves.compareTo(a.saves);
        if (saves != 0) return saves;
        final conceded = a.goalsConceded.compareTo(b.goalsConceded);
        return conceded != 0 ? conceded : a.name.compareTo(b.name);
      });

      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
          children: [
            Text('MURAL DOS GOLEIROS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.redLight, letterSpacing: 2, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text('Pódio exclusivo', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar goleiro', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['Pontos', 'Gols', 'Defesas', 'Vitórias', 'Gols sofridos', 'Infrações'].map((item) =>
                Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(
                  label: Text(item), selected: _sort == item,
                  onSelected: (_) => setState(() => _sort = item),
                ))).toList()),
            ),
            const SizedBox(height: 8),
            Text('${keepers.length} goleiros', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 8),
            const SizedBox(height: 18),
            if (keepers.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('Nenhum goleiro cadastrado.')))
            else ...[
              _Podium(keepers: keepers.take(3).toList()),
              const SizedBox(height: 22),
              const Text('Ranking de goleiros', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              ...keepers.asMap().entries.map((entry) => _GoalkeeperTile(
                position: entry.key + 1,
                goalkeeper: entry.value,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GoalkeeperDetailPage(api: widget.api, goalkeeper: entry.value))),
              )),
            ],
          ],
        ),
      );
    },
  );
}

class _Podium extends StatelessWidget {
  const _Podium({required this.keepers});
  final List<Goalkeeper> keepers;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var index = 0; index < keepers.length; index++) Expanded(child: _PodiumCard(goalkeeper: keepers[index], position: index + 1)),
      ]),
    ),
  );
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.goalkeeper, required this.position});
  final Goalkeeper goalkeeper;
  final int position;
  @override
  Widget build(BuildContext context) {
    final color = position == 1 ? AppColors.gold : position == 2 ? Colors.grey.shade300 : const Color(0xFFB87333);
    return Column(children: [
      PlayerAvatar(photo: goalkeeper.photo, radius: position == 1 ? 34 : 28, fallback: Text('$position', style: TextStyle(color: color, fontWeight: FontWeight.w900))),
      const SizedBox(height: 8),
      Text(goalkeeper.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      const SizedBox(height: 3),
      Text('${goalkeeper.points} pts', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
    ]);
  }
}

class _GoalkeeperTile extends StatelessWidget {
  const _GoalkeeperTile({required this.position, required this.goalkeeper, required this.onTap});
  final int position;
  final Goalkeeper goalkeeper;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      leading: PlayerAvatar(photo: goalkeeper.photo, radius: 22, fallback: Text('$position', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold))),
      title: Text(goalkeeper.name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('${goalkeeper.wins} vitórias • ${goalkeeper.goals} gols • ${goalkeeper.saves} defesas', style: const TextStyle(color: AppColors.muted, fontSize: 11)), 
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${goalkeeper.points} pts', style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)),
        Text('${goalkeeper.winRate.toStringAsFixed(0)}% vitórias', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
      ]),
    ),
  );
}

class GoalkeeperDetailPage extends StatefulWidget {
  const GoalkeeperDetailPage({super.key, required this.api, required this.goalkeeper});
  final ApiClient api;
  final Goalkeeper goalkeeper;
  @override
  State<GoalkeeperDetailPage> createState() => _GoalkeeperDetailPageState();
}

class _GoalkeeperDetailPageState extends State<GoalkeeperDetailPage> {
  late Future<_GoalkeeperDetails> _future;
  @override
  void initState() { super.initState(); _future = _load(); }
  Future<_GoalkeeperDetails> _load() async {
    final results = await Future.wait<dynamic>([
      widget.api.get('/goleiros/${widget.goalkeeper.id}').catchError((_) => null),
      widget.api.list('/goleiros/${widget.goalkeeper.id}/partidas').catchError((_) => <Map<String, dynamic>>[]),
      widget.api.list('/goleiros/${widget.goalkeeper.id}/evolucao').catchError((_) => <Map<String, dynamic>>[]),
    ]);
    final detail = results[0] is Map ? Goalkeeper.fromJson(Map<String, dynamic>.from(results[0] as Map)) : widget.goalkeeper;
    final matches = (results[1] is List ? results[1] as List : const <dynamic>[])
        .whereType<Map>()
        .map((item) => GoalkeeperMatch.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final evolution = (results[2] is List ? results[2] as List : const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return _GoalkeeperDetails(detail.id == 0 ? widget.goalkeeper : detail, matches, evolution);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.goalkeeper.name)),
    body: FutureBuilder<_GoalkeeperDetails>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _Error(message: snapshot.error.toString(), onRetry: () async => setState(() => _future = _load()));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final g = snapshot.data!.goalkeeper;
        return ListView(padding: const EdgeInsets.all(18), children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            PlayerAvatar(photo: g.photo, radius: 38, fallback: const Icon(Icons.sports_soccer, color: AppColors.gold)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(g.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text('${g.points} pontos • ${g.competition ?? 'competência atual'}', style: const TextStyle(color: AppColors.muted))])),
          ]))),
          const SizedBox(height: 14),
          _StatsGrid(goalkeeper: g),
          const SizedBox(height: 18),
          _GoalkeeperAchievements(goalkeeper: g),
          const SizedBox(height: 20),
          const Text('AVALIAÇÃO TÉCNICA DE CAMPO', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.redLight, letterSpacing: 0.6)),
          const SizedBox(height: 5),
          const Text('Avaliação individual cadastrada manualmente • escala de 0 a 20', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          if (g.assessment == null)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Este goleiro ainda não possui avaliação técnica manual cadastrada.')))
          else
            _GoalkeeperAssessment(values: g.assessment!),
          const SizedBox(height: 20),
          const Text('Partidas registradas', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (snapshot.data!.matches.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Nenhuma partida de goleiro foi registrada ainda.', style: TextStyle(color: AppColors.muted)))) else ...snapshot.data!.matches.map((m) => Card(child: ListTile(leading: Icon(_resultIcon(m.result), color: _resultColor(m.result)), title: Text(m.result.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${m.saves} defesas • ${m.goalsConceded} gols sofridos'), trailing: Text('${m.points} pts', style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900))))),
          const SizedBox(height: 20),
          const Text('Evolução mensal', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (snapshot.data!.evolution.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Ainda não há competências com dados de goleiro.', style: TextStyle(color: AppColors.muted)))) else ...snapshot.data!.evolution.map((e) => Card(child: ListTile(title: Text('${e['nome'] ?? e['chave'] ?? 'Competência'}'), subtitle: Text('${e['jogos_disputados'] ?? 0} jogos • ${e['defesas'] ?? 0} defesas • ${e['gols_sofridos'] ?? 0} gols sofridos'), trailing: Text('${e['pontos'] ?? 0} pts')))),
        ]);
      },
    ),
  );
}

class _GoalkeeperAchievements extends StatelessWidget {
  const _GoalkeeperAchievements({required this.goalkeeper});
  final Goalkeeper goalkeeper;

  @override
  Widget build(BuildContext context) {
    final g = goalkeeper;
    final items = <(String, String, String, bool)>[
      ('Primeira muralha', 'Registre 10 defesas', '🧤', g.saves >= 10),
      ('Paredão', 'Registre 25 defesas', '🧱', g.saves >= 25),
      ('Vitória', 'Conquiste 5 vitórias', '🏆', g.wins >= 5),
      ('Experiente', 'Dispute 10 partidas', '⭐', g.matches >= 10),
      ('Segurança', 'Média de até 1 gol sofrido em 5 ou mais jogos', '🛡️', g.matches >= 5 && g.concededAverage <= 1),
      ('Disciplina', 'Finalize sem infrações registradas', '🤝', g.matches > 0 && g.fouls == 0),
    ];
    final unlocked = items.where((item) => item.$4).length;
    return Card(child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('CONQUISTAS DO GOLEIRO', style: TextStyle(fontWeight: FontWeight.w900)),
          Text('$unlocked/${items.length}', style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        ...items.map((item) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Text(item.$3, style: const TextStyle(fontSize: 21)),
          title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(item.$2, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          trailing: Icon(item.$4 ? Icons.check_circle : Icons.lock_outline,
            color: item.$4 ? AppColors.gold : AppColors.muted),
        )),
      ]),
    ));
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.goalkeeper});
  final Goalkeeper goalkeeper;
  @override
  Widget build(BuildContext context) => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 2.15, children: [
    _Stat(label: 'Pontos', value: '${goalkeeper.points}'), _Stat(label: 'Jogos', value: '${goalkeeper.matches}'),
    _Stat(label: 'Vitórias', value: '${goalkeeper.wins}'), _Stat(label: 'Empates', value: '${goalkeeper.draws}'),
    _Stat(label: 'Derrotas', value: '${goalkeeper.losses}'), _Stat(label: 'Gols', value: '${goalkeeper.goals}'),
    _Stat(label: 'Defesas', value: '${goalkeeper.saves}'), _Stat(label: 'Gols sofridos', value: '${goalkeeper.goalsConceded}'),
    _Stat(label: 'Infrações', value: '${goalkeeper.fouls}'), _Stat(label: 'Média sofrida', value: goalkeeper.concededAverage.toStringAsFixed(2)),
    _Stat(label: 'Aproveitamento', value: '${goalkeeper.winRate.toStringAsFixed(1)}%'),
  ]);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11))])));
}

class _GoalkeeperDetails {
  const _GoalkeeperDetails(this.goalkeeper, this.matches, this.evolution);
  final Goalkeeper goalkeeper;
  final List<GoalkeeperMatch> matches;
  final List<Map<String, dynamic>> evolution;
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, color: AppColors.redLight, size: 34), const SizedBox(height: 10), const Text('Não foi possível carregar os goleiros.', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente'))])));
}

IconData _resultIcon(String result) => result == 'vitoria' ? Icons.emoji_events : result == 'empate' ? Icons.handshake_outlined : Icons.close;
Color _resultColor(String result) => result == 'vitoria' ? AppColors.gold : result == 'empate' ? Colors.blueAccent : AppColors.redLight;


class _GoalkeeperAssessment extends StatelessWidget {
  const _GoalkeeperAssessment({required this.values});
  final List<double> values;
  static const labels = ['Defesa', 'Ataque', 'Velocidade', 'Habilidade', 'Passe'];

  @override
  Widget build(BuildContext context) {
    final average = values.reduce((a, b) => a + b) / values.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Radar de desempenho', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('${average.toStringAsFixed(1)}/20', style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: CustomPaint(
                painter: _RadarPainter(values: values, lineColor: AppColors.redLight, gridColor: AppColors.muted.withValues(alpha: 0.35)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(values.length, (index) => Text(
                '${labels[index]}: ${values[index].toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.values, required this.lineColor, required this.gridColor});
  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width * 0.31, size.height * 0.36);
    const angleOffset = -math.pi / 2;
    Offset point(int index, double scale) {
      final angle = angleOffset + (2 * math.pi * index / count);
      return Offset(center.dx + math.cos(angle) * radius * scale, center.dy + math.sin(angle) * radius * scale);
    }

    final gridPaint = Paint()..color = gridColor..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var level = 1; level <= 4; level++) {
      final path = Path();
      for (var i = 0; i < count; i++) {
        final p = point(i, level / 4);
        if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }
    for (var i = 0; i < count; i++) {
      final p = point(i, 1);
      canvas.drawLine(center, p, gridPaint);
    }

    final dataPath = Path();
    for (var i = 0; i < count; i++) {
      final p = point(i, (values[i].clamp(0, 20)) / 20);
      if (i == 0) { dataPath.moveTo(p.dx, p.dy); } else { dataPath.lineTo(p.dx, p.dy); }
    }
    dataPath.close();
    canvas.drawPath(dataPath, Paint()..color = lineColor.withValues(alpha: 0.18)..style = PaintingStyle.fill);
    canvas.drawPath(dataPath, Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < count; i++) {
      final p = point(i, (values[i].clamp(0, 20)) / 20);
      canvas.drawCircle(p, 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor || oldDelegate.gridColor != gridColor;
}
