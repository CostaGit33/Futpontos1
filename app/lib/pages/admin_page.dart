
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<_AdminData> future;
  bool busy = false;
  @override
  void initState() { super.initState(); future = _load(); }
  Map<String, dynamic> map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  List<Map<String, dynamic>> rows(dynamic v, String key) {
    final raw = v is Map ? v[key] : v;
    return raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
  }
  Future<_AdminData> _load() async {
    final r = await Future.wait<dynamic>([
      widget.api.get('/admin/overview'), widget.api.get('/admin/users'),
      widget.api.get('/admin/links'), widget.api.get('/admin/audit'),
      widget.api.list('/jogadores'), widget.api.list('/goleiros'),
    ]);
    return _AdminData(map(r[0]), rows(r[1], 'usuarios'), rows(r[2], 'vinculos'),
      rows(r[3], 'registros'), r[4] as List<Map<String, dynamic>>, r[5] as List<Map<String, dynamic>>);
  }
  Future<void> refresh() async { final f = _load(); setState(() => future = f); await f; }
  Future<void> run(Future<dynamic> Function() action, String message) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<bool> confirm(String title, String message) async =>
    await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(title), content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmar')),
      ],
    )) ?? false;

  Future<void> decide(Map<String, dynamic> l, String value) async {
    if (!await confirm(value == 'approved' ? 'Aprovar vínculo?' : 'Rejeitar vínculo?',
      '${l['usuario_nome']} • ${l['perfil_nome'] ?? l['profile_id']}')) return;
    await run(() => widget.api.patch('/admin/links/${l['id']}', {'status': value}),
      value == 'approved' ? 'Vínculo aprovado.' : 'Vínculo rejeitado.');
  }
  Future<void> role(Map<String, dynamic> u, String value, int self) async {
    if ('${u['id']}' == '$self') return;
    if (!await confirm(value == 'admin' ? 'Promover administrador?' : 'Remover administrador?', '${u['nome']} • ${u['email']}')) return;
    await run(() => widget.api.patch('/admin/users/${u['id']}/role', {'role': value}), 'Papel atualizado.');
  }
  Future<void> accountStatus(Map<String, dynamic> u, String value, int self) async {
    if ('${u['id']}' == '$self') return;
    if (!await confirm(value == 'blocked' ? 'Bloquear conta?' : 'Desbloquear conta?', '${u['nome']} • ${u['email']}')) return;
    await run(() => widget.api.patch('/admin/users/${u['id']}/status', {'status': value}), 'Situação da conta atualizada.');
  }
  Future<void> editAthlete(bool keeper, [Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: item?['nome']?.toString() ?? '');
    final wins = TextEditingController(text: '${item?['vitorias'] ?? 0}');
    final draws = TextEditingController(text: '${item?['empate'] ?? item?['empates'] ?? 0}');
    final saves = TextEditingController(text: '${item?['defesa'] ?? item?['defesas'] ?? 0}');
    final goals = TextEditingController(text: '${item?['gols'] ?? 0}');
    final fouls = TextEditingController(text: '${item?['infracoes'] ?? 0}');
    final save = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(item == null ? (keeper ? 'Novo goleiro' : 'Novo jogador') : 'Editar cadastro'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
        field(wins, 'Vitórias'), field(draws, 'Empates'), field(saves, 'Defesas'),
        field(goals, 'Gols'), field(fouls, 'Infrações'),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Salvar')),
      ],
    ));
    if (save == true && mounted) {
      int n(TextEditingController c) => int.tryParse(c.text.trim()) ?? -1;
      final v = [n(wins), n(draws), n(saves), n(goals), n(fouls)];
      if (name.text.trim().length < 2 || v.any((x) => x < 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha nome e números válidos.')));
      } else {
        final body = {'nome': name.text.trim(), 'vitorias': v[0], 'empate': v[1], 'defesa': v[2], 'gols': v[3], 'infracoes': v[4]};
        final path = keeper ? '/goleiros' : '/jogadores';
        await run(() => item == null ? widget.api.post(path, body) : widget.api.put('$path/${item['id']}', body), 'Cadastro salvo.');
      }
    }
    name.dispose(); wins.dispose(); draws.dispose(); saves.dispose(); goals.dispose(); fouls.dispose();
  }
  Widget field(TextEditingController c, String label) => TextField(controller: c, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label));
  Future<void> deleteAthlete(bool keeper, Map<String, dynamic> item) async {
    if (!await confirm('Excluir cadastro?', '${item['nome']}')) return;
    await run(() => widget.api.delete('${keeper ? '/goleiros' : '/jogadores'}/${item['id']}'), 'Cadastro excluído.');
  }
  Future<void> closeCompetition(Map<String, dynamic> data) async {
    final comp = map(data['competencia']);
    if (!await confirm('Encerrar competência?', 'A competência ${comp['chave'] ?? ''} será fechada e a próxima será aberta.')) return;
    await run(() => widget.api.post('/competencias/fechar', {'confirm': true}), 'Competência encerrada.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administração FutPontos'), actions: [
      IconButton(onPressed: refresh, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
    ]),
    body: FutureBuilder<_AdminData>(future: future, builder: (context, s) {
      if (s.hasError) {
        final msg = s.error.toString().replaceFirst('Exception: ', '');
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.admin_panel_settings_outlined, size: 44),
          const SizedBox(height: 12),
          Text(msg.contains('permissão') || msg.contains('administrador') ? 'Acesso restrito a administradores.' : msg, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('A API valida a sessão e o papel administrativo. Use a mesma conta do FutPontos.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
          FilledButton(onPressed: refresh, child: const Text('Tentar novamente')),
        ])));
      }
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final d = s.data!;
      final stats = map(d.overview['resumo']);
      final self = int.tryParse('${map(d.overview['administrador_atual'])['id']}') ?? -1;
      return DefaultTabController(length: 5, child: Column(children: [
        Material(color: Theme.of(context).colorScheme.surface, child: const TabBar(isScrollable: true, tabs: [
          Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumo'),
          Tab(icon: Icon(Icons.sports_soccer), text: 'Atletas'),
          Tab(icon: Icon(Icons.people_outline), text: 'Pessoas'),
          Tab(icon: Icon(Icons.verified_user_outlined), text: 'Aprovações'),
          Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Registro'),
        ])),
        Expanded(child: TabBarView(children: [summary(d, stats), athletes(d), users(d.users, self), links(d.links), audit(d.audit)])),
      ]));
    }),
  );

  Widget metric(String title, dynamic value, IconData icon) => Card(child: ListTile(
    leading: Icon(icon, color: AppColors.redLight),
    title: Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
    subtitle: Text(title),
  ));
  Widget summary(_AdminData d, Map<String, dynamic> s) {
    final comp = map(d.overview['competencia']);
    return ListView(padding: const EdgeInsets.all(14), children: [
      const Text('CENTRAL DE CONTROLE', style: TextStyle(color: AppColors.redLight, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      Text('Visão geral do FutPontos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 2.1, children: [
        metric('Contas', s['usuarios'] ?? 0, Icons.people_outline),
        metric('Contas ativas', s['usuarios_ativos'] ?? 0, Icons.verified_user_outlined),
        metric('Jogadores', s['jogadores'] ?? 0, Icons.sports_soccer),
        metric('Goleiros', s['goleiros'] ?? 0, Icons.sports_handball),
        metric('Vínculos pendentes', s['vinculos_pendentes'] ?? 0, Icons.pending_actions),
        metric('Sessões ativas', s['sessoes_ativas'] ?? 0, Icons.key_outlined),
      ]),
      Card(child: ListTile(leading: const Icon(Icons.calendar_month_outlined), title: Text(comp['nome']?.toString() ?? 'Competência atual'), subtitle: Text('${comp['chave'] ?? '—'} • ${comp['status'] ?? 'sem status'}'))),
      Card(child: ListTile(leading: const Icon(Icons.lock_clock_outlined), title: const Text('Encerrar competência'), subtitle: const Text('Fecha a atual e abre a próxima'), onTap: busy ? null : () => closeCompetition(d.overview))),
      Card(child: ListTile(leading: const Icon(Icons.admin_panel_settings_outlined), title: const Text('Administradores ativos'), subtitle: Text('${d.overview['administradores_ativos'] ?? 0} conta(s)'))),
    ]);
  }
  Widget athletes(_AdminData d) => ListView(padding: const EdgeInsets.all(12), children: [
    Row(children: [
      Expanded(child: Text('Jogadores (${d.players.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
      FilledButton.tonalIcon(onPressed: busy ? null : () => editAthlete(false), icon: const Icon(Icons.add), label: const Text('Novo')),
    ]),
    ...d.players.map((p) => Card(child: ListTile(title: Text(p['nome']?.toString() ?? 'Jogador'),
      subtitle: Text('${p['pontos'] ?? 0} pts • ${p['gols'] ?? 0} gols • ${p['vitorias'] ?? 0} vitórias'),
      trailing: PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? editAthlete(false, p) : deleteAthlete(false, p),
        itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Excluir'))])))),
    const Divider(height: 28),
    Row(children: [
      Expanded(child: Text('Goleiros (${d.goalkeepers.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
      FilledButton.tonalIcon(onPressed: busy ? null : () => editAthlete(true), icon: const Icon(Icons.add), label: const Text('Novo')),
    ]),
    ...d.goalkeepers.map((g) => Card(child: ListTile(title: Text(g['nome']?.toString() ?? 'Goleiro'),
      subtitle: Text('${g['pontos'] ?? 0} pts • ${g['defesas'] ?? g['defesa'] ?? 0} defesas'),
      trailing: PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? editAthlete(true, g) : deleteAthlete(true, g),
        itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Excluir'))])))),
  ]);
  Widget users(List<Map<String, dynamic>> items, int self) => ListView(padding: const EdgeInsets.all(12), children: [
    Text('Contas cadastradas (${items.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
    ...items.map((u) {
      final admin = u['role'] == 'admin', blocked = u['status'] == 'blocked', own = '${u['id']}' == '$self';
      final link = u['link_id'] == null ? 'Sem vínculo' : '${u['profile_type']} #${u['profile_id']} • ${u['link_status']}';
      return Card(child: Column(children: [
        ListTile(title: Text(u['nome']?.toString() ?? '—'), subtitle: Text('${u['email'] ?? '—'} • $link • ${blocked ? 'BLOQUEADA' : 'ATIVA'} • ${admin ? 'ADMIN' : 'USUÁRIO'}')),
        if (!own) ButtonBar(children: [
          TextButton(onPressed: busy ? null : () => role(u, admin ? 'user' : 'admin', self), child: Text(admin ? 'Remover admin' : 'Promover admin')),
          TextButton(onPressed: busy ? null : () => accountStatus(u, blocked ? 'active' : 'blocked', self), child: Text(blocked ? 'Desbloquear' : 'Bloquear')),
        ]),
      ]));
    }),
  ]);
  Widget links(List<Map<String, dynamic>> items) => items.isEmpty ? const Center(child: Text('Não há solicitações pendentes.')) :
    ListView(padding: const EdgeInsets.all(12), children: [
      Text('Vínculos pendentes (${items.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      ...items.map((l) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l['usuario_nome']?.toString() ?? 'Conta', style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(l['email']?.toString() ?? '—', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        Text('${l['profile_type']} • ${l['perfil_nome'] ?? l['profile_id']}'),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: busy ? null : () => decide(l, 'rejected'), child: const Text('Rejeitar')),
          FilledButton(onPressed: busy ? null : () => decide(l, 'approved'), child: const Text('Aprovar')),
        ]),
      ])))),
    ]);
  Widget audit(List<Map<String, dynamic>> items) => items.isEmpty ? const Center(child: Text('Nenhuma ação administrativa registrada.')) :
    ListView(padding: const EdgeInsets.all(12), children: [
      const Text('Últimas 200 ações', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      ...items.map((r) => Card(child: ListTile(leading: const Icon(Icons.history),
        title: Text(r['action']?.toString() ?? 'Ação'),
        subtitle: Text('${r['administrador_nome'] ?? r['administrador_email'] ?? 'Console'} • ${r['target_type'] ?? ''} ${r['target_id'] ?? ''} • ${r['created_at'] ?? ''}')))),
    ]);
}

class _AdminData {
  const _AdminData(this.overview, this.users, this.links, this.audit, this.players, this.goalkeepers);
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> users, links, audit, players, goalkeepers;
}
