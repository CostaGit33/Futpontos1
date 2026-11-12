import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/api_client.dart';
import 'core/app_theme.dart';
import 'data/player.dart';
import 'data/history.dart';
import 'pages/history_page.dart';
import 'pages/goalkeepers_page.dart';
import 'pages/players_page.dart';
import 'pages/auth_page.dart';
import 'services/auth_service.dart';

void main() => runApp(const FutPontosApp());

class FutPontosApp extends StatelessWidget {
  const FutPontosApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FutPontos',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: const AuthGate(),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ApiClient api = ApiClient();
  late final AuthService auth = AuthService(api);
  late final Future<bool> restored = auth.restoreSession();
  bool? signedIn;

  Future<void> _logout() async {
    try { await auth.logout(); } catch (_) {}
    if (mounted) {
      setState(() => signedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (signedIn == true) return AppHome(api: api, onLogout: _logout);
    if (signedIn == false) {
      return AuthPage(api: api, onAuthenticated: () {
        setState(() => signedIn = true);
      });
    }
    return FutureBuilder<bool>(
      future: restored,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && signedIn == null) setState(() => signedIn = snapshot.data);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class AppHome extends StatefulWidget {
  const AppHome({super.key, required this.api, required this.onLogout});
  final ApiClient api;
  final VoidCallback onLogout;
  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  int selected = 0;
  int _refreshVersion = 0;
  late final ApiClient api = widget.api;

  static const labels = ['Início', 'Classificação', 'Jogadores', 'Goleiros', 'Histórico', 'Mais'];
  static const icons = [
    Icons.space_dashboard_outlined, Icons.leaderboard_outlined,
    Icons.groups_outlined, Icons.sports_handball_outlined, Icons.insights_outlined, Icons.grid_view_outlined,
  ];

  void _selectTab(int value) {
    if (value == selected) {
      HapticFeedback.selectionClick();
      setState(() => _refreshVersion++);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => selected = value);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final pages = [
      DashboardPage(key: ValueKey('dashboard-$_refreshVersion'), api: api, onRanking: () => setState(() => selected = 1)),
      RankingPage(key: ValueKey('ranking-$_refreshVersion'), api: api),
      PlayersPage(
        key: ValueKey('players-$_refreshVersion'),
        loadPlayers: () async => (await api.list('/jogadores')).map((e) => Player.fromJson(e)).toList(),
        loadPlayerDetails: (id) async {
          final data = await api.get('/jogadores/$id');
          if (data is Map<String, dynamic>) return data;
          if (data is Map) return Map<String, dynamic>.from(data);
          throw const FormatException('Formato inválido no perfil individual da API.');
        },
        loadAssessments: () => api.list('/desempenho'),
      ),
      GoalkeepersPage(key: ValueKey('goalkeepers-$_refreshVersion'), api: api),
      HistoryPage(key: ValueKey('history-$_refreshVersion'), api: api),
      InsightsPage(key: ValueKey('insights-$_refreshVersion'), api: api),
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
            tooltip: 'Sair da conta',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => setState(() => _refreshVersion++),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (wide) NavigationRail(
          selectedIndex: selected,
          onDestinationSelected: _selectTab,
          labelType: NavigationRailLabelType.all,
          destinations: [
            for (var i = 0; i < labels.length; i++)
              NavigationRailDestination(icon: Icon(icons[i]), label: Text(labels[i])),
          ],
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < pages.length; i++)
                IgnorePointer(
                  ignoring: selected != i,
                  child: AnimatedOpacity(
                    opacity: selected == i ? 1 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSlide(
                      offset: selected == i ? Offset.zero : const Offset(0, .025),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: pages[i],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: _selectTab,
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
        final players = snapshot.data!.map((e) => Player.fromJson(e as Map<String, dynamic>)).toList()
          ..sort((a, b) {
            final points = b.points.compareTo(a.points);
            if (points != 0) return points;
            final wins = b.wins.compareTo(a.wins);
            if (wins != 0) return wins;
            final goals = b.goals.compareTo(a.goals);
            return goals != 0 ? goals : a.name.compareTo(b.name);
          });
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
                  _Metric(label: 'Jogadores', value: '${players.length}', icon: Icons.groups_outlined),
                  _Metric(label: 'Pontos somados', value: '$sum', icon: Icons.bolt),
                  _ApiStatusMetric(api: widget.api),
                  _Metric(label: 'Ativos', value: '${players.where((p) => p.points != 0 || p.wins + p.goals + p.saves + p.draws + p.fouls > 0).length}', icon: Icons.query_stats),
                ],
              );
            }),
            const SizedBox(height: 24),
            _GoalkeeperHighlight(api: widget.api),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Destaques', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              TextButton(onPressed: widget.onRanking, child: const Text('Ver ranking')),
            ]),
            const SizedBox(height: 8),
            if (players.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Nenhum jogador cadastrado.')))
            else
              ...players.take(3).toList().asMap().entries.map((entry) =>
                _Entrance(
                  delay: Duration(milliseconds: 55 * entry.key),
                  child: _PlayerTile(position: entry.key + 1, player: entry.value),
                )),
          ],
        );
      },
    ),
  );
}

