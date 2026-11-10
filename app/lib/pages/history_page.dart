// ignore_for_file: prefer_interpolation_to_compose_strings
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../data/analytics.dart';
import '../data/history.dart';
import '../data/player.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<HistoryCollection> _future;
  int? _selectedCompetitionId;
  int? _selectedPlayerId;
  bool _careerMode = false;

  @override
  void initState() {
    super.initState();
    _future = HistoryCollection.load(widget.api);
  }

  Future<void> _reload() async {
    final next = HistoryCollection.load(widget.api);
    setState(() => _future = next);
    try { await next; } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<HistoryCollection>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _HistoryError(message: snapshot.error.toString(), onRetry: _reload);
      }
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return _buildContent(context, snapshot.data!);
    },
  );

  Widget _buildContent(BuildContext context, HistoryCollection data) {
    if (data.seasons.isEmpty) {
      return _HistoryEmpty(onRetry: _reload);
    }
    SeasonData? chosen;
    for (final season in data.seasons) {
      if (season.competition.id == _selectedCompetitionId) chosen = season;
    }
    chosen ??= data.currentSeason ?? data.seasons.first;
    final career = data.careerPlayers;
    Player? selectedPlayer;
    for (final player in career) {
      if (player.id == _selectedPlayerId) selectedPlayer = player;
    }
    selectedPlayer ??= career.isEmpty ? null : career.first;
    final seasonStats = TeamStats(chosen.ranking);
    final careerStats = TeamStats(career);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          Text('CENTRAL HISTÓRICA', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.redLight, letterSpacing: 2, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text('A história do FutPontos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text('Resultados de competências encerradas, totais acumulados e evolução individual.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Competências'), selected: !_careerMode, onSelected: (_) => setState(() => _careerMode = false)),
            ChoiceChip(label: const Text('Carreira'), selected: _careerMode, onSelected: (_) => setState(() => _careerMode = true)),
          ]),
          const SizedBox(height: 14),
          if (data.failedCompetitions.isNotEmpty)
            Card(child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: AppColors.gold),
              title: const Text('Histórico parcial'),
              subtitle: Text(data.failedCompetitions.length.toString() + ' competência(s) não responderam. Puxe para atualizar.'),
            )),
          if (!_careerMode) ...[
            _CompetitionDropdown(
              seasons: data.seasons,
              selected: chosen.competition,
              onChanged: (id) => setState(() => _selectedCompetitionId = id),
            ),
            const SizedBox(height: 12),
            _Banner(competition: chosen.competition, players: chosen.ranking.length),
            const SizedBox(height: 12),
            _MetricGrid(items: [
              _MetricData('Pontos', seasonStats.totalPoints, Icons.bolt),
              _MetricData('Gols', seasonStats.totalGoals, Icons.sports_soccer),
              _MetricData('Vitórias', seasonStats.totalWins, Icons.emoji_events_outlined),
              _MetricData('Defesas', seasonStats.totalSaves, Icons.shield_outlined),
            ]),
            const SizedBox(height: 18),
            const Text('Ranking preservado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (chosen.ranking.isEmpty)
              const _EmptyMessage('Nenhum jogador foi registrado nesta competência.')
            else
              ..._sortedRanking(chosen.ranking).asMap().entries.map((entry) => _RankingTile(position: entry.key + 1, player: entry.value)),
          ] else ...[
            _MetricGrid(items: [
              _MetricData('Pontos acumulados', careerStats.totalPoints, Icons.bolt),
              _MetricData('Gols', careerStats.totalGoals, Icons.sports_soccer),
              _MetricData('Vitórias', careerStats.totalWins, Icons.emoji_events_outlined),
              _MetricData('Defesas', careerStats.totalSaves, Icons.shield_outlined),
            ]),
            const SizedBox(height: 18),
            const Text('Ranking da carreira', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...career.asMap().entries.map((entry) => _CareerTile(position: entry.key + 1, player: entry.value)),
            if (selectedPlayer != null) ...[
              const SizedBox(height: 18),
              const Text('Evolução individual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              _PlayerDropdown(players: career, selected: selectedPlayer, onChanged: (id) => setState(() => _selectedPlayerId = id)),
              const SizedBox(height: 12),
              _CareerProfile(player: selectedPlayer, data: data),
            ],
          ],
          const SizedBox(height: 18),
          const Text('Como os números são calculados', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text('Os totais da carreira somam uma vez os registros de cada competência por jogador. Não são contadas partidas ou minutos, porque esses dados não existem na tabela histórica disponível.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

List<Player> _sortedRanking(List<Player> players) => players.toList()..sort((a, b) {
  final result = b.points.compareTo(a.points);
  if (result != 0) return result;
  final wins = b.wins.compareTo(a.wins);
  if (wins != 0) return wins;
  return b.goals.compareTo(a.goals);
});

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});
  final List<_MetricData> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final columns = box.maxWidth > 600 ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: items.map((item) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(item.icon, color: AppColors.redLight, size: 20),
            Text(item.value.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            Text(item.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ]),
        ),
      )).toList(),
    );
  });
}

