import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';

class IntelligentRegistrationPage extends StatefulWidget {
  const IntelligentRegistrationPage({
    super.key,
    required this.api,
    this.onRegistered,
  });

  final ApiClient api;
  final Future<void> Function()? onRegistered;

  @override
  State<IntelligentRegistrationPage> createState() => _IntelligentRegistrationPageState();
}

class _IntelligentRegistrationPageState extends State<IntelligentRegistrationPage> {
  final _message = TextEditingController();
  bool _sending = false;
  Map<String, dynamic>? _confirmation;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  Future<void> _submit() async {
    final message = _message.text.trim();
    if (_sending || message.length < 3) {
      if (message.length < 3) {
        setState(() => _error = 'Descreva os acontecimentos com pelo menos 3 caracteres.');
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
      _confirmation = null;
    });

    try {
      final response = _asMap(await widget.api.post(
        '/admin/registro-inteligente',
        {'mensagem': message},
      ));
      final apiResult = _asMap(response['api_result']);
      final confirmed = response['success'] == true &&
          (apiResult['success'] == true || apiResult['sucesso'] == true || apiResult['ok'] == true);
      if (!confirmed) {
        throw Exception(response['error']?.toString() ??
            'O workflow não retornou confirmação positiva da API. Nenhum sucesso foi exibido.');
      }
      if (!mounted) return;
      setState(() => _confirmation = response);
      await widget.onRegistered?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _updatedPlayers(dynamic value) {
    if (value is! List || value.isEmpty) return const SizedBox.shrink();
    final players = value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    if (players.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text('Jogadores retornados pela API', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        ...players.map((player) => ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.sports_soccer, color: AppColors.redLight),
          title: Text(player['nome']?.toString() ?? 'Jogador'),
          subtitle: Text('${player['pontos'] ?? 0} pts • ${player['gols'] ?? 0} gols • ${player['vitorias'] ?? 0} vitórias'),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _confirmation == null ? <String, dynamic>{} : _asMap(_confirmation!['api_result']);
    final resultText = result.isEmpty ? '' : const JsonEncoder.withIndent('  ').convert(result);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('REGISTRO INTELIGENTE', style: TextStyle(
          color: AppColors.redLight, fontWeight: FontWeight.w900, letterSpacing: 1.3,
        )),
        const SizedBox(height: 6),
        Text('Registre falando normalmente', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Escreva como você enviaria no Telegram. O mesmo workflow do n8n interpreta a mensagem, valida os jogadores e solicita o registro à API.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: AppColors.gold),
                SizedBox(width: 8),
                Text('Mensagem para o FutPontos', style: TextStyle(fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _message,
                minLines: 4,
                maxLines: 7,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Romulo, Wendel e Peixe\n1 vitória e 1 empate',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bolt),
                  label: Text(_sending ? 'Processando no n8n...' : 'Interpretar e registrar'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A confirmação só aparece quando o backend recebe a confirmação positiva da API.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ]),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
              title: Text('Não foi possível confirmar', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.w800)),
              subtitle: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          ),
        ],
        if (_confirmation != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text('Registro confirmado pela API', style: TextStyle(fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: 6),
                Text(_confirmation!['message']?.toString() ?? 'Os dados foram registrados e a API confirmou a operação.'),
                _updatedPlayers(result['jogadores_atualizados']),
                if (resultText.isNotEmpty) ...[
                  const Divider(height: 24),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Resposta técnica da API', style: TextStyle(fontWeight: FontWeight.w700)),
                    children: [
                      SelectableText(resultText, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _message.clear();
                    _confirmation = null;
                    _error = null;
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar outra mensagem'),
                ),
              ]),
            ),
          ),
        ],
      ],
    );
  }
}
