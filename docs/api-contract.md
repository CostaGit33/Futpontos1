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
| GET | /goleiros/ranking | Pódio separado de goleiros |
| GET | /goleiros/:id/partidas | Partidas registradas do goleiro |
| GET | /goleiros/:id/evolucao | Evolução mensal do goleiro |
| GET | /competencias/:id/goleiros | Ranking histórico de goleiros |
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
- POST /goleiros/:id/foto
- DELETE /goleiros/:id
- POST /competencias/fechar (exige `confirm=true`)
- POST /montar-times/selecionar
- DELETE /montar-times/:jogadorId
- DELETE /montar-times
- POST /partida/registrar

`POST /partida/registrar` mantém os blocos antigos `coletivo` e `individual` e aceita opcionalmente `goleiros`, por exemplo:

```json
{
  "operacao_id": "flutter-2027-01-0001",
  "goleiros": [
    {
      "goleiro_id": 8,
      "resultado": "vitoria",
      "defesas": 3,
      "gols_sofridos": 1,
      "infracoes": 0
    }
  ]
}
```

**Segurança:** na versão auditada, não foi localizada rota de autenticação. A API também usa CORS aberto. Antes de liberar administração no app, implementar autenticação/autorização no servidor e restringir CORS, além de validar os contratos e permissões de cada operação.
