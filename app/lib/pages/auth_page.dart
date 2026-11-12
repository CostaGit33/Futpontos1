import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../data/player.dart';
import '../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.api, required this.onAuthenticated});
  final ApiClient api;
  final VoidCallback onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final AuthService _auth;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _notice;
  String? _profileType;
  Player? _selectedProfile;
  List<_Candidate> _candidates = [];

  @override
  void initState() {
    super.initState();
    _auth = AuthService(widget.api);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to =   'aaaaaeeeeiiiiooooouuuuc';
    var result = value.toLowerCase().trim();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _searchProfiles() async {
    final query = _normalize(_name.text);
    if (query.length < 3) {
      setState(() => _error = 'Digite pelo menos 3 letras do seu nome para pesquisar.');
      return;
    }
    setState(() { _busy = true; _error = null; _notice = null; _candidates = []; _selectedProfile = null; });
    try {
      final players = await widget.api.list('/jogadores');
      final goalkeepers = await widget.api.list('/goleiros');
      final found = <_Candidate>[];
      for (final row in players) {
        final name = (row['nome'] ?? '').toString();
        final normalized = _normalize(name);
        if (normalized == query || normalized.startsWith(query) || normalized.contains(query) || query.contains(normalized)) {
          found.add(_Candidate(type: 'jogador', player: Player.fromJson(row)));
        }
      }
      for (final row in goalkeepers) {
        final name = (row['nome'] ?? '').toString();
        final normalized = _normalize(name);
        if (normalized == query || normalized.startsWith(query) || normalized.contains(query) || query.contains(normalized)) {
          found.add(_Candidate(type: 'goleiro', player: Player.fromJson(row)));
        }
      }
      found.sort((a, b) {
        final aExact = _normalize(a.player.name) == query ? 0 : 1;
        final bExact = _normalize(b.player.name) == query ? 0 : 1;
        return aExact.compareTo(bExact);
      });
      if (!mounted) return;
      setState(() {
        _candidates = found.take(12).toList();
        _notice = found.isEmpty
            ? 'Não encontramos um nome correspondente. Você pode criar a conta sem vincular um perfil.'
            : 'Encontramos possíveis correspondências. Confirme somente se o perfil for realmente seu.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Não foi possível consultar a lista de pontuação: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseCandidate(_Candidate candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Este perfil é seu?'),
        content: Text('Você é ${candidate.player.name}, que aparece na lista de pontuação como ${candidate.type == 'goleiro' ? 'goleiro' : 'jogador'}?\n\nA vinculação ficará pendente de aprovação administrativa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não sou eu')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim, sou eu')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() { _selectedProfile = candidate.player; _profileType = candidate.type; _error = null; });
    }
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      if (_register) {
        final result = await _auth.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          profileType: _profileType,
          profileId: _selectedProfile?.id,
        );
        if (!mounted) return;
        setState(() {
          _register = false;
          _password.clear();
          _notice = (result['message'] ?? 'Cadastro realizado. Faça login para continuar.').toString();
        });
      } else {
        await _auth.login(_email.text, _password.text);
        if (mounted) widget.onAuthenticated();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF101827), Color(0xFF080B12)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Icon(Icons.sports_soccer, size: 48, color: AppColors.redLight),
                      const SizedBox(height: 8),
                      const Text('FUTPONTOS', textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)),
                      const SizedBox(height: 5),
                      Text(_register ? 'Crie sua conta no aplicativo' : 'Entre para acessar o aplicativo',
                        textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 24),
                      if (_register) ...[
                        TextField(controller: _name, textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline))),
                        const SizedBox(height: 12),
                      ],
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                        autocorrect: false, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined))),
                      const SizedBox(height: 12),
                      TextField(controller: _password, obscureText: _obscure,
                        decoration: InputDecoration(labelText: 'Senha', prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure)))),
                      if (_register) ...[
                        const SizedBox(height: 8),
                        const Text('A senha deve ter pelo menos 10 caracteres.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 18),
                        const Text('Seu perfil na pontuação', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        const Text('Opcional: escolha a categoria e procure seu nome na lista oficial.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'jogador', label: Text('Jogador'), icon: Icon(Icons.groups_outlined)),
                            ButtonSegment(value: 'goleiro', label: Text('Goleiro'), icon: Icon(Icons.sports_handball_outlined)),
                          ],
                          selected: _profileType == null ? <String>{} : <String>{_profileType!},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (values) => setState(() {
                            _profileType = values.isEmpty ? null : values.first;
                            _selectedProfile = null;
                            _candidates = [];
                          }),
                        ),
                        if (_profileType != null) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(onPressed: _busy ? null : _searchProfiles,
                            icon: const Icon(Icons.search), label: const Text('Buscar meu nome na pontuação')),
                        ],
                        if (_selectedProfile != null)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.verified_user_outlined, color: AppColors.gold),
                            title: Text(_selectedProfile!.name),
                            subtitle: const Text('Vínculo selecionado — aguardará aprovação'),
                            trailing: IconButton(icon: const Icon(Icons.close),
                              onPressed: () => setState(() { _selectedProfile = null; _profileType = null; _candidates = []; })),
                          ),
                        if (_notice != null) Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_notice!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ),
                        if (_candidates.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Você é algum destes perfis?', style: TextStyle(fontWeight: FontWeight.w700)),
                          ..._candidates.map((candidate) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(candidate.type == 'goleiro' ? Icons.sports_handball : Icons.sports_soccer),
                            title: Text(candidate.player.name),
                            subtitle: Text('${candidate.type == 'goleiro' ? 'Goleiro' : 'Jogador'} • ${candidate.player.points} pontos'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _busy ? null : () => _chooseCandidate(candidate),
                          )),
                          TextButton(onPressed: () => setState(() { _selectedProfile = null; _profileType = null; _candidates = []; }),
                            child: const Text('Não sou nenhum destes perfis')),
                        ],
                      ],
                      if (_error != null) Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_register ? 'Criar conta' : 'Entrar'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => setState(() {
                          _register = !_register;
                          _error = null;
                          _notice = null;
                          _candidates = [];
                          _selectedProfile = null;
                          _profileType = null;
                        }),
                        child: Text(_register ? 'Já tenho uma conta — entrar' : 'Não tenho conta — cadastrar'),
                      ),
                      const SizedBox(height: 4),
                      const Text('O cadastro não altera a pontuação. A vinculação a um perfil existente depende de aprovação.',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Candidate {
  const _Candidate({required this.type, required this.player});
  final String type;
  final Player player;
}
