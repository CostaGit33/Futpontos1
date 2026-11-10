# FutPontos1

Aplicativo FutPontos reconstruído em Flutter (Dart), com interface própria e integração com a API oficial existente.

## Direção
- Flutter nativo; não é um WebView nem um projeto Capacitor.
- API oficial: https://api.semdominio.online
- PostgreSQL existente permanece como fonte persistente.
- Regras de pontuação documentadas e cobertas por testes.
- Layout responsivo: navegação inferior em telas compactas e lateral em telas amplas.
- Os repositórios de origem permanecem intactos.

## Pontuação
Vitória +3 · Gol +2 · Empate +1 · Defesa +1 · Infração -2.

## Estado
Fundação inicial do Flutter, cliente HTTP, domínio de pontuação e navegação. Telas e operações serão migradas por módulos após validação dos contratos. Não há login fictício nem escrita administrativa sem autenticação real.

## Executar
```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```
