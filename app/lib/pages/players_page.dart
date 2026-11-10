import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/analytics.dart';
import '../data/player.dart';

/// Avaliação técnica manual realizada em campo. Escala original: 0 a 20.
/// A associação é pelo nome exato, como no cadastro manual do PWA.
const Map<String, List<int>> _manualAssessments = {
  'Mikael': [5, 11, 0, 5, 9],
  'Henrique Noronha': [14, 4, 1, 3, 17],
  'Alex': [2, 16, 10, 13, 13],
  'Victor': [3, 11, 17, 11, 10],
  'Jhon100%': [2, 15, 1, 2, 5],
  'Israel': [2, 0, 5, 16, 15],
  'Fernando': [0, 17, 8, 13, 11],
  'Eric': [4, 13, 12, 11, 7],
  'Rai Ortiz': [15, 0, 0, 0, 0],
  'Beninha': [10, 3, 0, 1, 2],
  'Marcão': [17, 0, 1, 8, 14],
  'Maicon': [9, 16, 14, 14, 9],
  'Joel': [16, 1, 8, 1, 6],
  'Kaio Kros': [12, 0, 2, 1, 7],
  'Theu': [6, 18, 16, 5, 5],
  'Fabio': [17, 0, 1, 2, 10],
  'Henrique Barbeiro': [10, 12, 1, 9, 9],
  'Pedro Uggere': [19, 0, 6, 11, 13],
  'Savio': [16, 2, 7, 1, 6],
  'Adailson': [12, 1, 2, 2, 0],
  'Hélio Júnior': [1, 5, 0, 7, 4],
  'Jadson': [2, 3, 3, 6, 10],
  'Samuel': [0, 5, 2, 13, 11],
  'uilliam Peixe': [15, 5, 6, 15, 11],
  'Edmilson Novais': [8, 3, 14, 7, 2],
  'Edmilson Pereira': [16, 0, 1, 1, 7],
  'DN': [2, 11, 5, 3, 3],
  'Hudson': [16, 0, 0, 3, 14],
  'Bicudo': [17, 0, 2, 2, 12],
  'João B.': [16, 7, 12, 4, 4],
  'Henrigol': [0, 10, 7, 4, 9],
  'Guilherme': [7, 0, 9, 0, 0],
  'Wenderson': [0, 12, 12, 12, 9],
  'Arlley': [10, 5, 0, 0, 0],
  'Wendel': [2, 12, 2, 15, 15],
  'Thomas': [10, 10, 0, 4, 13],
  'Luis henrique': [10, 3, 1, 5, 10],
};

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key, required this.loadPlayers});
  final Future<List<Player>> Function() loadPlayers;

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  late Future<List<Player>> _future;
  String _query = '';
  String _sort = 'Pontos';

  @override
  void initState() {
    super.initState();
    _future = widget.loadPlayers();
  }

  Future<void> _refresh() async {
    final request = widget.loadPlayers();
    setState(() => _future = request);
    await request;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Player>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, color: AppColors.redLight, size: 38),
            const SizedBox(height: 10),
            const Text('Não foi possível carregar os jogadores.'),
            const SizedBox(height: 8),
            Text(snapshot.error.toString(), textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente')),
          ]),
        ));
      }
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final players = snapshot.data!.where((p) =>
        p.name.toLowerCase().contains(_query.trim().toLowerCase())).toList();
      int value(Player p) => switch (_sort) {
        'Gols' => p.goals,
        'Defesas' => p.saves,
        'Vitórias' => p.wins,
        _ => p.points,
      };
      players.sort((a, b) => value(b).compareTo(value(a)));
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Text('PLANTEL', style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.redLight, letterSpacing: 2, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Jogadores', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Buscar jogador',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['Pontos', 'Gols', 'Defesas', 'Vitórias'].map((item) =>
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(label: Text(item), selected: _sort == item,
                    onSelected: (_) => setState(() => _sort = item)),
                )).toList()),
            ),
            const SizedBox(height: 8),
            Text('${players.length} jogadores', style: const TextStyle(
              color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 8),
            if (players.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18),
                child: Text('Nenhum jogador encontrado.')))
            else
              ...players.asMap().entries.map((entry) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.raised,
                    backgroundImage: entry.value.photo == null || entry.value.photo!.isEmpty
                      ? null : NetworkImage(entry.value.photo!),
                    child: entry.value.photo == null || entry.value.photo!.isEmpty
                      ? Text('${entry.key + 1}') : null,
                  ),
                  title: Text(entry.value.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${entry.value.wins} vitórias • ${entry.value.goals} gols • ${entry.value.saves} defesas'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${entry.value.points}', style: const TextStyle(
                      color: AppColors.redLight, fontWeight: FontWeight.w900, fontSize: 17)),
                    const Text('PTS', style: TextStyle(fontSize: 9, color: AppColors.muted)),
                  ]),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PlayerProfilePage(player: entry.value)),
                  ),
                ),
              )),
          ],
        ),
      );
    },
  );
}

