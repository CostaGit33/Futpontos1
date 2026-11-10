# API FutPontos — contrato identificado

Base: `https://api.semdominio.online`

## Leituras identificadas
| Método | Rota | Uso |
|---|---|---|
| GET | /health | Saúde da API e banco |
| GET | /jogadores | Ranking/competência atual |
| GET | /jogadores/:id | Perfil |
| GET | /goleiros | Lista de goleiros |
| GET | /goleiros/:id | Perfil do goleiro |
| GET | /desempenho | Avaliações |
| GET | /competencias | Histórico de competências |
| GET | /competencias/atual | Competência aberta e resumo |
| GET | /competencias/:id/jogadores | Ranking histórico |
| GET | /montar-times | Times montados |

## Escritas existentes (não habilitadas no app nesta fase)
- POST /jogadores
- PUT /jogadores/:id
- POST /jogadores/:id/foto
- DELETE /jogadores/:id
- POST /goleiros
- PUT /goleiros/:id
- DELETE /goleiros/:id
- POST /competencias/fechar (exige `confirm=true`)
- POST /montar-times/selecionar
- DELETE /montar-times/:jogadorId
- DELETE /montar-times
- POST /partida/registrar

**Segurança:** na versão auditada, não foi localizada rota de autenticação. A API também usa CORS aberto. Antes de liberar administração no app, implementar autenticação/autorização no servidor e restringir CORS, além de validar os contratos e permissões de cada operação.
