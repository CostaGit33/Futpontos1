import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/app_theme.dart';
import 'data/player.dart';

void main() => runApp(const FutPontosApp());

class FutPontosApp extends StatelessWidget {
  const FutPontosApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FutPontos',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: const AppHome(),
  );
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});
  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  int selected = 0;
  final api = ApiClient();

  static const labels = ['Início', 'Classificação', 'Jogadores', 'Desempenho', 'Mais'];
  static const icons = [
    Icons.space_dashboard_outlined, Icons.leaderboard_outlined,
    Icons.groups_outlined, Icons.insights_outlined, Icons.grid_view_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final pages = [
      DashboardPage(api: api, onRanking: () => setState(() => selected = 1)),
      RankingPage(api: api),
      const PlaceholderPage(title: 'Jogadores', detail: 'Migração dos perfis em andamento.', icon: Icons.groups_2_outlined),
      const PlaceholderPage(title: 'Desempenho', detail: 'Estatísticas e avaliações técnicas serão integradas nesta seção.', icon: Icons.query_stats),
      const PlaceholderPage(title: 'Mais funcionalidades', detail: 'Goleiros, competições, vídeos e montagem de times.', icon: Icons.apps),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.blue, AppColors.red]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_soccer, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('FUTPONTOS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (wide) NavigationRail(
          selectedIndex: selected,
          onDestinationSelected: (value) => setState(() => selected = value),
          labelType: NavigationRailLabelType.all,
          destinations: [
            for (var i = 0; i < labels.length; i++)
              NavigationRailDestination(icon: Icon(icons[i]), label: Text(labels[i])),
          ],
        ),
        Expanded(child: IndexedStack(index: selected, children: pages)),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (value) => setState(() => selected = value),
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.api, required this.onRanking});
  final ApiClient api;
  final VoidCallback onRanking;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<dynamic>> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.list('/jogadores');
  }

  Future<void> refresh() async {
    setState(() => future = widget.api.list('/jogadores'));
    await future;
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: refresh,
    child: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListView(padding: const EdgeInsets.all(22), children: [
            const _Intro(),
            const SizedBox(height: 24),
            _ErrorCard(message: snapshot.error.toString(), onRetry: refresh),
          ]);
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final players = snapshot.data!.map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();
        final sum = players.fold<int>(0, (total, player) => total + player.points);
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _Intro(),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue, Color(0xFF151B29), AppColors.red],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Icon(Icons.emoji_events_outlined, size: 36),
                SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FUTPONTOS • TEMPORADA', style: TextStyle(fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('O desempenho em campo, em números.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ])),
              ]),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, box) {
              final count = box.maxWidth > 620 ? 4 : 2;
              return GridView.count(
                crossAxisCount: count, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10, mainAxisSpacing: 10,
                childAspectRatio: count == 4 ? 1.7 : 1.45,
                children: [
                  const _Metric(label: 'Jogadores', value: '${players.length}', icon: Icons.groups_outlined),
                  const _Metric(label: 'Pontos somados', value: '$sum', icon: Icons.bolt),
                  const _Metric(label: 'API', value: 'Online', icon: Icons.cloud_done_outlined),
                  const _Metric(label: 'Ranking', value: 'Atual', icon: Icons.leaderboard_outlined),
                ],
              );
            }),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Destaques', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              TextButton(onPressed: widget.onRanking, child: const Text('Ver ranking')),
            ]),
            const SizedBox(height: 8),
            if (players.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Nenhum jogador cadastrado.')))
            else
              ...players.take(3).toList().asMap().entries.map((entry) =>
                _PlayerTile(position: entry.key + 1, player: entry.value)),
          ],
        );
      },
    ),
  );
}

class RankingPage extends StatefulWidget {
  const RankingPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  late Future<List<dynamic>> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.list('/jogadores');
  }

  Future<void> refresh() async {
    setState(() => future = widget.api.list('/jogadores'));
    await future;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: _ErrorCard(message: snapshot.error.toString(), onRetry: refresh));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final players = snapshot.data!.map((e) => Player.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.points.compareTo(a.points));
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text('CLASSIFICAÇÃO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.redLight, letterSpacing: 2, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Ranking geral', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text('Pontuação da competência atual.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            if (players.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Nenhum jogador cadastrado.')))
            else
              ...players.asMap().entries.map((entry) =>
                _PlayerTile(position: entry.key + 1, player: entry.value, detailed: true)),
          ],
        ),
      );
    },
  );
}

class _Intro extends StatelessWidget {
  const _Intro();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('PAINEL DO FUTEBOL', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.redLight, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 7),
    Text('Acompanhe o jogo.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 5),
    const Text('Estatísticas, evolução e classificação em um só lugar.', style: TextStyle(color: AppColors.muted)),
  ]);
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(13),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: AppColors.redLight, size: 20),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
    ]),
  ));
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.position, required this.player, this.detailed = false});
  final int position;
  final Player player;
  final bool detailed;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: AppColors.raised,
        backgroundImage: player.photo == null || player.photo!.isEmpty ? null : NetworkImage(player.photo!),
        child: player.photo == null || player.photo!.isEmpty
          ? Text('#$position', style: TextStyle(fontWeight: FontWeight.w900, color: position <= 3 ? AppColors.gold : Colors.white))
          : null,
      ),
      title: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: detailed ? Text('V ${player.wins}  •  G ${player.goals}  •  D ${player.saves}  •  E ${player.draws}  •  I ${player.fouls}', style: const TextStyle(color: AppColors.muted, fontSize: 11)) : null,
      trailing: Text('${player.points} pts', style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.cloud_off_outlined, color: AppColors.redLight, size: 30),
      const SizedBox(height: 10),
      const Text('Não foi possível carregar os dados.', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(message, style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
    ]),
  ));
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.detail, required this.icon});
  final String title, detail;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 54, color: AppColors.muted),
      const SizedBox(height: 14),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
    ]),
  ));
}
