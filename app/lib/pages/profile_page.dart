import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../core/analytics.dart';
import '../data/goalkeeper.dart';
import '../data/history.dart';
import '../data/player.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.api, required this.onLogout});
  final ApiClient api;
  final VoidCallback onLogout;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> future;
  final ImagePicker _picker = ImagePicker();
  bool _photoBusy = false;
  String? _photoOverride;
  @override
  void initState() { super.initState(); future = _load(); }

  Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  Future<Map<String, dynamic>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('futpontos_auth_token');
    if (token == null || token.isEmpty) throw Exception('Sessão não encontrada. Entre novamente.');
    final session = await widget.api.authMe(token);
    final user = _map(session['user']);
    final rawLinks = session['vinculos'];
    final links = rawLinks is List ? rawLinks.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    Map<String, dynamic>? link;
    for (final item in links) { if (item['status'] == 'approved') { link = item; break; } }
    link ??= links.isEmpty ? null : links.first;
    final result = <String, dynamic>{'user': user, 'link': link};
    if (link == null || link['status'] != 'approved') return result;
    final id = int.tryParse(link['profile_id'].toString()) ?? 0;
    if (id <= 0) return result;
    if (link['profile_type'] == 'jogador') {
      final values = await Future.wait<dynamic>([
        widget.api.get('/jogadores/' + id.toString()),
        HistoryCollection.load(widget.api),
        widget.api.list('/desempenho'),
      ]);
      result['player'] = Player.fromJson(_map(values[0]));
      result['history'] = (values[1] as HistoryCollection).historyFor(id);
      final records = values[2] as List<Map<String, dynamic>>;
      for (final row in records) {
        if (row['id'].toString() == id.toString() && row['avaliacao'] is Map) {
          final raw = row['avaliacao'] as Map;
          const keys = ['defesa', 'ataque', 'velocidade', 'habilidade', 'passe'];
          final values = keys.map((k) => double.tryParse(raw[k].toString())).toList();
          if (values.every((v) => v != null)) result['assessment'] = values.cast<double>();
          break;
        }
      }
    } else if (link['profile_type'] == 'goleiro') {
      final values = await Future.wait<dynamic>([
        widget.api.get('/goleiros/' + id.toString()),
        widget.api.list('/goleiros/' + id.toString() + '/partidas'),
        widget.api.list('/goleiros/' + id.toString() + '/evolucao'),
      ]);
      result['goalkeeper'] = Goalkeeper.fromJson(_map(values[0]));
      result['matches'] = (values[1] as List<Map<String, dynamic>>).map(GoalkeeperMatch.fromJson).toList();
      result['history'] = values[2];
    }
    return result;
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() { future = f; _photoOverride = null; });
    await f;
  }

  Future<void> _changePhoto(Map<String, dynamic> link) async {
    if (_photoBusy || link['status'] != 'approved') return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(child: Wrap(children: [
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Galeria'),
          onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Câmera'),
          onTap: () => Navigator.pop(context, ImageSource.camera)),
      ])),
    );
    if (source == null || !mounted) return;
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1400);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) throw Exception('A imagem deve ter no máximo 5 MB.');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('futpontos_auth_token');
      if (token == null || token.isEmpty) throw Exception('Sessão expirada. Entre novamente.');
      setState(() => _photoBusy = true);
      final id = int.tryParse(link['profile_id'].toString()) ?? 0;
      final result = link['profile_type'] == 'goleiro'
          ? await widget.api.uploadGoalkeeperPhoto(goalkeeperId: id, bytes: bytes, filename: image.name, token: token)
          : await widget.api.uploadPlayerPhoto(playerId: id, bytes: bytes, filename: image.name, token: token);
      if (!mounted) return;
      setState(() => _photoOverride = resolvePlayerPhoto(result['foto']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _editAccount(Map<String, dynamic> user) async {
    final name = TextEditingController(text: user['nome']?.toString() ?? '');
    final oldPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirm = TextEditingController();
    var changePassword = false;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Configurações da conta'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome de exibição')),
            const SizedBox(height: 8),
            Text('E-mail: ' + (user['email']?.toString() ?? '—'),
                style: const TextStyle(color: AppColors.muted)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Alterar senha'),
              value: changePassword,
              onChanged: (value) => setDialogState(() => changePassword = value),
            ),
            if (changePassword) ...[
              TextField(controller: oldPassword, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha atual')),
              TextField(controller: newPassword, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova senha (mínimo 10 caracteres)')),
              TextField(controller: confirm, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar nova senha')),
            ],
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (save != true || !mounted) {
      name.dispose(); oldPassword.dispose(); newPassword.dispose(); confirm.dispose();
      return;
    }
    try {
      final body = <String, dynamic>{'nome': name.text.trim()};
      if (changePassword) {
        if (newPassword.text.length < 10) throw Exception('A nova senha deve ter pelo menos 10 caracteres.');
        if (newPassword.text != confirm.text) throw Exception('As senhas novas não coincidem.');
        body['senha_atual'] = oldPassword.text;
        body['nova_senha'] = newPassword.text;
      }
      await widget.api.patch('/auth/profile', body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações atualizadas com sucesso.')),
        );
        await _refresh();
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      name.dispose(); oldPassword.dispose(); newPassword.dispose(); confirm.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meu perfil'), actions: [
      IconButton(onPressed: _refresh, tooltip: 'Atualizar', icon: const Icon(Icons.refresh)),
    ]),
    body: FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, s) {
        if (s.hasError) return Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(s.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _refresh, child: const Text('Tentar novamente')),
          ]),
        ));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final d = s.data!;
        final user = _map(d['user']);
        final p = d['player'] as Player?;
        final g = d['goalkeeper'] as Goalkeeper?;
        final link = d['link'] as Map<String, dynamic>?;
        return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: ListTile(
            leading: Stack(clipBehavior: Clip.none, children: [
              PlayerAvatar(photo: _photoOverride ?? p?.photo ?? g?.photo, radius: 30,
                fallback: const Icon(Icons.person_outline, size: 30)),
              if (link?['status'] == 'approved')
                Positioned(right: -8, bottom: -8, child: _photoBusy
                  ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Alterar foto',
                      onPressed: () => _changePhoto(link!),
                      icon: const Icon(Icons.camera_alt_outlined, size: 15),
                    )),
            ]),
            title: Text(user['nome']?.toString() ?? 'Minha conta', style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(user['email']?.toString() ?? '—'),
            trailing: Text(p != null ? 'JOGADOR' : g != null ? 'GOLEIRO' : 'CONTA',
                style: const TextStyle(color: AppColors.redLight, fontSize: 10, fontWeight: FontWeight.w900)),
          )),
          const SizedBox(height: 14),
          if (link == null || link['status'] != 'approved')
            _Notice(link: link)
          else if (p != null)
            _PlayerData(player: p, history: (d['history'] as List<Player>?) ?? [], assessment: d['assessment'] as List<double>?)
          else if (g != null)
            _GoalkeeperData(goalkeeper: g, history: (d['history'] as List<Map<String, dynamic>>?) ?? [],
              matches: (d['matches'] as List<GoalkeeperMatch>?) ?? [])
          else
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Não foi possível carregar os dados esportivos.'))),
          const SizedBox(height: 14),
          Card(child: Column(children: [
            ListTile(leading: const Icon(Icons.manage_accounts_outlined), title: const Text('Configurações da conta'),
              subtitle: const Text('Editar nome de exibição e alterar senha'), trailing: const Icon(Icons.chevron_right),
              onTap: () => _editAccount(user)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.verified_user_outlined), title: const Text('Vínculo esportivo'),
              subtitle: Text(_linkText(link))),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.logout, color: AppColors.redLight),
              title: const Text('Sair da conta'), textColor: AppColors.redLight, onTap: widget.onLogout),
          ])),
          const SizedBox(height: 12),
          const Text('As estatísticas são carregadas dos registros oficiais da API.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ]));
      },
    ),
  );

  String _linkText(Map<String, dynamic>? link) {
    if (link == null) return 'Nenhum perfil vinculado';
    final kind = link['profile_type'] == 'goleiro' ? 'Goleiro' : 'Jogador';
    final status = link['status'] == 'approved' ? 'Aprovado' : link['status'] == 'pending' ? 'Pendente' : 'Rejeitado';
    return kind + ' #' + link['profile_id'].toString() + ' • ' + status;
  }
}