class _ApiStatusMetric extends StatelessWidget {
  const _ApiStatusMetric({required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: api.health(),
    builder: (context, snapshot) {
      final online = snapshot.hasData && snapshot.data?['status'] == 'ok';
      final checking = !snapshot.hasData && !snapshot.hasError;
      final label = checking ? 'Verificando' : online ? 'Online' : 'Indisponível';
      return _Metric(
        label: 'API / banco',
        value: label,
        icon: online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
      );
    },
  );
}

class _GoalkeeperHighlight extends StatelessWidget {
  const _GoalkeeperHighlight({required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: api.list('/goleiros'),
    builder: (context, snapshot) {
      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
        return const SizedBox.shrink();
      }
      final keepers = snapshot.data!.map((item) {
        int number(String key) => int.tryParse('${item[key] ?? 0}') ?? 0;
        return _KeeperSummary(
          name: (item['nome'] ?? 'Goleiro').toString(),
          photo: resolvePlayerPhoto(item['foto']) ?? resolvePlayerPhoto(item['foto_url']),
          points: number('pontos'),
          saves: number('defesas') == 0 ? number('defesa') : number('defesas'),
          conceded: number('gols_sofridos'),
        );
      }).toList()..sort((a, b) {
        final points = b.points.compareTo(a.points);
        return points != 0 ? points : b.saves.compareTo(a.saves);
      });
      final best = keepers.first;
      return Card(child: ListTile(
        leading: PlayerAvatar(photo: best.photo, radius: 24,
          fallback: const Icon(Icons.sports_handball, color: AppColors.gold)),
        title: const Text('Destaque dos goleiros', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${best.name} • ${best.saves} defesas • ${best.conceded} gols sofridos'),
        trailing: Text('${best.points} pts', style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)),
      ));
    },
  );
}

class _KeeperSummary {
  const _KeeperSummary({required this.name, required this.photo, required this.points, required this.saves, required this.conceded});
  final String name;
  final String? photo;
  final int points, saves, conceded;
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
                _Entrance(
                  delay: Duration(milliseconds: 35 * entry.key),
                  child: _PlayerTile(position: entry.key + 1, player: entry.value, detailed: true),
                )),
          ],
        ),
      );
    },
  );
}

