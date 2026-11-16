import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/token_storage.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../data/analytics.dart';
import '../data/player.dart';
import '../widgets/sports_banner.dart';
import '../widgets/motion.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key, required this.api, required this.loadPlayers, required this.loadPlayerDetails, required this.loadAssessments});
  final ApiClient api;
  final Future<List<Player>> Function() loadPlayers;
  final Future<Map<String, dynamic>> Function(int id) loadPlayerDetails;
  final Future<List<Map<String, dynamic>>> Function() loadAssessments;

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
        'Infrações' => p.fouls,
        _ => p.points,
      };
      players.sort((a, b) {
        final primary = value(b).compareTo(value(a));
        if (primary != 0) return _sort == 'Infrações' ? -primary : primary;
        final points = b.points.compareTo(a.points);
        return points != 0 ? points : a.name.compareTo(b.name);
      });
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            const SportsBanner(
              title: 'Jogadores',
              subtitle: 'Destaques, desempenho e evolução em campo',
              icon: Icons.sports_soccer_rounded,
              tag: 'PLANTEL • FUTPONTOS',
            ),
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
              child: Row(children: ['Pontos', 'Gols', 'Defesas', 'Vitórias', 'Infrações'].map((item) =>
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
              ...players.asMap().entries.map((entry) => MotionReveal(
                delay: Duration(milliseconds: 28 * entry.key.clamp(0, 7).toInt()),
                child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Hero(
                    tag: 'player-avatar-${entry.value.id}',
                    child: PlayerAvatar(
                      photo: entry.value.photo,
                      radius: 20,
                      fallback: Text('${entry.key + 1}'),
                    ),
                  ),
                  title: Text(entry.value.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${entry.value.wins} vitórias • ${entry.value.goals} gols • ${entry.value.saves} defesas'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${entry.value.points}', style: const TextStyle(
                      color: AppColors.redLight, fontWeight: FontWeight.w900, fontSize: 17)),
                    const Text('PTS', style: TextStyle(fontSize: 9, color: AppColors.muted)),
                  ]),
                  onTap: () async {
                    var selectedPlayer = entry.value;
                    String? syncWarning;
                    try {
                      final raw = await widget.loadPlayerDetails(entry.value.id);
                      final detail = raw['jogador'] is Map
                          ? Map<String, dynamic>.from(raw['jogador'] as Map)
                          : raw;
                      selectedPlayer = Player.fromJson({
                        'id': entry.value.id,
                        'nome': entry.value.name,
                        'foto': entry.value.photo,
                        'pontos': entry.value.points,
                        'vitorias': entry.value.wins,
                        'gols': entry.value.goals,
                        'defesa': entry.value.saves,
                        'empate': entry.value.draws,
                        'infracoes': entry.value.fouls,
                        ...detail,
                      });
                    } catch (error) {
                      syncWarning = 'Detalhes atualizados parcialmente: ${error.toString()}';
                    }
                    List<int>? assessment;
                    String? assessmentSource;
                    try {
                      final records = await widget.loadAssessments();
                      for (final record in records) {
                        if ('${record['id']}' != '${entry.value.id}') continue;
                        if (record['avaliacao'] == null) break;
                        if (record['avaliacao'] is! Map) {
                          throw const FormatException(
                            'A API retornou um formato inválido para a avaliação técnica.');
                        }
                        final rawAssessment =
                            Map<String, dynamic>.from(record['avaliacao'] as Map);
                        const keys = ['defesa', 'ataque', 'velocidade', 'habilidade', 'passe'];
                        final values = keys
                            .map((key) => int.tryParse('${rawAssessment[key]}'))
                            .toList();
                        if (values.every((value) =>
                            value != null && value >= 0 && value <= 20)) {
                          assessment = values.cast<int>();
                          assessmentSource = 'Avaliação manual sincronizada pela API • escala de 0 a 20';
                        } else {
                          throw const FormatException(
                            'A API retornou uma avaliação incompleta ou fora da escala de 0 a 20.');
                        }
                        break;
                      }
                    } catch (error) {
                      assessmentSource = 'Falha ao sincronizar a avaliação técnica.';
                      syncWarning = [syncWarning, 'Avaliação não sincronizada: $error']
                          .whereType<String>().join(' ');
                    }
                    if (!context.mounted) return;
                    if (syncWarning != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(syncWarning!)),
                      );
                    }
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlayerProfilePage(
                        api: widget.api,
                        player: selectedPlayer,
                        assessment: assessment,
                        assessmentSource: assessmentSource,
                        assessmentError: assessmentSource?.startsWith('Falha') == true
                            ? assessmentSource : null,
                      ),
                    ));
                  },
                ),
              ))),
          ],
        ),
      );
    },
  );
}

class PlayerProfilePage extends StatelessWidget {
  const PlayerProfilePage({super.key, required this.api, required this.player, this.assessment, this.assessmentSource, this.assessmentError});
  final ApiClient api;
  final Player player;
  final List<int>? assessment;
  final String? assessmentSource;
  final String? assessmentError;