class _Notice extends StatelessWidget {
  const _Notice({this.link});
  final Map<String, dynamic>? link;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(
    link?['status'] == 'pending' ? 'Vínculo aguardando aprovação. As estatísticas aparecerão após a aprovação da comissão.' :
    link?['status'] == 'rejected' ? 'Vínculo não aprovado. Procure a organização para verificar a solicitação.' :
    'Sua conta ainda não possui um perfil esportivo vinculado.',
  )));
}

class _PlayerData extends StatelessWidget {
  const _PlayerData({required this.player, required this.history, this.assessment});
  final Player player;
  final List<Player> history;
  final List<double>? assessment;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _Heading('Desempenho atual'),
    _Stats(items: [('Pontos', player.points), ('Vitórias', player.wins), ('Gols', player.goals),
      ('Defesas', player.saves), ('Empates', player.draws), ('Infrações', player.fouls)]),
    const SizedBox(height: 14),
    const _Heading('Evolução mensal'),
    _History(labels: history.map((e) => e.name).toList(), values: history.map((e) => e.points.toDouble()).toList()),
    const SizedBox(height: 14),
    const _Heading('Avaliação técnica • 0 a 20'),
    _Assessment(values: assessment),
    const SizedBox(height: 14),
    const _Heading('Conquistas'),
    _Awards(items: achievementsFor(player).map((a) => (a.icon, a.title, a.description, a.progress, a.target, a.unlocked)).toList()),
  ]);
}