class _CompetitionDropdown extends StatelessWidget {
  const _CompetitionDropdown({required this.seasons, required this.selected, required this.onChanged});
  final List<SeasonData> seasons;
  final Competition selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected.id, isExpanded: true,
          items: seasons.map((season) => DropdownMenuItem<int>(
            value: season.competition.id,
            child: Text(season.competition.name + (season.competition.isOpen ? ' • Aberta' : ' • Encerrada'), overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (value) { if (value != null) onChanged(value); },
        ),
      ),
    ),
  );
}

class _PlayerDropdown extends StatelessWidget {
  const _PlayerDropdown({required this.players, required this.selected, required this.onChanged});
  final List<Player> players;
  final Player selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected.id, isExpanded: true,
          items: players.map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name))).toList(),
          onChanged: (value) { if (value != null) onChanged(value); },
        ),
      ),
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.competition, required this.players});
  final Competition competition;
  final int players;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF151B29), AppColors.red]),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(children: [
      const Icon(Icons.emoji_events_outlined, size: 34),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(competition.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(players.toString() + ' jogadores • ' + (competition.isOpen ? 'Em andamento' : 'Encerrada'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
    ]),
  );
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.position, required this.player});
  final int position;
  final Player player;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 7),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: AppColors.raised, child: Text(position.toString(), style: TextStyle(color: position <= 3 ? AppColors.gold : Colors.white, fontWeight: FontWeight.w900))),
      title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('V ' + player.wins.toString() + ' • G ' + player.goals.toString() + ' • D ' + player.saves.toString() + ' • E ' + player.draws.toString() + ' • I ' + player.fouls.toString(), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      trailing: Text(player.points.toString() + ' pts', style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)),
    ),
  );
}

class _CareerTile extends StatelessWidget {
  const _CareerTile({required this.position, required this.player});
  final int position;
  final Player player;
  @override
  Widget build(BuildContext context) {
    final unlocked = achievementsFor(player).where((a) => a.unlocked).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.raised, child: Text(position.toString(), style: TextStyle(color: position <= 3 ? AppColors.gold : Colors.white, fontWeight: FontWeight.w900))),
        title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(levelName(levelFor(player)) + ' • ' + unlocked.toString() + ' medalhas', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        trailing: Text(player.points.toString() + ' pts', style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _CareerProfile extends StatelessWidget {
  const _CareerProfile({required this.player, required this.data});
  final Player player;
  final HistoryCollection data;
  @override
  Widget build(BuildContext context) {
    final chronological = data.seasons.reversed.toList();
    var maxPoints = 1;
    for (final season in chronological) {
      for (final p in season.ranking) { if (p.id == player.id && p.points > maxPoints) maxPoints = p.points; }
    }
    final bars = <Widget>[];
    for (final season in chronological) {
      for (final p in season.ranking) {
        if (p.id == player.id) {
          bars.add(_HistoryBar(label: season.competition.name, value: p.points, max: maxPoints));
          break;
        }
      }
    }
    final medals = achievementsFor(player);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(player.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          Text(player.points.toString() + ' pontos acumulados • ' + levelName(levelFor(player)), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(spacing: 7, runSpacing: 7, children: [
            _SmallMetric(label: 'Gols', value: player.goals),
            _SmallMetric(label: 'Vitórias', value: player.wins),
            _SmallMetric(label: 'Defesas', value: player.saves),
            _SmallMetric(label: 'Empates', value: player.draws),
            _SmallMetric(label: 'Infrações', value: player.fouls),
          ]),
          const SizedBox(height: 16),
          const Text('Pontos por competência', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (bars.isEmpty) const Text('Sem registros nas competências consultadas.') else ...bars,
          const SizedBox(height: 16),
          const Text('Conquistas', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          ...medals.map((a) => _MedalRow(item: a)),
        ]),
      ),
    );
  }
}

class _HistoryBar extends StatelessWidget {
  const _HistoryBar({required this.label, required this.value, required this.max});
  final String label;
  final int value, max;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 12))), Text(value.toString() + ' pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: max <= 0 ? 0 : (value / max).clamp(0, 1).toDouble(), minHeight: 7, backgroundColor: AppColors.raised)),
    ]),
  );
}

class _MedalRow extends StatelessWidget {
  const _MedalRow({required this.item});
  final Achievement item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(item.icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        Text(item.description, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: item.fraction, minHeight: 5)),
      ])),
      const SizedBox(width: 8),
      Icon(item.unlocked ? Icons.check_circle : Icons.lock_outline, color: item.unlocked ? AppColors.gold : AppColors.muted, size: 18),
    ]),
  );
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: AppColors.raised, borderRadius: BorderRadius.circular(10)), child: Text(label + ': ' + value.toString(), style: const TextStyle(fontSize: 11)));
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(message, style: const TextStyle(color: AppColors.muted))));
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(22), child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.cloud_off_outlined, color: AppColors.redLight, size: 30),
    const SizedBox(height: 10),
    const Text('Não foi possível consultar o histórico.', style: TextStyle(fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    Text(message, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
  ])))));
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.history, size: 48, color: AppColors.muted),
    const SizedBox(height: 12),
    const Text('Nenhuma competência histórica encontrada.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('Verifique se o Control já preservou competências fechadas e se a API consegue consultá-las.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Atualizar')),
  ])));
}