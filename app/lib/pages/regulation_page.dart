import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';

class RegulationPage extends StatelessWidget {
  const RegulationPage({super.key});

  static const _sections = <_RegulationSection>[
    _RegulationSection('1. OBJETIVO E ORGANIZAÇÃO', [
      'Este regulamento estabelece as regras de participação, organização, disciplina, pagamentos e critérios de pontuação do Baba.',
      'Todos os participantes devem conhecer e respeitar as regras, contribuindo para um ambiente de respeito, compromisso, organização e espírito esportivo.',
    ]),
    _RegulationSection('2. INSCRIÇÃO E LISTA DE PARTICIPANTES', [
      '2.1. O Baba terá o limite de 24 jogadores por encontro.',
      '2.2. A inclusão de convidados na lista será permitida somente a partir das 18h do sábado, desde que ainda existam vagas entre os 24 participantes.',
      '2.3. O participante poderá indicar o nome de um convidado ao lado do seu próprio nome em qualquer horário. Entretanto, o convidado deverá respeitar a regra de entrada na lista e, durante a organização dos jogos, deverá revezar com o responsável pela indicação.',
      '2.4. Caso o participante não possa comparecer, deverá retirar seu nome da lista até as 18h do sábado.',
      '2.5. Cada jogador é responsável por manter sua inscrição atualizada e comunicar sua ausência dentro do prazo estabelecido.',
    ]),
    _RegulationSection('3. HORÁRIO E DIVISÃO DOS TIMES', [
      '3.1. A divisão dos times será realizada às 7h em ponto.',
      '3.2. Será concedida tolerância de cinco minutos para a chegada dos participantes.',
      '3.3. O horário limite para participar da divisão será 7h05. A partir das 7h06, o jogador que chegar não poderá participar dos jogos daquele encontro.',
      '3.4. Todos devem se organizar para chegar com antecedência, evitando atrasos e prejudicando o andamento do Baba.',
    ]),
    _RegulationSection('4. FALTAS E PENALIDADES', [
      '4.1. O jogador que colocar seu nome na lista e não comparecer ao Baba, sem retirar sua inscrição até o prazo estabelecido, estará sujeito a uma multa de R\$ 10,00.',
      '4.2. A multa deverá ser paga antes da participação no próximo Baba.',
      '4.3. Cada jogador deverá participar de pelo menos um Baba por mês.',
      '4.4. O jogador que não participar de nenhum encontro durante o mês será removido automaticamente da lista de participantes.',
      '4.5. A regra de frequência poderá ter exceções, desde que previamente autorizadas pela comissão.',
    ]),
    _RegulationSection('5. DISCIPLINA E CONDUTA ESPORTIVA', [
      '5.1. Todos os jogadores deverão manter uma conduta respeitosa dentro e fora de campo.',
      '5.2. Não serão toleradas atitudes antidesportivas, desrespeito aos participantes ou comportamentos que prejudiquem a organização do Baba.',
      '5.3. O jogador que receber cartão vermelho será banido do Baba.',
      '5.4. As decisões disciplinares e situações não previstas neste regulamento deverão ser encaminhadas à comissão organizadora.',
    ]),
    _RegulationSection('6. MATERIAIS E UNIFORMES', [
      'Cada participante deverá levar seus próprios materiais:',
      '• Garrafa de água para hidratação.',
      '• Uniforme azul.',
      '• Uniforme vermelho.',
      'É responsabilidade de cada jogador comparecer preparado para participar dos jogos.',
    ]),
    _RegulationSection('7. PAGAMENTOS E CONTRIBUIÇÕES', [
      '7.1. Os pagamentos deverão ser realizados, impreterivelmente, até o dia 10 de cada mês.',
      '7.2. Os valores estabelecidos são:',
      'Mensalista: R\$ 35,00 por mês.',
      'Convidado: R\$ 15,00 por Baba.',
      'Multa por ausência sem aviso: R\$ 10,00.',
      '7.3. Os convidados deverão pagar o valor correspondente a cada Baba em que participarem.',
      'Chave PIX: 73998084515',
      'É responsabilidade de cada participante manter seus pagamentos em dia.',
    ]),
    _RegulationSection('8. CRITÉRIOS DE CLASSIFICAÇÃO', [
      '8.1. TIME CAMPEÃO',
      'A definição do time campeão seguirá esta ordem de critérios:',
      '1. Maior pontuação geral.',
      '2. Maior número de gols no geral.',
      '3. Maior pontuação individual.',
      'Os critérios serão considerados na ordem apresentada.',
      '8.2. MELHOR DO MÊS',
      'A escolha do Melhor do Mês seguirá os seguintes critérios, em ordem de prioridade:',
      '1. Maior pontuação geral.',
      '2. Maior número de vitórias.',
      '3. Maior número de gols.',
      '4. Maior frequência nos encontros.',
      'Os critérios serão utilizados para definir a classificação mensal dos participantes.',
    ]),
    _RegulationSection('9. SISTEMA DE PONTUAÇÃO INDIVIDUAL', [
      'A pontuação individual será contabilizada conforme os seguintes acontecimentos durante os jogos:',
      'Gol marcado: +2 pontos.',
      'Zagueiro ou goleiro sem sofrer gol: +1 ponto.',
      'Cartão amarelo: -2 pontos.',
      'Gol contra: -2 pontos.',
      'Pênalti perdido: -2 pontos.',
      '9.1. Os pontos positivos e negativos serão acumulados no sistema de pontuação online.',
      '9.2. Os registros deverão corresponder aos acontecimentos efetivamente ocorridos durante as partidas.',
    ]),
    _RegulationSection('10. COMISSÃO ORGANIZADORA', [
      'A comissão é responsável por acompanhar a organização do Baba, orientar os participantes, avaliar situações excepcionais e zelar pelo cumprimento deste regulamento.',
      'Integrantes: Wendel, Joel, Matheus e Rômulo.',
      '10.1. A comissão poderá analisar situações não previstas neste documento.',
      '10.2. Exceções às regras deverão ser autorizadas pela comissão, respeitando a organização e a igualdade entre os participantes.',
    ]),
    _RegulationSection('11. DISPOSIÇÕES FINAIS', [
      '11.1. Todos os participantes, mensalistas e convidados, deverão respeitar este regulamento.',
      '11.2. O desconhecimento das regras não isenta o participante de cumprir suas obrigações.',
      '11.3. O objetivo deste documento é garantir transparência, compromisso, disciplina e equilíbrio na realização dos encontros.',
      '11.4. As dúvidas, reclamações e situações excepcionais deverão ser apresentadas à comissão organizadora.',
      'A participação no Baba representa a concordância com as regras aqui estabelecidas.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regulamento do Baba'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue, Color(0xFF151B29), AppColors.red],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sports_soccer, size: 34, color: Colors.white),
                SizedBox(height: 10),
                Text('REGULAMENTO OFICIAL DO BABA',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                SizedBox(height: 8),
                Text('Regras, condutas, participação e critérios de pontuação.',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.redLight),
                  title: const Text('Instagram oficial'),
                  subtitle: const Text('@babasemdomonio'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openUrl(context,
                      'https://instagram.com/babasemdomonio?igshid=YmMyMTA2M2Y='),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.leaderboard_outlined, color: AppColors.redLight),
                  title: const Text('Pontuação online'),
                  subtitle: const Text('www.semdominio.online'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openUrl(context, 'https://www.semdominio.online/index.html'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._sections.map((section) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title,
                          style: const TextStyle(
                              color: AppColors.redLight,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .3)),
                      const SizedBox(height: 12),
                      ...section.paragraphs.map((paragraph) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Text(paragraph,
                                style: const TextStyle(height: 1.45)),
                          )),
                    ],
                  ),
                ),
              )),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMISSÃO ORGANIZADORA',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text('Wendel • Joel • Matheus • Rômulo'),
                  SizedBox(height: 10),
                  Text('Instagram: @babasemdomonio'),
                  Text('Pontuação online: https://www.semdominio.online/index.html'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }
}

class _RegulationSection {
  const _RegulationSection(this.title, this.paragraphs);
  final String title;
  final List<String> paragraphs;
}