class _Entrance extends StatefulWidget {
  const _Entrance({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, .10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
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
      if (int.tryParse(value) case final number?)
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: number.toDouble()),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => Text(
            animated.round().toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        )
      else
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            value,
            key: ValueKey(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
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
      leading: PlayerAvatar(
        photo: player.photo,
        radius: 20,
        fallback: Text('#$position', style: TextStyle(
          fontWeight: FontWeight.w900,
          color: position <= 3 ? AppColors.gold : Colors.white,
        )),
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

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late Future<List<Player>> _players;
  @override
  void initState() {
    super.initState();
    _players = _load();
  }

  Future<List<Player>> _load() async =>
      (await widget.api.list('/jogadores')).map(Player.fromJson).toList();

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _players = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Player>>(
    future: _players,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: _ErrorCard(message: snapshot.error.toString(), onRetry: _refresh));
      }
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final players = snapshot.data!;
      final byPoints = players.toList()..sort((a, b) => b.points.compareTo(a.points));
      final byGoals = players.toList()..sort((a, b) => b.goals.compareTo(a.goals));
      final bySaves = players.toList()..sort((a, b) => b.saves.compareTo(a.saves));
      final byWins = players.toList()..sort((a, b) => b.wins.compareTo(a.wins));
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Text('CENTRAL DE DESEMPENHO', style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.redLight, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text('Estatísticas e destaques', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text('Indicadores calculados a partir dos registros da competência atual.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            _Entrance(delay: const Duration(milliseconds: 0), child: _InsightTile(title: 'Pontuador', player: byPoints.isEmpty ? null : byPoints.first, value: (p) => '${p.points} pontos', icon: Icons.bolt)),
            _Entrance(delay: const Duration(milliseconds: 55), child: _InsightTile(title: 'Artilheiro', player: byGoals.isEmpty || byGoals.first.goals == 0 ? null : byGoals.first, value: (p) => '${p.goals} gols', icon: Icons.sports_soccer)),
            _Entrance(delay: const Duration(milliseconds: 110), child: _InsightTile(title: 'Mais defesas', player: bySaves.isEmpty || bySaves.first.saves == 0 ? null : bySaves.first, value: (p) => '${p.saves} defesas', icon: Icons.shield_outlined)),
            _Entrance(delay: const Duration(milliseconds: 165), child: _InsightTile(title: 'Mais vitórias', player: byWins.isEmpty || byWins.first.wins == 0 ? null : byWins.first, value: (p) => '${p.wins} vitórias', icon: Icons.emoji_events_outlined)),
            const Text('Comparar jogadores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            _PlayerComparison(players: players),
            const SizedBox(height: 14),
            _MonthlyPointsComparison(api: widget.api),
            const SizedBox(height: 16),
            const Text('Critérios', style: TextStyle(fontWeight: FontWeight.w900)),
            const Text('Os destaques usam apenas números retornados pela API. Empates são mantidos como destaques equivalentes na ordenação; nenhum dado é estimado.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      );
    },
  );
}

class _PlayerComparison extends StatefulWidget {
  const _PlayerComparison({required this.players});
  final List<Player> players;
  @override
  State<_PlayerComparison> createState() => _PlayerComparisonState();
}

class _PlayerComparisonState extends State<_PlayerComparison> {
  int? _firstId;
  int? _secondId;

  @override
  void didUpdateWidget(covariant _PlayerComparison oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.players.map((p) => p.id).toSet();
    if (_firstId == null || !ids.contains(_firstId)) {
      _firstId = widget.players.isEmpty ? null : widget.players.first.id;
    }
    if (_secondId == null || !ids.contains(_secondId) || _secondId == _firstId) {
      _secondId = widget.players.length > 1 ? widget.players[1].id : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.length < 2) {
      return const Card(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('São necessários pelo menos dois jogadores para comparar.', style: TextStyle(color: AppColors.muted)),
      ));
    }
    final firstId = _firstId ?? widget.players.first.id;
    final secondId = _secondId ?? widget.players[1].id;
    final first = widget.players.firstWhere((p) => p.id == firstId, orElse: () => widget.players.first);
    final second = widget.players.firstWhere((p) => p.id == secondId, orElse: () => widget.players[1]);
    Widget selector(String label, int selected, ValueChanged<int?> onChanged) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        DropdownButton<int>(
          value: selected,
          isExpanded: true,
          items: widget.players.map((p) => DropdownMenuItem<int>(
            value: p.id,
            child: Text(p.name, overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
    final metrics = <(String, int, int)>[
      ('Pontos', first.points, second.points),
      ('Vitórias', first.wins, second.wins),
      ('Gols', first.goals, second.goals),
      ('Defesas', first.saves, second.saves),
      ('Empates', first.draws, second.draws),
      ('Infrações', first.fouls, second.fouls),
    ];
    return Card(child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: selector('Jogador A', first.id, (value) {
            if (value != null) {
              setState(() {
                HapticFeedback.selectionClick();
                _firstId = value;
                if (_secondId == value) {
                  _secondId = widget.players.firstWhere((p) => p.id != value).id;
                }
              });
            }
          })),
          const SizedBox(width: 12),
          Expanded(child: selector('Jogador B', second.id, (value) {
            if (value != null) {
              setState(() {
                HapticFeedback.selectionClick();
                _secondId = value;
                if (_firstId == value) {
                  _firstId = widget.players.firstWhere((p) => p.id != value).id;
                }
              });
            }
          })),
        ]),
        const Divider(),
        ...metrics.map((metric) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(child: Text(metric.$1, style: const TextStyle(fontWeight: FontWeight.w700))),
            SizedBox(width: 42, child: Text('${metric.$2}', textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w900, color: metric.$2 >= metric.$3 ? AppColors.gold : AppColors.muted))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('×', style: TextStyle(color: AppColors.muted))),
            SizedBox(width: 42, child: Text('${metric.$3}', textAlign: TextAlign.start,
              style: TextStyle(fontWeight: FontWeight.w900, color: metric.$3 >= metric.$2 ? AppColors.gold : AppColors.muted))),
          ]),
        )),
        const SizedBox(height: 4),
        const Text('Comparação restrita aos números da competência atual.', style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ]),
    ));
  }
}

