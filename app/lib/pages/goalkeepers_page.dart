import 'package:flutter/material.dart';
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
      final keepers = snapshot.data!;
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
            const Text('Estatísticas de goleiros separadas dos jogadores de linha.', style: TextStyle(color: AppColors.muted)),
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
      subtitle: Text('${goalkeeper.matches} jogos • ${goalkeeper.saves} defesas • ${goalkeeper.goalsConceded} gols sofridos', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
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
    final results = await Future.wait([
      widget.api.get('/goleiros/${widget.goalkeeper.id}'),
      widget.api.list('/goleiros/${widget.goalkeeper.id}/partidas'),
      widget.api.list('/goleiros/${widget.goalkeeper.id}/evolucao'),
    ]);
    final detail = results[0] is Map ? Goalkeeper.fromJson(Map<String, dynamic>.from(results[0] as Map)) : widget.goalkeeper;
    final matches = (results[1] as List).map(GoalkeeperMatch.fromJson).toList();
    final evolution = (results[2] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.goalkeeper});
  final Goalkeeper goalkeeper;
  @override
  Widget build(BuildContext context) => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 2.15, children: [
    _Stat(label: 'Jogos', value: '${goalkeeper.matches}'), _Stat(label: 'Vitórias', value: '${goalkeeper.wins}'),
    _Stat(label: 'Defesas', value: '${goalkeeper.saves}'), _Stat(label: 'Gols sofridos', value: '${goalkeeper.goalsConceded}'),
    _Stat(label: 'Média sofrida', value: goalkeeper.concededAverage.toStringAsFixed(2)), _Stat(label: 'Aproveitamento', value: '${goalkeeper.winRate.toStringAsFixed(1)}%'),
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