class PlayerProfilePage extends StatelessWidget {
  const PlayerProfilePage({super.key, required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final assessment = _manualAssessments[player.name];
    final achievements = achievementsFor(player);
    return Scaffold(
      appBar: AppBar(title: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              CircleAvatar(radius: 34,
                backgroundColor: AppColors.raised,
                backgroundImage: player.photo == null || player.photo!.isEmpty
                  ? null : NetworkImage(player.photo!),
                child: player.photo == null || player.photo!.isEmpty
                  ? const Icon(Icons.person, size: 34) : null),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(player.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text('${player.points} pontos • ${levelName(levelFor(player))}',
                  style: const TextStyle(color: AppColors.muted)),
              ])),
            ]),
          )),
          const SizedBox(height: 14),
          const Text('ESTATÍSTICAS DA COMPETÊNCIA', style: TextStyle(
            color: AppColors.redLight, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _ProfileMetric('Pontos', player.points),
            _ProfileMetric('Vitórias', player.wins),
            _ProfileMetric('Gols', player.goals),
            _ProfileMetric('Defesas', player.saves),
            _ProfileMetric('Empates', player.draws),
            _ProfileMetric('Infrações', player.fouls),
          ]),
          const SizedBox(height: 20),
          const Text('AVALIAÇÃO TÉCNICA DE CAMPO', style: TextStyle(
            color: AppColors.redLight, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          const Text('Avaliação individual cadastrada manualmente • escala de 0 a 20',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 10),
          if (assessment == null)
            const Card(child: Padding(padding: EdgeInsets.all(16),
              child: Text('Este jogador ainda não possui avaliação técnica manual cadastrada.')))
          else
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Média técnica', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text((assessment.reduce((a, b) => a + b) / assessment.length).toStringAsFixed(1) + '/20',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.redLight)),
                ]),
                const SizedBox(height: 12),
                ...List.generate(5, (i) => _AssessmentBar(
                  label: const ['Defesa', 'Ataque', 'Velocidade', 'Habilidade', 'Passe'][i],
                  score: assessment[i])),
              ]),
            )),
          const SizedBox(height: 20),
          const Text('CONQUISTAS', style: TextStyle(
            color: AppColors.redLight, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Card(child: Column(children: achievements.map((a) => ListTile(
            leading: Text(a.icon, style: const TextStyle(fontSize: 22)),
            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${a.description} • ${a.progress}/${a.target}'),
            trailing: Icon(a.unlocked ? Icons.check_circle : Icons.lock_outline,
              color: a.unlocked ? AppColors.gold : AppColors.muted),
          )).toList())),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppColors.raised, borderRadius: BorderRadius.circular(12)),
    child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class _AssessmentBar extends StatelessWidget {
  const _AssessmentBar({required this.label, required this.score});
  final String label;
  final int score;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label), Text('$score/20', style: const TextStyle(fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(value: (score / 20).clamp(0, 1).toDouble(),
          minHeight: 8, backgroundColor: AppColors.raised)),
    ]),
  );
}
