# Arquitetura

## Fontes de origem
- `control`: painel administrativo.
- `sitesemdominio`: frontend público e funcionalidades.
- `semdominio/api`: Express + PostgreSQL, backend oficial.

## Princípios
1. Não duplicar banco nem criar backend paralelo.
2. A API atual permanece fonte oficial dos dados.
3. Centralizar regras de domínio no Flutter e manter backend consistente.
4. Não presumir endpoint de login: a API auditada não expõe autenticação.
5. Não habilitar escrita até autenticação/autorização reais.
6. Preservar competências mensais, histórico, fotos, montagem de times e idempotência de partidas.
7. Não alterar os repositórios originais durante a migração.

## Goleiros no aplicativo

O Flutter mantém goleiros em uma seção e ranking próprios. A API pode acrescentar campos e rotas de goleiros sem misturá-los às respostas de jogadores consumidas pelo PWA. O aplicativo usa `GET /goleiros`, `/goleiros/ranking`, `/goleiros/:id/partidas`, `/goleiros/:id/evolucao` e `/competencias/:id/goleiros` para leitura.

O registro de partidas aceita um bloco opcional `goleiros`, mas o aplicativo não habilita operações administrativas de escrita enquanto a API não tiver autenticação e autorização reais.

## Migração
Classificação, jogadores/perfis, goleiros, desempenho, análise semanal, vídeos, montagem de times, competências e administração protegida.


## Autenticação exclusiva do Flutter

O aplicativo Flutter apresenta uma tela de login/cadastro antes de abrir o conteúdo. O PWA e o painel `control` permanecem sem alterações nesta etapa.

### Cadastro e identificação esportiva
1. A pessoa informa nome, e-mail e senha.
2. Escolhe se participa como jogador ou goleiro.
3. O aplicativo consulta somente a lista da categoria escolhida (`GET /jogadores` ou `GET /goleiros`) e procura correspondências de nome, sem alterar a pontuação.
4. A pessoa confirma explicitamente se o perfil encontrado é dela.
5. A API cria uma solicitação de vínculo com status `pending`. A confirmação no aplicativo não aprova nem comprova a identidade.
6. Sem correspondência, a pessoa pode criar uma conta sem vínculo esportivo.

### API de autenticação
- `POST /auth/register`: cria a conta e, opcionalmente, a solicitação de vínculo.
- `POST /auth/login`: valida e-mail/senha e cria uma sessão.
- `GET /auth/me`: consulta a conta e o estado dos vínculos.
- `POST /auth/logout`: encerra a sessão.
- Senhas são derivadas com scrypt e salt aleatório; tokens de sessão aleatórios são armazenados como hash no PostgreSQL.
- O Flutter persiste o token usando `flutter_secure_storage`.

### Limites desta etapa
- A solicitação de vínculo fica pendente; a aprovação administrativa ainda precisa de um fluxo próprio e não é concedida automaticamente.
- Não há verificação de e-mail, recuperação de senha, limitação distribuída de tentativas nem rotação de sessão nesta primeira etapa.
- A autenticação protege as rotas `/auth/*`; não foi aplicado middleware global aos endpoints legados, para não quebrar PWA e integrações atuais. Portanto, esta entrega não equivale a uma migração completa de autorização das operações administrativas da API.
- A API deve ser implantada antes de a nova tela Flutter conseguir cadastrar ou autenticar contas.