  @override
  Widget build(BuildContext context) {
    final technicalAssessment = assessment;
    final achievements = achievementsFor(player);
    return Scaffold(
      appBar: AppBar(title: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              _ProfilePhotoEditor(api: api, player: player),
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
          Text(assessmentSource ?? 'Avaliação individual cadastrada manualmente • escala de 0 a 20',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 10),
          if (technicalAssessment == null)
            Card(child: Padding(padding: const EdgeInsets.all(16),
              child: Text(assessmentError ?? 'Este jogador ainda não possui avaliação técnica manual cadastrada.')))
          else
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Média técnica', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text('${(technicalAssessment.reduce((a, b) => a + b) / technicalAssessment.length).toStringAsFixed(1)}/20',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.redLight)),
                ]),
                const SizedBox(height: 12),
                ...List.generate(5, (i) => _AssessmentBar(
                  label: const ['Defesa', 'Ataque', 'Velocidade', 'Habilidade', 'Passe'][i],
                  score: technicalAssessment[i])),
              ]),
            )),
          const SizedBox(height: 20),
          const Text('CONQUISTAS', style: TextStyle(
            color: AppColors.redLight, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Card(child: Column(children: achievements.asMap().entries.map((entry) => MotionReveal(
            delay: Duration(milliseconds: 35 * entry.key.clamp(0, 6).toInt()),
            child: ListTile(
              leading: Text(entry.value.icon, style: const TextStyle(fontSize: 22)),
              title: Text(entry.value.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${entry.value.description} • ${entry.value.progress}/${entry.value.target}'),
              trailing: Icon(entry.value.unlocked ? Icons.check_circle : Icons.lock_outline,
                color: entry.value.unlocked ? AppColors.gold : AppColors.muted),
            ),
          )).toList())),
        ],
      ),
    );
  }
}


class _ProfilePhotoEditor extends StatefulWidget {
  const _ProfilePhotoEditor({required this.api, required this.player});
  final ApiClient api;
  final Player player;

  @override
  State<_ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends State<_ProfilePhotoEditor> {
  final ImagePicker _picker = ImagePicker();
  String? _photo;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _photo = widget.player.photo;
  }

  Future<String?> _loginIfNeeded() async {
    const tokenStorage = TokenStorage();
    if (!mounted) return null;
    var token = await tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      final credentials = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Entrar para alterar a foto'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'email': emailController.text.trim(),
                'password': passwordController.text,
              }),
              child: const Text('Entrar'),
            ),
          ],
        ),
      );
      emailController.dispose();
      passwordController.dispose();
      if (credentials == null) return null;
      final login = await widget.api.login(
        email: credentials['email'] ?? '',
        password: credentials['password'] ?? '',
      );
      token = login['token']?.toString();
      if (token == null || token.isEmpty) throw Exception('A API não retornou uma sessão válida.');
      await tokenStorage.writeToken(token);
    }

    late final Map<String, dynamic> session;
    try {
      session = await widget.api.authMe(token);
    } on ApiException catch (error) {
      if (error.statusCode == 401) await tokenStorage.deleteToken();
      rethrow;
    }
    final links = session['vinculos'];
    final approved = links is List && links.any((item) =>
      item is Map &&
      item['profile_type'] == 'jogador' &&
      '${item['profile_id']}' == '${widget.player.id}' &&
      item['status'] == 'approved');
    if (!approved) {
      throw Exception('Sua conta ainda não possui vínculo aprovado com este jogador. Solicite a aprovação do vínculo antes de alterar a foto.');
    }
    return token;
  }

  Future<void> _chooseAndUpload() async {
    if (_uploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(child: Wrap(children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Escolher da galeria'),
          onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Tirar uma foto'),
          onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
        ),
      ])),
    );
    if (source == null || !mounted) return;
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1400);
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('A imagem deve ter no máximo 5 MB.');
      }
      setState(() => _uploading = true);
      final token = await _loginIfNeeded();
      if (token == null) return;
      final result = await widget.api.uploadPlayerPhoto(
        playerId: widget.player.id,
        bytes: bytes,
        filename: image.name,
        token: token,
      );
      if (!mounted) return;
      setState(() => _photo = resolvePlayerPhoto(result['foto']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Stack(alignment: Alignment.bottomRight, children: [
        Hero(
          tag: 'player-avatar-${widget.player.id}',
          child: PlayerAvatar(
            photo: _photo,
            radius: 34,
            fallback: const Icon(Icons.person, size: 34),
          ),
        ),
        if (_uploading)
          const Positioned.fill(child: CircleAvatar(
            radius: 34,
            backgroundColor: Color(0x99000000),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ))
        else
          Positioned(
            right: -7,
            bottom: -7,
            child: IconButton.filled(
              tooltip: 'Alterar foto',
              visualDensity: VisualDensity.compact,
              onPressed: _chooseAndUpload,
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
            ),
          ),
      ]),
      const SizedBox(height: 8),
      MotionTap(
        onTap: _uploading ? null : _chooseAndUpload,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            _uploading ? 'Enviando...' : 'Alterar foto',
            style: TextStyle(
              color: _uploading ? AppColors.muted : AppColors.redLight,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ],
  );
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppColors.raised, borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
      MotionNumber(value: value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
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
        child: MotionProgressBar(value: (score / 20).clamp(0, 1).toDouble(),
          minHeight: 8, backgroundColor: AppColors.raised)),
    ]),
  );
}

