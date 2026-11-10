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

## Migração
Classificação, jogadores/perfis, goleiros, desempenho, análise semanal, vídeos, montagem de times, competências e administração protegida.