class _MonthlyPointsComparison extends StatefulWidget {
  const _MonthlyPointsComparison({required this.api});
  final ApiClient api;

  @override
  State<_MonthlyPointsComparison> createState() => _MonthlyPointsComparisonState();
}

class _MonthlyPointsComparisonState extends State<_MonthlyPointsComparison> {
  late Future<HistoryCollection> _history;

  @override
  void initState() {
    super.initState();
    _history = HistoryCollection.load(widget.api);
  }

  Future<void> _reload() async {
    final next = HistoryCollection.load(widget.api);
    setState(() => _history = next);
    try {
      await next;
    } catch (_) {}
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    const names = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    if (year == null || month == null || month < 1 || month > 12) return key;
    return '${names[month - 1]}/$year';
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<HistoryCollection>(
    future: _history,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pontuação total por mês', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Não foi possível carregar o histórico mensal.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            Align(alignment: Alignment.centerRight, child: TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Tentar novamente'),
            )),
          ]),
        ));
      }
      if (!snapshot.hasData) {
        return const Card(child: Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator()),
        ));
      }

      final totals = <String, int>{};
      for (final season in snapshot.data!.seasons) {
        final key = season.competition.key;
        final points = season.ranking.fold<int>(0, (sum, player) => sum + player.points);
        totals.update(key, (value) => value + points, ifAbsent: () => points);
      }
      final months = totals.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final maxPoints = months.fold<int>(1, (max, item) => item.value > max ? item.value : max);

      return Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Pontuação total por mês', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
            IconButton(
              tooltip: 'Atualizar histórico mensal',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded, size: 19),
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const Text('Soma dos pontos de todos os jogadores em cada mês.', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 14),
          if (months.isEmpty)
            const Text('Ainda não há competências com pontuação registrada.', style: TextStyle(color: AppColors.muted, fontSize: 12))
          else
            ...months.asMap().entries.map((entry) {
              final index = entry.key;
              final month = entry.value;
              final previous = index > 0 ? months[index - 1].value : null;
              final difference = previous == null ? null : month.value - previous;
              final comparison = difference == null
                  ? 'Primeiro mês'
                  : difference > 0
                      ? '+$difference pts vs. mês anterior'
                      : difference < 0
                          ? '$difference pts vs. mês anterior'
                          : 'Mesmo total do mês anterior';
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(_monthLabel(month.key), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                    Text('${month.value} pts', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.redLight, fontSize: 12)),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: (month.value / maxPoints).clamp(0, 1).toDouble(),
                      minHeight: 8,
                      backgroundColor: AppColors.raised,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(comparison, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                ]),
              );
            }),
          if (snapshot.data!.failedCompetitions.isNotEmpty)
            Text(
              'Atenção: ${snapshot.data!.failedCompetitions.length} competência(s) não puderam ser incluídas.',
              style: const TextStyle(color: AppColors.gold, fontSize: 11),
            ),
        ]),
      ));
    },
  );
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.title, required this.player, required this.value, required this.icon});
  final String title;
  final Player? player;
  final String Function(Player) value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: Icon(icon, color: AppColors.redLight),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(player == null ? 'Sem registros' : player!.name),
    trailing: player == null ? null : Text(value(player!), style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)),
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