class _GoalkeeperData extends StatelessWidget {
  const _GoalkeeperData({required this.goalkeeper, required this.history, required this.matches});
  final Goalkeeper goalkeeper;
  final List<Map<String, dynamic>> history;
  final List<GoalkeeperMatch> matches;
  @override
  Widget build(BuildContext context) {
    final g = goalkeeper;
    final awards = <(String, String, String, int, int, bool)>[
      ('🧤', 'Primeira muralha', '10 defesas', g.saves, 10, g.saves >= 10),
      ('🧱', 'Paredão', '25 defesas', g.saves, 25, g.saves >= 25),
      ('🏆', 'Vitórias', '5 vitórias', g.wins, 5, g.wins >= 5),
      ('⭐', 'Experiente', '10 partidas', g.matches, 10, g.matches >= 10),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Heading('Desempenho atual'),
      _Stats(items: [('Pontos', g.points), ('Jogos', g.matches), ('Vitórias', g.wins),
        ('Defesas', g.saves), ('Gols sofridos', g.goalsConceded), ('Derrotas', g.losses)]),
      const SizedBox(height: 14),
      const _Heading('Médias'),
      _Stats(items: [('Defesas/jogo', g.matches == 0 ? '0' : (g.saves / g.matches).toStringAsFixed(1)),
        ('Gols sofridos/jogo', g.concededAverage.toStringAsFixed(2)), ('Aproveitamento', g.winRate.toStringAsFixed(1) + '%')]),
      const SizedBox(height: 14),
      const _Heading('Evolução mensal'),
      _History(labels: history.map((e) => e['nome']?.toString() ?? e['chave']?.toString() ?? 'Competência').toList(),
        values: history.map((e) => double.tryParse(e['pontos'].toString()) ?? 0).toList()),
      const SizedBox(height: 14),
      const _Heading('Avaliação técnica • 0 a 20'),
      _Assessment(values: g.assessment),
      const SizedBox(height: 14),
      const _Heading('Conquistas'),
      _Awards(items: awards),
      const SizedBox(height: 14),
      const _Heading('Partidas recentes'),
      if (matches.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Nenhuma partida registrada.')))
      else Card(child: Column(children: matches.take(8).map((m) => ListTile(dense: true,
        leading: Icon(m.result == 'vitoria' ? Icons.check_circle : m.result == 'derrota' ? Icons.cancel : Icons.handshake),
        title: Text(m.result.toUpperCase()),
        subtitle: Text(m.saves.toString() + ' defesas • ' + m.goalsConceded.toString() + ' gols sofridos'),
        trailing: Text(m.points.toString() + ' pts'))).toList())),
    ]);
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(), style: const TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900)));
}

class _Stats extends StatelessWidget {
  const _Stats({required this.items});
  final List<(String, Object)> items;
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 7, crossAxisSpacing: 7, childAspectRatio: 1.25,
    children: items.map((e) => Card(child: Padding(padding: const EdgeInsets.all(8),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(e.$2.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(e.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ])))).toList(),
  );
}

class _History extends StatelessWidget {
  const _History({required this.labels, required this.values});
  final List<String> labels;
  final List<double> values;
  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Ainda não há histórico mensal.')));
    final max = values.fold<double>(0, (a, b) => a > b ? a : b);
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: List.generate(values.length, (i) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Column(children: [
        Row(children: [Expanded(child: Text(labels[i])), Text(values[i].toStringAsFixed(0) + ' pts')]),
        LinearProgressIndicator(value: max <= 0 ? 0 : (values[i] / max).clamp(0.0, 1.0)),
      ]))))));
  }
}

class _Assessment extends StatelessWidget {
  const _Assessment({this.values});
  final List<double>? values;
  @override
  Widget build(BuildContext context) {
    if (values == null || values!.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Sem avaliação técnica cadastrada.')));
    const labels = ['Defesa', 'Ataque', 'Velocidade', 'Habilidade', 'Passe'];
    final average = values!.reduce((a, b) => a + b) / values!.length;
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
      Text('Média técnica: ' + average.toStringAsFixed(1) + '/20'),
      ...List.generate(values!.length, (i) => Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(labels[i]), Text(values![i].toStringAsFixed(1))]),
        LinearProgressIndicator(value: (values![i] / 20).clamp(0.0, 1.0)),
      ])),
    ])));
  }
}

class _Awards extends StatelessWidget {
  const _Awards({required this.items});
  final List<(String, String, String, int, int, bool)> items;
  @override
  Widget build(BuildContext context) {
    final count = items.where((e) => e.$6).length;
    return Card(child: Column(children: [
      ListTile(title: const Text('Conquistas desbloqueadas'), trailing: Text(count.toString() + '/' + items.length.toString())),
      ...items.map((e) => ListTile(dense: true, leading: Text(e.$1, style: const TextStyle(fontSize: 20)),
        title: Text(e.$2), subtitle: Text(e.$3 + ' • ' + e.$4.toString() + '/' + e.$5.toString()),
        trailing: Icon(e.$6 ? Icons.check_circle : Icons.lock_outline, color: e.$6 ? AppColors.gold : AppColors.muted))),
    ]));
  }
}
